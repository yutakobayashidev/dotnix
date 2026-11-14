"""Compile pinned domain lists into native CoreDNS configuration, offline."""

import argparse
from pathlib import Path
import re


def read_domains(path, *, adblock=False):
    domains = set()
    for number, line in enumerate(Path(path).read_text().splitlines(), 1):
        value = line.split("#", 1)[0].strip()
        if not value or value.startswith("!"):
            continue
        if adblock:
            if not (value.startswith("||") and value.endswith("^")):
                raise ValueError(f"{path}:{number}: unsupported CNAME rule")
            value = value[2:-1]
        value = value.lower().rstrip(".")
        labels = value.split(".")
        if (
            len(value) > 253
            or len(labels) < 2
            or any(
                not re.fullmatch(r"[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9_])?", label)
                for label in labels
            )
        ):
            raise ValueError(f"{path}:{number}: invalid domain {value!r}")
        domains.add(value)
    return domains


def covered(name, domains):
    labels = name.split(".")
    return any(".".join(labels[i:]) in domains for i in range(len(labels)))


def minimal(domains):
    # Remove children to avoid empty nodes overriding a parent's DNS wildcard.
    return sorted(d for d in domains if not covered(d.partition(".")[2], domains))


def generate(args):
    domains = read_domains(args.domains)
    cnames = read_domains(args.cnames, adblock=True)
    if not domains or not cnames:
        raise ValueError("Upstream blocklists must not be empty")
    allow = read_domains(args.allowlist)
    protected = set(args.protected)
    for domain in allow | domains | cnames | read_domains(args.blocklist):
        if covered(domain, protected) or any(covered(p, {domain}) for p in protected):
            raise ValueError(f"Policy overlaps protected zone: {domain}")
    blocked = minimal(domains | cnames | read_domains(args.blocklist))
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    # A sparse root zone provides wildcard NODATA for every address/service type.
    # TXT is a diagnostic marker, not a destination; root SOA is local metadata.
    # https://coredns.io/plugins/file/
    with (output / "blocked.zone").open("w") as zone:
        zone.write("$ORIGIN .\n$TTL 60\n")
        zone.write("@ IN SOA localhost. hostmaster.invalid. 1 60 60 60 60\n")
        for domain in blocked:
            if not covered(domain, allow):
                zone.write(f'{domain}. IN TXT "blocked"\n')
                zone.write(f'*.{domain}. IN TXT "blocked"\n')
    # Label boundaries prevent matching e.g. nottracker.example for tracker.example.
    # https://github.com/AdguardTeam/cname-trackers
    with (output / "cname.conf").open("w") as rules:
        rules.write("# Generated CNAME target policy.\n")
        for domain in minimal(cnames):
            if not covered(domain, allow):
                pattern = domain.replace(".", "[.]")
                rules.write(
                    f"rewrite stop cname regex (?i)(^|[.]){pattern}[.]$ blocked.invalid.\n"
                )
    with (output / "allowlist.conf").open("w") as rules:
        rules.write(
            "# Queried-name exceptions bypass both direct and CNAME filtering.\n"
        )
        for domain in minimal(allow):
            rules.write(
                f"{domain}:53 {{\n"
                "    import common\n    import cached\n    import upstream\n}\n"
            )
    print(f"Policy: {len(blocked)} domain subtrees, {len(cnames)} CNAME targets")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("domains", "cnames", "blocklist", "allowlist", "output"):
        parser.add_argument(f"--{name}", required=True)
    parser.add_argument("--protected", nargs="*", default=[])
    generate(parser.parse_args())
