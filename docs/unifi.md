# UniFi Network

UniFi Network runs on B450M-Pro4 using `services.unifi`. Open
<https://unifi.home.yutakobayashi.com> from the Tailnet to complete the initial
setup. Traefik terminates HTTPS and forwards requests to the controller's local
HTTPS listener on port 8443. Port 8443 is not opened in the firewall.

The configuration opens TCP 8080 (device inform), 18880 and 8843 (guest portal),
6789 (mobile speed test), and UDP 3478 (STUN) and 10001 (discovery).
Devices on the home LAN can use `http://192.168.0.5:8080/inform` as their inform
URL. This is the server's current DHCP address; keep its lease reserved when
adopting devices. Adoption and changes to device configuration are separate
from deploying the controller.

The controller stores its database and configuration in `/var/lib/unifi`,
covered by the host's persistent `/var/lib` mount. Configure and download
controller backups in the UniFi UI before upgrades or device migrations.

Kubo's loopback gateway uses `http://127.0.0.1:18080` to leave port 8080 available
for UniFi devices. UniFi's HTTP guest portal uses port 18880 because vmalert
already occupies 8880. A service pre-start step manages only that property in
the controller's writable `system.properties` file.

Check the service with `systemctl status unifi` and inspect startup logs with
`journalctl -u unifi`. Application logs are in `/var/log/unifi`.
