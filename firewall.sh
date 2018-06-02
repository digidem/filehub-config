# Stops external network access to the device, increases security.

# Delete existing modification from file, if it exists
sed -i '/#START_MOD/,/#END_MOD/d' /etc/rc.local

cat <<'EOF' >> /etc/rc.local
#START_MOD
iface="apcli0"

# Drop all tcp traffic incomming on iface
/bin/iptables -A INPUT -p tcp -i ${iface} -j DROP
# Drop all udp traffic incomming on iface
/bin/iptables -A INPUT -p udp -i ${iface} -j DROP

# Fetch IPv6 address on iface
ipv6_addr=`ifconfig ${iface} | grep inet6 | awk {'print $3'}`

# No IPv6 filter is installed, so remove IPv6 address on iface
if [ "${ipv6_addr}" != "" ]; then
  /bin/ip -6 addr del "${ipv6_addr}" dev ${iface}
fi
#END_MOD
EOF
