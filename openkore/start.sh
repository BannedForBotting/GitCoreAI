#!/bin/bash

ip=$(curl -s https://api.ipify.org)
echo "IP : $ip"
export XIP=$ip
	
file=/root/openkore/locked

if [ ! -e "$file" ] 
then  

	touch "$file"
	
	RMMD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)


	sed -i 's/6901/'"$XLISTEN_PORT"'/g' control/config.txt
	sed -i 's/6902/'"$WLISTEN_PORT"'/g' control/config.txt
	sed -i 's/6904/'"$WSLISTEN_PORT"'/g' control/config.txt
	sed -i 's/43.254.132.28/'"$XIP"'/g' control/config.txt


fi

perl openkore.pl
