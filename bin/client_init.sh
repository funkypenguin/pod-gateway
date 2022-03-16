#!/bin/bash

set -ex

# Load main settings
cat /default_config/settings.sh
. /default_config/settings.sh
cat /config/settings.sh
. /config/settings.sh

# in re-entry we need to remove the vxlan
# on first entry set a routing rule to the k8s DNS server
if ip addr | grep -q vxlan0; then
  ip link del vxlan0
else
  K8S_GW_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
  for local_cidr in $NOT_ROUTED_TO_GATEWAY_CIDRS; do
    # command might fail if rule already set
    ip route add "$local_cidr" via "$K8S_GW_IP" || /bin/true
  done
fi

# Delete default GW to prevent outgoing traffic to leave this docker
echo "Deleting existing default GWs"
ip route del 0/0 || /bin/true

# After this point nothing should be reachable -> check
if ping -c 1 -W 1000 8.8.8.8; then
  echo "WE SHOULD NOT BE ABLE TO PING -> EXIT"
  exit 255
fi

# For debugging reasons print some info
ip addr
ip route

# Derived settings
K8S_DNS_IP="$(cut -d ' ' -f 1 <<< "$K8S_DNS_IPS")"
GATEWAY_IP="$(dig +short "$GATEWAY_NAME" "@${K8S_DNS_IP}")"
# NAT_ENTRY="$(grep "$(hostname)" /config/nat.conf || true)"
VXLAN_GATEWAY_IP="${VXLAN_IP_NETWORK}.1"

# For debugging reasons print some info
ip addr
ip route

# Check we can connect to the GATEWAY IP
ping -c1 "$GATEWAY_IP"

# Create tunnel NIC
ip link add vxlan0 type vxlan id "$VXLAN_ID" dev eth0 dstport 0 || true
bridge fdb append to 00:00:00:00:00:00 dst "$GATEWAY_IP" dev vxlan0
ip link set up dev vxlan0

POD_IP_SUFFIX=$(hostname -i | awk -F. '{ print $3"."$4 }')
VXLAN_IP="${VXLAN_IP_NETWORK}.${POD_IP_SUFFIX}"
echo "Use fixed IP $VXLAN_IP"
ip addr add "${VXLAN_IP}/16" dev vxlan0
route add default gw "$VXLAN_GATEWAY_IP"

# For debugging reasons print some info
ip addr
ip route

# Check we can connect to the gateway ussing the vxlan device
ping -c1 "$VXLAN_GATEWAY_IP"

echo "Gateway ready and reachable"
