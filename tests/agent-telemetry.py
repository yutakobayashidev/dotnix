"""Exercise generated Alloy config against an isolated VictoriaMetrics process.

python3 tests/agent-telemetry.py --alloy /path/to/alloy \
  --victoriametrics /path/to/victoria-metrics --config /path/to/server.alloy
"""

import argparse
import json
import pathlib
import socket
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request


def port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def attributes(values):
    return [
        {"key": key, "value": {"stringValue": value}} for key, value in values.items()
    ]


def send(endpoint, name, amount, start, end, resource=None, labels=None):
    body = {
        "resourceMetrics": [
            {
                "resource": {"attributes": attributes(resource or {})},
                "scopeMetrics": [
                    {
                        "scope": {"name": "isolated-test"},
                        "metrics": [
                            {
                                "name": name,
                                "sum": {
                                    "aggregationTemporality": 1,
                                    "isMonotonic": True,
                                    "dataPoints": [
                                        {
                                            "attributes": attributes(labels or {}),
                                            "startTimeUnixNano": str(start),
                                            "timeUnixNano": str(end),
                                            "asDouble": amount,
                                        }
                                    ],
                                },
                            }
                        ],
                    }
                ],
            }
        ]
    }
    request = urllib.request.Request(
        f"http://127.0.0.1:{endpoint}/v1/metrics",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=3) as response:
        assert response.status == 200


def wait_for(check, timeout=90):
    deadline = time.monotonic() + timeout
    last_error = None
    while time.monotonic() < deadline:
        try:
            result = check()
            if result:
                return result
        except (OSError, ValueError, AssertionError) as error:
            last_error = error
        time.sleep(0.2)
    raise AssertionError(f"Timed out waiting for telemetry: {last_error}")


def main():
    parser = argparse.ArgumentParser()
    for option in ["alloy", "victoriametrics", "config"]:
        parser.add_argument("--" + option, required=True)
    args = parser.parse_args()
    local, legacy, grpc, admin, vm = [port() for _ in range(5)]
    config = pathlib.Path(args.config).read_text()
    assert "legacy_agents" in config, "Use the evaluated server configuration"
    config = config.replace("127.0.0.1:4317", f"127.0.0.1:{grpc}")
    config = config.replace("127.0.0.1:4319", f"127.0.0.1:{local}")
    config = config.replace("0.0.0.0:4318", f"127.0.0.1:{legacy}")
    config = config.replace("127.0.0.1:8428", f"127.0.0.1:{vm}")
    processes = []
    with tempfile.TemporaryDirectory(prefix="agent-telemetry-test-") as tmp:
        root = pathlib.Path(tmp)
        (root / "config.alloy").write_text(config)
        with (root / "process.log").open("w+") as log:
            try:
                processes.append(
                    subprocess.Popen(
                        [
                            args.victoriametrics,
                            f"-storageDataPath={tmp}/vm",
                            f"-httpListenAddr=127.0.0.1:{vm}",
                            "-search.latencyOffset=0s",
                        ],
                        stdout=log,
                        stderr=log,
                    )
                )
                processes.append(
                    subprocess.Popen(
                        [
                            args.alloy,
                            "run",
                            "--stability.level=experimental",
                            f"--server.http.listen-addr=127.0.0.1:{admin}",
                            f"--storage.path={tmp}/alloy",
                            str(root / "config.alloy"),
                        ],
                        stdout=log,
                        stderr=log,
                    )
                )
                wait_for(
                    lambda: (
                        urllib.request.urlopen(
                            f"http://127.0.0.1:{admin}/-/ready", timeout=1
                        ).status
                        == 200
                    )
                )
                # remote_write discards samples older than its startup time during WAL replay.
                start = time.time_ns()
                # Turn labels must collapse before accumulation. Identity comes from the collector.
                for i, value in enumerate([0, 7, 11]):
                    send(
                        local,
                        "codex.turn.cost_microusd",
                        value,
                        start + i * 1000000,
                        start + (i + 1) * 1000000,
                        {"host": "unknown"},
                        {"turn.id": str(i), "conversation.id": str(i)},
                    )
                # Two simultaneous Pi processes remain separate streams.
                for instance, value in [("a", 3), ("b", 5)]:
                    resource = {"service.name": "pi", "service.instance.id": instance}
                    send(local, "pi.token.usage", 0, start, start + 1000000, resource)
                    send(
                        local,
                        "pi.token.usage",
                        value,
                        start + 1000000,
                        start + 2000000,
                        resource,
                    )
                send(legacy, "legacy.probe", 1, start, start + 1000000)
                send(
                    legacy,
                    "legacy.probe",
                    2,
                    start,
                    start + 1000000,
                    {"deployment.environment.name": "home-legacy-test"},
                )

                def query(name):
                    expr = urllib.parse.urlencode({"query": name, "nocache": "1"})
                    with urllib.request.urlopen(
                        f"http://127.0.0.1:{vm}/api/v1/query?{expr}", timeout=2
                    ) as response:
                        return json.load(response)["data"]["result"]

                def check():
                    cost = query("codex_turn_cost_microusd")
                    assert len(cost) == 1 and float(cost[0]["value"][1]) == 18, cost
                    metric = cost[0]["metric"]
                    assert metric["host"] == "B450M-Pro4", metric
                    assert (
                        "turn_id" not in metric and "conversation_id" not in metric
                    ), metric
                    pi = query("pi_token_usage")
                    assert sorted(float(p["value"][1]) for p in pi) == [3, 5], pi
                    old = query("legacy_probe")
                    assert {p["metric"]["host"] for p in old} == {
                        "unknown",
                        "legacy-test",
                    }, old
                    return True

                wait_for(check)
                print(
                    "PASS: host identity, per-turn cost accumulation, concurrent Pi streams, legacy identity"
                )
            except BaseException:
                log.flush()
                print((root / "process.log").read_text()[-6000:])
                print(
                    "Observed:",
                    {
                        name: query(name)
                        for name in [
                            "codex_turn_cost_microusd",
                            "pi_token_usage",
                            "legacy_probe",
                        ]
                    },
                )
                raise
            finally:
                for process in reversed(processes):
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()


if __name__ == "__main__":
    main()
