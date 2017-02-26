#!/bin/bash

DHCP_CONF="etc/dhcpcd.conf"
NETWORK_INTERFACE_FILE="etc/network/interfaces"
HOSTAPD_CONF_FILE="etc/hostapd/hostapd.conf"
HOSTAPD_DEFAULT_CONF_FILE="etc/default/hostapd"
DNSMASQ_CONF_FILE="etc/dnsmasq.conf"

rm -v $HOSTAPD_CONF_FILE
rm -v $DNSMASQ_CONF_FILE

mv -v "$NETWORK_INTERFACE_FILE.bak" $NETWORK_INTERFACE_FILE
mv -v "$HOSTAPD_DEFAULT_CONF_FILE.bak" $HOSTAPD_DEFAULT_CONF_FILE
mv -v "$DHCP_CONF.bak" $DHCP_CONF
