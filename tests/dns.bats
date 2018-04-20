#! /usr/bin/env bats
#
# Acceptance test for the configuration defined in test.yml.
#
# Variable ${ns_ip} should be set outside of this script, e.g.
#
# SYSTEM_UNDER_TEST=192.168.56.10 bats dns.bats

SYSTEM_UNDER_TEST=${SYSTEM_UNDER_TEST:-ns}
DOMAIN=${DOMAIN:-example.com}

#{{{ Helper functions


# Usage: assert_forward_lookup NAME IP4
#
# Exits with status 0 if NAME.DOMAIN resolves to IP4 (an IPv4 address), a
# nonzero status otherwise
assert_forward_lookup() {
  local name="$1"
  local expected="$2"
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" "${name}.${DOMAIN}" +short)

  printf "Expected: %s\n" "${expected}"
  printf "Actual  : %s\n" "${result}"

  [ "${expected}" = "${result}" ]
}

# Usage: assert_forward_ipv6_lookup NAME IP6
#
# Exits with status 0 if NAME.DOMAIN resolves to IP6 (an IPv6 address), a
# nonzero status otherwise
assert_forward_ipv6_lookup() {
  local name="${1}"
  local expected="$2"
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" AAAA "${name}.${DOMAIN}" +short)

  printf "Expected: %s\n" "${expected}"
  printf "Actual  : %s\n" "${result}"

  [ "${expected}" = "${result}" ]
}

# Usage: assert_reverse_lookup NAME IP
#
# Exits with status 0 if a reverse lookup on IP resolves to NAME,
# a nonzero status otherwise
assert_reverse_lookup() {
  local name="$1"
  local ip="$2"
  local expected="${name}.${DOMAIN}."
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" -x "${ip}" +short)

  printf "Expected: %s\n" "${expected}"
  printf "Actual  : %s\n" "${result}"

  [ "${expected}" = "${result}" ]
}

# Usage: assert_alias_lookup ALIAS NAME IP
#
# Exits with status 0 if a forward lookup on NAME resolves to the
# host name NAME.DOMAIN and to IP, a nonzero status otherwise
assert_alias_lookup() {
  local alias="$1"
  local name="$2"
  local ip="$3"
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" "${alias}.${DOMAIN}" +short)

  grep "${name}\.${DOMAIN}\." <<< "${result}"
  grep "${ip}" <<< "${result}"
}

# Usage: assert_ns_lookup NS_NAME...
#
# Exits with status 0 if all specified host names occur in the list of
# name servers for the domain.
assert_ns_lookup() {
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" "${DOMAIN}" NS +short)

  [ -n "${result}" ] # the list of name servers should not be empty

  while (( "$#" )); do
    grep "$1\.${DOMAIN}\." <<< "${result}"
    shift
  done
}

# Usage: assert_mx_lookup PREF1 NAME1 PREF2 NAME2...
#   e.g. assert_mx_lookup 10 mailsrv1 20 mailsrv2
#
# Exits with status 0 if all specified host names occur in the list of
# mail servers for the domain.
assert_mx_lookup() {
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" "${DOMAIN}" MX +short)

  [ -n "${result}" ] # the list of name servers should not be empty
  while (( "$#" )); do
    echo "${result}" | grep "$1 $2\.${DOMAIN}\."
    shift
    shift
  done
}

# Usage: assert_srv_lookup SERVICE WEIGHT PORT TARGET
#
#  e.g.  assert_srv_lookup _ldap._tcp 0 100 88 ldapsrv
assert_srv_lookup() {
  local service="${1}"
  shift
  local expected="${*}.${DOMAIN}."
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" SRV "${service}.${DOMAIN}" +short)

  printf "Expected: %s\n" "${expected}"
  printf "Actual  : %s\n" "${result}"

  [ "${expected}" = "${result}" ]
}

# Perform a TXT record lookup
# Usage: assert_txt_lookup NAME TEXT...
assert_txt_lookup() {
  local name="$1"
  local result

  result=$(dig @"${SYSTEM_UNDER_TEST}" TXT "${name}" +short)
  shift

  printf "Expected: %s\n" "${*}"
  printf "Actual  : %s\n" "${result}"

  while [ "$#" -ne "0" ]; do
    grep "${1}" <<< "${result}"
    shift
  done
}

#}}}

@test 'The dig command should be installed' {
  which dig
}

@test 'It should return the NS record(s)' {
  result="$(dig @${SYSTEM_UNDER_TEST} ${DOMAIN} NS +short)"
  [ -n "${result}" ] # The result should not be empty
}

@test 'It should be able to resolve host names' {
  assert_forward_lookup ns1        192.168.56.10
  assert_forward_lookup ns2        192.168.56.11

  assert_forward_lookup dc         192.168.56.40

  assert_forward_lookup web        192.168.56.72
  assert_forward_lookup db         192.168.56.73

  assert_forward_lookup priv0001   172.16.0.10
  assert_forward_lookup priv0002   172.16.0.11
}

@test 'It should be able to do reverse lookups' {
  assert_reverse_lookup ns1        192.168.56.10
  assert_reverse_lookup ns2        192.168.56.11

  assert_reverse_lookup dc         192.168.56.40

  assert_reverse_lookup web        192.168.56.72
  assert_reverse_lookup db         192.168.56.73

  assert_reverse_lookup priv0001   172.16.0.10
  assert_reverse_lookup priv0002   172.16.0.11
}

@test 'It should be able to resolve aliases' {
  assert_alias_lookup www  web 192.168.56.72
}

@test 'It should return the SRV record(s)' {
  assert_srv_lookup _ldap._tcp            0 100 88  dc
  assert_srv_lookup _kerberos._tcp        0 100 88  dc
  assert_srv_lookup _kerberos._udp        0 100 88  dc
  assert_srv_lookup _kerberos-master._tcp 0 100 88  dc
  assert_srv_lookup _kerberos-master._udp 0 100 88  dc
  assert_srv_lookup _kpasswd._tcp         0 100 464 dc
  assert_srv_lookup _kpasswd._udp         0 100 464 dc
}
