#!/bin/sh

DHCP_CONF="etc/dhcpcd.conf"
NETWORK_INTERFACE_FILE="etc/network/interfaces"
IP_ADDR="192.168.1.100"
NETMASK="255.255.255.0"
NETWORK="192.168.1.1"
BROADCAST="192.168.1.255"

IFACE_OUT="wlan0"
PI_ROUTER_SSID="Pi3-AP"
PI_ROUTER_PASSWORD="raspberry"

## Deny wlan interface which will be used for outgoing traffic.
to_add="denyinterfaces wlan0"
if grep -Fxq "$to_add" $DHCP_CONF; then
	echo "Interface wlan0 already denied."
else
	echo $to_add >> $DHCP_CONF
	echo "Interface wlan0 denied in $DHCP_CONF"
fi

## Make the outgoing network interface use static ip
iface_dynamic="iface $IFACE_OUT inet dynamic"
iface_static="iface $IFACE_OUT inet static\n\
\taddress ${IP_ADDR}\n\
\tnetmask ${NETMASK}\n\
\tnetwork ${NETWORK}\n\
\tbroadcast ${BROADCAST}"

sed -i.bak "s/$iface_dynamic/$iface_static/" "$NETWORK_INTERFACE_FILE"

## Open template hostapd.conf file and do replacements
sed -e "s/\${IFACE_OUT}/$IFACE_OUT/" \
	-e "s/\${PI_ROUTER_SSID}/$PI_ROUTER_SSID/" \
	-e "s/\${PI_ROUTER_PASSWORD}/$PI_ROUTER_PASSWORD/" hostapd-template.conf > etc/hostapd/hostapd.conf