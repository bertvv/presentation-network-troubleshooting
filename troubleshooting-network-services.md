% Troubleshooting Network Services (on EL7)
% Bert Van Vreckem
% CentOS Dojo 2018 Brussels, 2018-02-02

# Introduction

## `whoami`

- Bert Van Vreckem
- *Lector ICT* at University College Ghent (HoGent)
    - BS programme Applied Informatics
    - Mainly Linux, research techniques
- *Open source* contributor: <https://github.com/bertvv/>
    - Ansible roles
    - Scripts
    - Learning resources

## This talk is for you if

- Linux/CentOS novice
- Unfamiliar with EL7/systemd
- Struggle with network services

## Agenda

- Bottom-up approach
- Network access (Link) layer
- Internet layer
- Transport
- Application Layer
- SELinux

<https://github.com/bertvv/presentation-network-troubleshooting/>

## Remarks

**Interrupt me if you have remarks/questions!**

Presentation, example code:

<https://github.com/bertvv/presentation-network-troubleshooting/>

Troubleshooting guide

<https://bertvv.github.io/linux-network-troubleshooting/>

## Case: web + db server

Two VirtualBox VMs, set up with Vagrant

| Host  | IP            | Service              |
| :---  | :---          | :---                 |
| `web` | 192.168.56.72 | http, https (Apache) |
| `db`  | 192.168.56.73 | mysql (MariaDB)      |

- On `web`, a PHP app runs a query on the `db`
- `db` is set up correctly, `web` is not

## Objective

![The PHP application](img/result.png)

## Running the demo environment

```console
$ git clone https://github.com/bertvv/presentation-network-troubleshooting.git
[...]
$ cd presentation-network-troubleshooting/
$ vagrant status
Current machine states:

db                        not created (virtualbox)
web                       not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
$ vagrant up
[...]
```

## Test the database server

```shell
$ ./query_db.sh 
+ mysql --host=192.168.56.73 --user=demo_user \
+   --password=ArfovWap_OwkUfeaf4 demo \
+   '--execute=SELECT * FROM demo_tbl;'
+----+-------------------+
| id | name              |
+----+-------------------+
|  1 | Tuxedo T. Penguin |
|  2 | Johnny Tables     |
+----+-------------------+
+ set +x
```

## Use a bottom-up approach

TCP/IP protocol stack

| Layer          | Protocols                | Keywords              |
| :---           | :---                     | :---                  |
| Application    | HTTP, DNS, SMB, FTP, ... |                       |
| Transport      | TCP, UDP                 | sockets, port numbers |
| Internet       | IP, ICMP                 | routing, IP address   |
| Network access | Ethernet                 | switch, MAC address   |
| Physical       |                          | cables                |

# Network Access Layer

## Network Access Layer

- bare metal:
    - test the cable(s)
    - check switch/NIC LEDs
- VM (e.g. VirtualBox):
    - check virtual network adapter type & settings
- `ip link`

## VirtualBox networking: NAT

![VirtualBox NAT Adapter](img/VirtualBox-networking-NAT.png)

## VirtualBox networking: NAT

- Reliable *Internet access*
- **Not routable** from host system

## VirtualBox networking: bridged

![VirtualBox Bridged Adapter](img/VirtualBox-networking-bridged.png)

## VirtualBox networking: bridged

- *Routable* from host system
- **Inconsistent** IP settings
    - May not recieve IP settings from DHCP

## Virtualbox networking: host-only

![VirtualBox Host-only Adapter](img/VirtualBox-networking-HO.png)

## VirtualBox networking: host-only

- *Routable* from host system
- *Consistent* IP settings
- **No Internet** access

# Internet Layer

## Checklist: Internet Layer

- Local network configuration:
    - IP address: `ip a`
    - Default gateway: `ip r`
    - DNS service: `/etc/resolv.conf`
- LAN connectivity:
    - Ping between hosts
    - Ping default GW/DNS
    - Query DNS (`dig`, `nslookup`, `getent`)

*Know the expected values!*

## VirtualBox networking: NAT

| Host    | IP           |
| :---    | :---         |
| VM      | 10.0.2.15/24 |
| Gateway | 10.0.2.2     |
| DNS     | 10.0.2.3     |

## VirtualBox networking: host-only

The "default" host-only network:

|              | IP              |
| :---         | :---            |
| Host system  | 192.168.56.1/24 |
| Virtual DHCP | 192.168.56.100  |
| Range from   | 192.168.56.101  |
| Range to     | 192.168.56.254  |

## Checklist: Internet Layer

- *Local network configuration:*
    - IP address: `ip a`
    - Default gateway: `ip r`
    - DNS service: `/etc/resolv.conf`
- LAN connectivity:
    - Ping between hosts
    - Ping default GW/DNS
    - Query DNS (`dig`, `nslookup`, `getent`)

## Local configuration: `ip address`

- IP address?
- In correct subnet?
- DHCP or fixed IP?
- Check configuration: `/etc/sysconfig/network-scripts/ifcfg-*`

## Common causes (DHCP)

- No IP
    - DHCP unreachable
    - DHCP won't give an IP
- 169.254.x.x
    - No DHCP offer, "link-local" address
- Unexpected subnet
    - Bad config (fixed IP set?)

## Common causes (Fixed IP)

- Unexpected subnet
    - Check config
- Correct IP, "network unreachable"
    - Check network mask

## Local configuration: `ip route`

- Default GW present?
- In correct subnet?
- Check network configuration

## DNS server: `/etc/resolv.conf`

- `nameserver` option present?
- Expected IP?

## Checklist: Internet Layer

- Local network configuration:
    - IP address: `ip a`
    - Default gateway: `ip r`
    - DNS service: `/etc/resolv.conf`
- *LAN connectivity*:
    - Ping between hosts
    - Ping default GW/DNS
    - Query DNS (`dig`, `nslookup`, `getent`)

## LAN connectivity: `ping`

- host -> VM: `ping 192.168.56.72`
- VM -> host: `ping 192.168.56.1`
- VM -> GW: `ping 10.0.2.2`
- VM -> DNS: `ping 10.0.2.3`

Remark: some routers **block** ICMP!

## LAN connectivity: DNS

- `dig icanhazip.com`
- `nslookup icanhazip.com`
- `getent ahosts icanhazip.com`

## LAN connectivity

Next step: routing beyond GW

# Transport Layer

## Checklist: Transport Layer

- Service running? `sudo systemctl status SERVICE`
- Correct port/inteface? `sudo ss -tulpn`
- Firewall settings: `sudo firewall-cmd --list-all`

## Is the service running?

`systemctl status httpd.service`

- `Active: active (running)` vs. `inactive (dead)`
    - `systemctl start httpd`
    - Fail? See below (Application layer)
- Start at boot: `enabled` vs. `disabled`
    - `systemctl enable httpd`

## Correct ports/interfaces?

- Use `ss` (not `netstat`)
    - TCP service: `sudo ss -tlnp`
    - UDP service: `sudo ss -ulnp`
- Correct port number?
    - See `/etc/services`
- Correct interface?
    - Only loopback?

## Firewall settings

`sudo firewall-cmd --list-all`

- Is the service or port listed?
- Use `--add-service` if possible
    - Supported: `--get-services`
- Don't use both `--add-service` and `--add-port`
- Add `--permanent`
- `--reload` firewall rules

---

```console
$ sudo firewall-cmd --add-service=http --permanent
$ sudo firewall-cmd --add-service=https --permanent
$ sudo firewall-cmd --reload
```

# Application Layer

## Checklist: Application Layer

- Check the logs `journalctl`
- Check config file syntax
- Other checks are application dependent
    - Read the reference manuals!

## Check the log files

- Either `journalctl`: `journalctl -f -u httpd.service`
- Or `/var/log/`:
    - `tail -f /var/log/httpd/error_log`

## Check config file syntax

- Application dependent, for Apache: `apachectl configtest`

## Read the fine manual!

- [RedHat Manuals](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/):
    - System Administrator's Guide
    - Networking guide
    - SELinux guide
- Reference manuals, e.g.:
    - <https://httpd.apache.org/docs/2.4/configuring.html>
- Man pages
    - smb.conf(5), dhcpd.conf(5), named.conf(5), ...

# SELinux troubleshooting

## SELinux

- SELinux is Mandatory Access Control in the Linux kernel
- Settings:
    - Booleans: `getsebool`, `setsebool`
    - Contexts, labels: `ls -Z`, `chcon`, `restorecon`
    - Policy modules: `sepolicy`

## Do not disable SELinux

<https://stopdisablingselinux.com/>

## Check file context

- Is the file context as expected?
    - `ls -Z /var/www/html`
- Set file context to default value
    - `sudo restorecon -R /var/www/`
- Set file context to specified value
    - `sudo chcon -t httpd_sys_content_t test.php`

## Check booleans

`getsebool -a | grep http`

- Know the relevant booleans! (RedHat manuals)
- Enable boolean:
    - `sudo setsebool -P httpd_can_network_connect_db on`

## Creating a policy

Let's try to set `DocumentRoot "/vagrant/www"`

```
$ sudo vi /etc/httpd/conf/httpd.conf
$ ls -Z /vagrant/www/
-rw-rw-r--. vagrant vagrant system_u:object_r:vmblock_t:s0   test.php
$ sudo chcon -R -t httpd_sys_content_t /vagrant/www/
chcon: failed to change context of ‘test.php’ to ‘system_u:object_r:httpd_sys_content_t:s0’: Operation not supported
chcon: failed to change context of ‘/vagrant/www/’ to ‘system_u:object_r:httpd_sys_content_t:s0’: Operation not supported
```

## Creating a policy

Instead of setting the files to the expected context, allow httpd to access files with `vmblock_t` context

1. Allow Apache to run in "permissive" mode:

    ```
    $ sudo semanage permissive -a httpd_t
    ```

2. Generate "Type Enforcement" file (.te)

    ```
    $ sudo audit2allow -a -m httpd-vboxsf > httpd-vboxsf.te
    ```

3. If necessary, edit the policy

    ```
    $ sudo vi httpd-vboxsf.te
    ```

---

1. Convert to policy module (.pp)

    ```
    $ checkmodule -M -m -o httpd-vboxsf.mod httpd-vboxsf.te
    $ semodule_package -o httpd-vboxsf.pp -m httpd-vboxsf.mod
    ```

5. Install module

    ```
    $ sudo semodule -i httpd-vboxsf.pp
    ```

6. Remove permissive domain exception

    ```
    $ sudo semanage permissive -d httpd_t
    ```

Tip: automate this!

# General guidelines

## Back up config files before changing

## Be systematic, bottom-up

## Be thorough, don't skip steps

## Do not assume: test

## Know your environment

## Know your log files

![Credit: @KrisBuytaert](img/reading-errorlog-files-small.jpg)

## Open logs in separate terminal

## Read The F*** Error Message!

## Small steps

## Validate the syntax of config files

## Don't forget to reload service after config change

## Verify each change

## Keep a cheat sheet/checklist

## Use a configuration management system

## Automate tests

## Never ping Google!

# That's it!

## Thank you!

[&#64;bertvanvreckem](https://twitter.com/bertvanvreckem/)

<https://github.com/bertvv/>

<https://bertvv.github.io/linux-network-troubleshooting/>

<https://github.com/bertvv/cheat-sheets/>


