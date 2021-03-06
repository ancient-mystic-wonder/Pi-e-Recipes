#!/bin/sh

## Original tutorial: https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/
## https://webcache.googleusercontent.com/search?q=cache:8nfWTN8xUhwJ:https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/+&cd=1&hl=en&ct=clnk&gl=ph

DEBUG=0

if [ $DEBUG -eq 1 ]
then
	DHCP_CONF="etc/dhcpcd.conf"
	NETWORK_INTERFACE_FILE="etc/network/interfaces"
	HOSTAPD_CONF_FILE="etc/hostapd/hostapd.conf"
	HOSTAPD_DEFAULT_CONF_FILE="etc/default/hostapd"
	DNSMASQ_CONF_FILE="etc/dnsmasq.conf"
else
	DHCP_CONF="/etc/dhcpcd.conf"
	NETWORK_INTERFACE_FILE="/etc/network/interfaces"
	HOSTAPD_CONF_FILE="/etc/hostapd/hostapd.conf"
	HOSTAPD_DEFAULT_CONF_FILE="/etc/default/hostapd"
	DNSMASQ_CONF_FILE="/etc/dnsmasq.conf"
fi

IP_ADDR="192.168.1.119"
NETMASK="255.255.255.0"
NETWORK="192.168.1.1"
BROADCAST="192.168.1.255"

IFACE_IN="wlan1"
IFACE_OUT="wlan0"
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

echo "Replacing $NETWORK_INTERFACE_FILE entries."

sed -i.bak -e "{N;s|$iface_manual|$iface_static|}" "$NETWORK_INTERFACE_FILE"

# Restart dhcpcd
if [ $DEBUG -ne 1 ]
then
	echo "Restarting dhcpcd"
	service dhcpcd restart
	echo "Setting up network interfaces"
	ifdown $IFACE_OUT
	ifup $IFACE_OUT
	ifdown $IFACE_IN
	ifup $IFACE_IN
fi

## Open template hostapd.conf file and do replacements
echo "Writing to $HOSTAPD_CONF_FILE"
sed -e "s/\${IFACE_OUT}/$IFACE_OUT/" \
	-e "s/\${PI_ROUTER_SSID}/$PI_ROUTER_SSID/" \
	-e "s/\${PI_ROUTER_PASSWORD}/$PI_ROUTER_PASSWORD/" hostapd-template.conf > $HOSTAPD_CONF_FILE

## Edit hostapd default configuration file for startup
echo "Editing $HOSTAPD_DEFAULT_CONF_FILE, setting conf to $HOSTAPD_CONF_FILE"
sed -i.bak 's|.*DAEMON_CONF=".*|DAEMON_CONF="$HOSTAPD_CONF_FILE"|' $HOSTAPD_DEFAULT_CONF_FILE

## Open template dnsmasq.conf file and do replacements
echo "Writing to $DNSMASQ_CONF_FILE"
sed -e "s/\${IFACE_OUT}/$IFACE_OUT/" \
	-e "s/\${IP_ADDR}/$IP_ADDR/" \
	-e "s/\${DHCP_RANGE_START}/$DHCP_RANGE_START/" \
	-e "s/\${DHCP_RANGE_END}/$DHCP_RANGE_END/" dnsmasq-template.conf > $DNSMASQ_CONF_FILE

# Enable ipv4 forwarding
if [ $DEBUG -ne 1 ]
then
	echo "Enabling ipv4 forwarding"
	sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
	sed -i "s/.*net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
fi

# Setup iptables
echo "Adding iptables entries"
iptables -t nat -A POSTROUTING -o $IFACE_IN -j MASQUERADE
iptables -A FORWARD -i $IFACE_IN -o $IFACE_OUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $IFACE_OUT -o $IFACE_IN -j ACCEPT

echo "Done! Now run run-hostapd.sh to start your router."
