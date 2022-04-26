#!/bin/bash

ip netns add netns1
ip link add veth0 type veth peer name veth1
ip link set veth1 netns netns1
ip addr add 192.168.0.1/24 dev veth0
ip link set dev veth0 up

iptables -t nat -A POSTROUTING -s 192.168.0.0/255.255.255.0 -o ens5 -j MASQUERADE
iptables -A FORWARD -i ens5 -o veth0 -j ACCEPT
iptables -A FORWARD -o ens5 -i veth0 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i ens5 --dport 6000 -j DNAT --to-destination 192.168.0.2:8080
iptables -A FORWARD -p tcp -d 192.168.0.2 --dport 8080 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

ip netns exec netns1 /bin/bash
# ip link set dev lo up
ip addr add 192.168.0.2/24 dev veth1
ip link set dev veth1 up
ip route add default via 192.168.0.1
# python3.9 server1.py
