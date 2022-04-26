#!/bin/bash

ip netns add netns2
ip link add veth2 type veth peer name veth3
ip link set veth3 netns netns2
ip addr add 192.168.1.1/24 dev veth2
ip link set dev veth2 up

iptables -t nat -A POSTROUTING -s 192.168.1.0/255.255.255.0 -o ens5 -j MASQUERADE
iptables -A FORWARD -i ens5 -o veth2 -j ACCEPT
iptables -A FORWARD -o ens5 -i veth2 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i ens5 --dport 6001 -j DNAT --to-destination 192.168.1.2:8080
iptables -A FORWARD -p tcp -d 192.168.1.2 --dport 8080 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

ip netns exec netns2 /bin/bash
# ip link set dev lo up
ip addr add 192.168.1.2/24 dev veth3
ip link set dev veth3 up
ip route add default via 192.168.1.1
# python3.9 server2.py
