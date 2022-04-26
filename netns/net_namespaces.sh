# Giles' blog
# Fun with network namespaces, part 1
# https://www.gilesthomas.com/2021/03/fun-with-network-namespaces


cat /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward


iptables -L FORWARD
iptables -P FORWARD DROP
iptables -L FORWARD
iptables -t nat -L


# So, firstly, we'll enable masquerading from the 192.168.0.* network onto our main ethernet interface ens5:
iptables -t nat -A POSTROUTING -s 192.168.0.0/255.255.255.0 -o ens5 -j MASQUERADE

# Now we'll say that we'll forward stuff that comes in on ens5 can be forwarded to our veth0 interface, which you'll remember is the end of the virtual network pair that is outside the namespace:
iptables -A FORWARD -i ens5 -o veth0 -j ACCEPT

# ...and then the routing in the other direction:
iptables -A FORWARD -o ens5 -i veth0 -j ACCEPT

# We use the "Destination NAT" chain in iptables:
iptables -t nat -A PREROUTING -p tcp -i ens5 --dport 6000 -j DNAT --to-destination 192.168.0.2:8080

# Next, we say that we're happy to forward stuff back and forth over new, established and related (not sure what that last one is) connections to the IP of our namespaced interface:
iptables -A FORWARD -p tcp -d 192.168.0.2 --dport 8080 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT




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
# link set dev lo up  ##--??
ip addr add 192.168.0.2/24 dev veth1
ip link set dev veth1 up
ip route add default via 192.168.0.1
# python3.7 server1.py
