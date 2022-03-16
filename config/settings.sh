#!/bin/bash

# hostname of the gateway - it must accept vxlan and DHCP traffic
# clients get it as env variable
GATEWAY_NAME="$gateway"
# K8S DNS IP address
# clients get it as env variable
K8S_DNS_IPS="$K8S_DNS_ips"
# Blank  sepated IPs not sent to the POD gateway but to the default K8S
# This is needed, for example, in case your CNI does
# not add a non-default rule for the K8S addresses (Flannel does)
NOT_ROUTED_TO_GATEWAY_CIDRS=""

# Vxlan ID to use
VXLAN_ID="42"
# VXLAN need an /24 IP range not conflicting with K8S and local IP ranges
VXLAN_IP_NETWORK="172.16"

# If using a VPN, interface name created by it
VPN_INTERFACE=tun0
# Prevent non VPN traffic to leave the gateway
VPN_BLOCK_OTHER_TRAFFIC=true
# If VPN_BLOCK_OTHER_TRAFFIC is true, allow VPN traffic over this port
VPN_TRAFFIC_PORT=443
# Traffic to these IPs will be send through the K8S gateway
VPN_LOCAL_CIDRS="10.0.0.0/8 192.168.0.0/16"
