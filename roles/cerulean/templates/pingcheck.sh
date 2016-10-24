#!/bin/bash
if [ $# -le 0 ] 
then 
  echo "Arguments too few..."
  exit
fi 
IP=$1
RES=1;

while [ $RES -ge 1 ];
do
  sleep 5
  ping -c 4 $IP | grep ' 0% packet loss'
  RES=$?
  echo "Got $RES"
done