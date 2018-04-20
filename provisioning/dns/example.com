; Hash: 120b85e961e8cd947b47f5742c1e15fb 18042020
; Zone file for example.com
; Ansible managed

$ORIGIN example.com
$TTL 1W

@ IN SOA ns1.example.com hostmaster.example.com (
  18042020
  1D
  1H
  1W
  1D )

                     IN  NS     ns1.example.com
                     IN  NS     ns1.example.com

ns1                  IN  A      192.168.56.10
ns2                  IN  A      192.168.56.11
dc                   IN  A      192.168.56.40
web                  IN  A      192.168.56.172
www                  IN  CNAME  web
db                   IN  A      192.168.56.173

priv0001             IN  A      172.16.0.10
priv0002             IN  A      172.16.0.11

_ldap._tcp           IN  SRV    0 100 88 dc
_kerberos._tcp       IN  SRV    0 100 88 dc
_kerberos._udp       IN  SRV    0 100 88 dc
_kerberos-master._tcp IN  SRV    0 100 88 dc
_kerberos-master._udp IN  SRV    0 100 88 dc
_kpasswd._tcp        IN  SRV    0 100 464 dc
_kpasswd._udp        IN  SRV    0 100 464 dc
