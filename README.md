# vuln-deb

A vulnerable Debian-based VM for telnet lab practice.

> ⚠️ **Lab use only**: This VM is intentionally insecure and must only be used in an isolated local environment.

## What this repository provides

- A Vagrant VM based on `debian/bookworm64`
- Private host-only network at `192.168.56.10`
- Automated provisioning script that installs and configures a vulnerable telnet setup

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
