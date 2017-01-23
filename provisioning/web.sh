#! /usr/bin/env bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# Installs a simple LAMP stack

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

#mariadb_root_password='7OdFobyak}0vedutNat+'
#wordpress_database='wordpress'
#wordpress_user='wordpress_user'
#wordpress_password='Amt_OtMat7'
#}}}

main() {
  install_packages
}

#{{{ Helper functions

install_packages() {

  info "Installing packages"

  yum install -y epel-release
  yum install -y \
    audit \
    bind-utils \
    git \
    httpd \
    mod_ssl \
    php \
    php-mysql \
    psmisc \
    tree \
    vim-enhanced \
    wordpress
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
