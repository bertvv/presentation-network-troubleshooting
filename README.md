# Troubleshooting Network Services (on EL7)

This repository contains the slides and code examples for my talk at [CentOS Dojo 2018 in Brussels](https://wiki.centos.org/Events/Dojo/Brussels2018) and workshop at [LOADays 2018](http://loadays.org/pages/network-troubleshooting.html). The slides can be viewed here: <https://bertvv.github.io/presentation-network-troubleshooting/>.

The CentOS Dojo talk was recorded and is [published on Youtube](https://www.youtube.com/watch?v=GoyC2PBGLj8&t=1584s).

As a reference guide to the content of this talk/workshop, check out my guide "Troubleshooting network services in Linux" at <https://bertvv.github.io/linux-network-troubleshooting/>.

## Setting up the demo environment

The demo environment is included in this repository as a Vagrant environment. To run it yourself, you can do the following:

- Ensure the necessary software is installed:
    - [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (inlcuding Extension pack)
    - [Vagrant](https://www.vagrantup.com/)
    - [Git](https://git-scm.com/)
- Clone the repository and start the environment:

```shell
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

## Assignment 1: Web + database server

The setup consists of two VirtualBox VMs:

| Host  | IP            | Service              |
| :---  | :---          | :---                 |
| `web` | 192.168.56.72 | http, https (Apache) |
| `db`  | 192.168.56.73 | mysql (MariaDB)      |

- On `web`, a PHP app runs a query on the `db`
- `db` is set up correctly, `web` is not

Throughout the presentation, we'll be fixing issues with `web`.

## Assignment 2: BIND master/slave DNS servers

A second assignment consists of two authoritative-only DNS servers (master-slave) for the domain *example.com*, set up with ISC BIND. These two VMs can be booted after you edit [vagrant-hosts.yml](vagrant-hosts.yml) an uncomment the following lines:

```yaml
- name: ns1
  ip: 192.168.56.10

- name: ns2
  ip: 192.168.56.11
```

| Host  | IP            | Service    |
| :---  | :---          | :---       |
| `ns1` | 192.168.56.10 | Master DNS |
| `ns2` | 192.168.56.11 | Slave DNS  |

- `ns1`, as the master DNS, contains the zone files (and is not set up correctly)
- `ns2` is set up correctly, and as a slave will receive DNS records from the master by zone transfer

An acceptance test is provided that validates whether both servers are available to clients on the network and resolve host names and IP addresses for the domain correctly. The assignment is completed if you see the following output:

```console
$ ./tests/runtests.sh 
Testing 192.168.56.10
 ✓ The dig command should be installed
 ✓ It should return the NS record(s)
 ✓ It should be able to resolve host names
 ✓ It should be able to do reverse lookups
 ✓ It should be able to resolve aliases
 ✓ It should return the SRV record(s)

6 tests, 0 failures
Testing 192.168.56.11
 ✓ The dig command should be installed
 ✓ It should return the NS record(s)
 ✓ It should be able to resolve host names
 ✓ It should be able to do reverse lookups
 ✓ It should be able to resolve aliases
 ✓ It should return the SRV record(s)

6 tests, 0 failures
```

## Compiling the slides

The slides were created using [Pandoc](http://pandoc.org/) The [source file](troubleshooting-network-services.md) in [Markdown](https://daringfireball.net/projects/markdown/) was converted into a [Reveal js](http://lab.hakim.se/reveal-js/#/) presentation. A [Makefile](Makefile) is provided to automate the build process.

After ensuring you have Pandoc installed, run `make all` to generate the presentation. You can find it in the [`docs/`](docs/) folder.

## License

This work is licensed under a [Creative Commons Attribution 4.0 International License](http://creativecommons.org/licenses/by/4.0/). Source code of the examples is licensed under the [2-clause BSD License](LICENSE.md).

