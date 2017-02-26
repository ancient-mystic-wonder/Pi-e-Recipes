#!/bin/sh

service dnsmasq start
service hostapd start

/usr/sbin/hostapd /etc/hostapd/hostapd.conf
