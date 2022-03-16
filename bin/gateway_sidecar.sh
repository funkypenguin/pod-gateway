#!/bin/bash

set -ex

# Load main settings
cat /default_config/settings.sh
. /default_config/settings.sh
cat /config/settings.sh
. /config/settings.sh

if [[ -n "$VPN_INTERFACE" ]]; then
  # Create all NAT rules
  PORT=1024 # starting port
  for THIRD in {0..255}
  do
    for FOURTH in {0..255}
    do
    if [[ $PORT -gt 65535 ]]; then
    break
    fi
    iptables  -t nat -A PREROUTING -p tcp -i "$VPN_INTERFACE" \
              --dport $PORT  -j DNAT \
              --to-destination "${VXLAN_IP_NETWORK}.${THIRD}.${FOURTH}:${PORT}"
    # iptables  -t nat -A PREROUTING -p udp -i "$VPN_INTERFACE" \
    #           --dport $PORT  -j DNAT \
    #           --to-destination "${VXLAN_IP_NETWORK}.${THIRD}.${FOURTH}:${PORT}"            
    # iptables  -A FORWARD -p tcp -d "${VXLAN_IP_NETWORK}.${THIRD}.${FOURTH}" \
    #           --dport "$PORT" -m state --state NEW,ESTABLISHED,RELATED \
    #           -j ACCEPT
    # iptables  -A FORWARD -p udp -d "${VXLAN_IP_NETWORK}.${THIRD}.${FOURTH}" \
    #           --dport "$PORT" -m state --state NEW,ESTABLISHED,RELATED \
    #           -j ACCEPT            
    ((PORT=PORT+1))
    done
  done
  iptables  -A FORWARD -i "$VPN_INTERFACE" -p tcp -d "${VXLAN_IP_NETWORK}.0.0/16" \
            -m state --state NEW,ESTABLISHED,RELATED \
            -j ACCEPT  
fi

echo "job done, going to sleep now..."
sleep infinity

echo "TERMINATING"

