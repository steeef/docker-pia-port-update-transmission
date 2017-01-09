#!/bin/bash

pia_username=${VPNUSER}
pia_passwd=${VPNPASS}
transmission_hostname=${TRANSMISSION_HOST}
transmission_port=${TRANSMISSION_PORT}
local_vpn_ip=$(ip -o -4 addr show | grep tun0 | awk '{print $4}')
pia_client_id_file=/data/pia_client_id
port_assignment_url=https://www.privateinternetaccess.com/vpninfo/port_forward_assignment

#
# First get a port from PIA
#

new_client_id() {
    head -n 100 /dev/urandom | md5sum | tr -d " -" | tee $pia_client_id_file
}

while [ 1 ]; do
  pia_client_id="$(cat $pia_client_id_file 2>/dev/null)"
  if [ -z ${pia_client_id} ]; then
      echo "Generating new client id for PIA"
      pia_client_id=$(new_client_id)
  fi

  # Get the port
  pia_response=$(curl -s -f -d "user=$pia_username&pass=$pia_passwd&client_id=$pia_client_id&local_ip=$local_vpn_ip" $port_assignment_url)

  # Check for curl error (curl will fail on HTTP errors with -f flag)
  ret=$?
  if [ $ret -ne 0 ]; then
      echo "curl encountered an error looking up new port: $ret"
  fi

  # Check for errors in PIA response
  error=$(echo $pia_response | grep -oE "\"error\".*\"")
  if [ ! -z "$error" ]; then
      echo "PIA returned an error: $error"
      exit
  fi

  # Get new port, check if empty
  new_port=$(echo $pia_response | grep -oE "[0-9]+")
  if [ -z "$new_port" ]; then
      echo "Could not find new port from PIA"
      exit
  fi
  echo "Got new port $new_port from PIA"

  #
  # Now, set port in Transmission
  #

  # get current listening port
  transmission_peer_port=$(transmission-remote ${transmission_hostname}:${transmission_port} -si | grep Listenport | grep -oE '[0-9]+')
  if [ "$new_port" != "$transmission_peer_port" ]
    then
      transmission-remote ${transmission_hostname}:${transmission_port} -p "$new_port"
      echo "Checking port..."
      sleep 10 && transmission-remote ${transmission_hostname}:${transmission_port} -pt
    else
      echo "No action needed, port hasn't changed"
  fi

  sleep 1h
done
