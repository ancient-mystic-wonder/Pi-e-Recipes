#!/bin/sh
# Need this because I keep on forgetting the commands

iptables -F FORWARD
iptables -t nat -F POSTROUTING
