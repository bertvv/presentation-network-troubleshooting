#! /usr/bin/env bash
#
# Installs and configures MariaDB

#{{{ Bash settings
# abort on nonzero exitstatus
set -o errexit
# abort on unbound variable
set -o nounset
# don't hide errors within pipes
set -o pipefail
#}}}
#{{{ Variables
IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

#}}}

main() {
  # Ensure vagrant can read logs without sudo
  usermod --append --groups adm vagrant

  install_packages
  start_basic_services
  setup_bind

}

#{{{ Helper functions

install_packages() {

  info "Installing packages"

  yum install -y epel-release
  yum install -y \
    audit \
    bash-completion \
    bash-completion-extras \
    bind-utils \
    git \
    bind \
    bind-utils \
    pciutils \
    policycoreutils-python \
    psmisc \
    tree \
    vim-enhanced

}

start_basic_services() {
  info "Starting essential services"
  systemctl start auditd.service
  systemctl restart network.service
  systemctl start firewalld.service
}

setup_bind() {
  info "Starting BIND"
  systemctl start named.service
  systemctl enable named.service
  firewall-cmd --add-service=dns
  firewall-cmd --add-service=dns --permanent

  cp /vagrant/provisioning/dns/named-slave.conf /etc/named.conf

  systemctl reload named
}

# Color definitions
readonly reset='\e[0m'
readonly cyan='\e[0;36m'
readonly red='\e[0;31m'
readonly yellow='\e[0;33m'

# Usage: info [ARG]...
#
# Prints all arguments on the standard output stream
info() {
  printf "${yellow}>>> %s${reset}\n" "${*}"
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard output stream
debug() {
  printf "${cyan}### %s${reset}\n" "${*}"
}

# Usage: error [ARG]...
#
# Prints all arguments on the standard error stream
error() {
  printf "${red}!!! %s${reset}\n" "${*}" 1>&2
}
#}}}

main "${@}"

