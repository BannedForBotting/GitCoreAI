#!/bin/bash

ip=$(curl -s https://api.ipify.org)
echo "IP : $ip"
export XIP=$ip
	
file=/root/openkore/locked

if [ ! -e "$file" ] 
then  

	touch "$file"
	
	RMMD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)

	sed -i 's/arrowcraft/'"arrowcraft$RMMD"'/g' up.pl
	sed -i 's/'"arrowcraft$RMMD.txt"'/'"arrowcraft.txt"'/g' up.pl
	sed -i 's/avoid/'"avoid$RMMD"'/g' up.pl
	sed -i 's/'"avoid$RMMD.txt"'/'"avoid.txt"'/g' up.pl
	sed -i 's/chat_resp/'"chat_resp$RMMD"'/g' up.pl
	sed -i 's/'"chat_resp$RMMD.txt"'/'"chat_resp.txt"'/g' up.pl
	sed -i 's/config/'"config$RMMD"'/g' up.pl
	sed -i 's/'"config$RMMD.txt"'/'"config.txt"'/g' up.pl
	sed -i 's/items_control/'"items_control$RMMD"'/g' up.pl
	sed -i 's/'"items_control$RMMD.txt"'/'"items_control.txt"'/g' up.pl
	sed -i 's/mon_control/'"mon_control$RMMD"'/g' up.pl
	sed -i 's/'"mon_control$RMMD.txt"'/'"mon_control.txt"'/g' up.pl
	sed -i 's/pickupitems/'"pickupitems$RMMD"'/g' up.pl
	sed -i 's/'"pickupitems$RMMD.txt"'/'"pickupitems.txt"'/g' up.pl
	sed -i 's/priority/'"priority$RMMD"'/g' up.pl
	sed -i 's/'"priority$RMMD.txt"'/'"priority.txt"'/g' up.pl
	sed -i 's/overallAuth/'"overallAuth$RMMD"'/g' up.pl
	sed -i 's/'"overallAuth$RMMD.txt"'/'"overallAuth.txt"'/g' up.pl
	sed -i 's/responses/'"responses$RMMD"'/g' up.pl
	sed -i 's/'"responses$RMMD.txt"'/'"responses.txt"'/g' up.pl
	sed -i 's/routeweights/'"routeweights$RMMD"'/g' up.pl
	sed -i 's/'"routeweights$RMMD.txt"'/'"routeweights.txt"'/g' up.pl
	sed -i 's/shop/'"shop$RMMD"'/g' up.pl
	sed -i 's/'"shop$RMMD.txt"'/'"shop.txt"'/g' up.pl
	sed -i 's/timeouts/'"timeouts$RMMD"'/g' up.pl
	sed -i 's/'"timeouts$RMMD.txt"'/'"timeouts.txt"'/g' up.pl

	sed -i 's/6901/'"$XLISTEN_PORT"'/g' control/config.txt
	sed -i 's/6902/'"$WLISTEN_PORT"'/g' control/config.txt
	sed -i 's/6904/'"$WSLISTEN_PORT"'/g' control/config.txt
	sed -i 's/43.254.132.28/'"$XIP"'/g' control/config.txt

	sed -i 's/127.0.0.1/'"$XIP"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/6903/'"$ULISTEN_PORT"'/g' plugins/webMonitorPlugin/WWW/config.html.template 

	sed -i 's/arrowcraft/'"arrowcraft$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"arrowcraft$RMMD.txt"'/'"arrowcraft.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/avoid/'"avoid$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"avoid$RMMD.txt"'/'"avoid.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/chat_resp/'"chat_resp$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"chat_resp$RMMD.txt"'/'"chat_resp.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/config/'"config$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"config$RMMD.txt"'/'"config.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/items_control/'"items_control$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"items_control$RMMD.txt"'/'"items_control.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/mon_control/'"mon_control$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"mon_control$RMMD.txt"'/'"mon_control.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/pickupitems/'"pickupitems$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"pickupitems$RMMD.txt"'/'"pickupitems.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/priority/'"priority$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"priority$RMMD.txt"'/'"priority.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/overallAuth/'"overallAuth$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"overallAuth$RMMD.txt"'/'"overallAuth.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/responses/'"responses$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"responses$RMMD.txt"'/'"responses.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/routeweights/'"routeweights$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"routeweights$RMMD.txt"'/'"routeweights.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/shop/'"shop$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"shop$RMMD.txt"'/'"shop.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/timeouts/'"timeouts$RMMD"'/g' plugins/webMonitorPlugin/WWW/config.html.template
	sed -i 's/'"timeouts$RMMD.txt"'/'"timeouts.txt"'/g' plugins/webMonitorPlugin/WWW/config.html.template
fi

perl up.pl daemon -m production -l http://*:$ULISTEN_PORT & perl openkore.pl
