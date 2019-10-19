#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################

## enable case insensitve matching
shopt -s nocaseglob

XS_ENABLE_IPV6=${UNBOUND_ENABLE_IPV6:-no}

echo "Setting console permissions..."
chown root:tty /dev/console
chmod g+rw /dev/console

echo "Receiving anchor key..."
/usr/sbin/unbound-anchor -a /etc/unbound/keys/trusted.key

echo "Receiving root hints..."
curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

echo "Configure Storage"
mkdir -p /etc/unbound/keys
chmod +w /etc/unbound/keys
chown -R unbound /etc/unbound

echo "Enable remote control and init keys"
/usr/sbin/unbound-control-setup -d /etc/unbound/keys/

if [ "$XS_ENABLE_IPV6" == "yes" ] || [ "$XS_ENABLE_IPV6" == "true" ] || [ "$XS_ENABLE_IPV6" == "on" ] || [ "$XS_ENABLE_IPV6" == "1" ] ; then
  sed -i "s/do-ip6: no/do-ip6: yes/g" /etc/unbound/unbound.conf
  sed -i "s/prefer-ip6: no/prefer-ip6: yes/g" /etc/unbound/unbound.conf
  echo "IPv6 Enabled"
else
  sed -i "s/do-ip6: yes/do-ip6: no/g" /etc/unbound/unbound.conf
  sed -i "s/prefer-ip6: yes/prefer-ip6: no/g" /etc/unbound/unbound.conf
  echo "IPv6 Disabled"
fi

/usr/sbin/unbound-checkconf /etc/unbound/unbound.conf
result=$?
if [ "$result" != "0" ] ; then
  echo "ERROR: CONFIG DAMAGED, sleeping ......"
  sleep 1d
  exit 1
fi

exec /usr/sbin/unbound
