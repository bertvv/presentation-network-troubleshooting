# Troubleshooting Network Services (on EL7)

This repository contains the slides and code examples for my talk at [CentOS Dojo 2018 in Brussels](https://wiki.centos.org/Events/Dojo/Brussels2018). The slides can be viewed here: <https://bertvv.github.io/presentation-network-troubleshooting/>.

Check out my guide "Troubleshooting network services in Linux" at <https://bertvv.github.io/linux-network-troubleshooting/>.

## Compiling the slides

The slides were created using [Pandoc](http://pandoc.org/) The [source file](troubleshooting-network-services.md) in [Markdown](https://daringfireball.net/projects/markdown/) was converted into a [Reveal js](http://lab.hakim.se/reveal-js/#/) presentation. A [Makefile](Makefile) is provided to automate the build process.

After ensuring you have Pandoc installed, run `make all` to generate the presentation. You can find it in the [`docs/`](docs/) folder.

## Running the code

During the presentation, I use the included Vagrant environment as a demo. To recreate the setup, do:

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

The setup consists of two VirtualBox VMs:

| Host  | IP            | Service              |
| :---  | :---          | :---                 |
| `web` | 192.168.56.72 | http, https (Apache) |
| `db`  | 192.168.56.73 | mysql (MariaDB)      |

- On `web`, a PHP app runs a query on the `db`
- `db` is set up correctly, `web` is not

Throughout the presentation, we'll be fixing issues with `web`.

## License

This work is licensed under a [Creative Commons Attribution 4.0 International License](http://creativecommons.org/licenses/by/4.0/). Source code of the examples is licensed under the [2-clause BSD License](LICENSE.md).

