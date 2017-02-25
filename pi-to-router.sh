#!/bin/sh

## Original tutorial: https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/
## https://webcache.googleusercontent.com/search?q=cache:8nfWTN8xUhwJ:https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/+&cd=1&hl=en&ct=clnk&gl=ph

DHCP_CONF="etc/dhcpcd.conf"
NETWORK_INTERFACE_FILE="etc/network/interfaces"
HOSTAPD_CONF_FILE="etc/hostapd/hostapd.conf"
HOSTAPD_DEFAULT_CONF_FILE="etc/default/hostapd"
DNSMASQ_CONF_FILE="etc/dnsmasq.conf"


IP_ADDR="192.168.1.100"
NETMASK="255.255.255.0"
NETWORK="192.168.1.1"
BROADCAST="192.168.1.255"

IFACE_IN="wlan0"
IFACE_OUT="wlan1"
PI_ROUTER_SSID="Pi3-AP"
PI_ROUTER_PASSWORD="raspberry"
DHCP_RANGE_START="192.168.1.50"
DHCP_RANGE_END="192.168.1.150"

## Deny wlan interface which will be used for outgoing traffic.
to_add="denyinterfaces $IFACE_OUT"
if grep -Fxq "$to_add" $DHCP_CONF; then
	echo "Interface $IFACE_OUT already denied."
else
	echo $to_add >> $DHCP_CONF
	echo "Interface $IFACE_OUT denied in $DHCP_CONF"
fi

## Make the outgoing network interface use static ip

#iface_dynamic="iface $IFACE_OUT inet dynamic"

iface_manual="iface $IFACE_OUT inet manual\n\
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf"

iface_static="iface $IFACE_OUT inet static\n\
\taddress ${IP_ADDR}\n\
\tnetmask ${NETMASK}\n\
\tnetwork ${NETWORK}\n\
\tbroadcast ${BROADCAST}"

echo "Replacing $iface_manual"

sed -i.bak -e "{N;s|$iface_manual|$iface_static|}" "$NETWORK_INTERFACE_FILE"

## Open template hostapd.conf file and do replacements
sed -e "s/\${IFACE_OUT}/$IFACE_OUT/" \
	-e "s/\${PI_ROUTER_SSID}/$PI_ROUTER_SSID/" \
	-e "s/\${PI_ROUTER_PASSWORD}/$PI_ROUTER_PASSWORD/" hostapd-template.conf > $HOSTAPD_CONF_FILE

## Edit hostapd default configuration file for startup
sed -i.bak 's|.*DAEMON_CONF=".*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' $HOSTAPD_DEFAULT_CONF_FILE

## Open template dnsmasq.conf file and do replacements
sed -e "s/\${IFACE_OUT}/$IFACE_OUT/" \
	-e "s/\${IP_ADDR}/$IP_ADDR/" \
	-e "s/\${DHCP_RANGE_START}/$DHCP_RANGE_START/" \
	-e "s/\${DHCP_RANGE_END}/$DHCP_RANGE_END/" dnsmasq-template.conf > $DNSMASQ_CONF_FILE

# Setup iptables
iptables -t nat -A POSTROUTING -o $IFACE_IN -j MASQUERADE
iptables -A FORWARD -i $IFACE_IN -o $IFACE_OUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $IFACE_OUT -o $IFACE_IN -j ACCEPT
