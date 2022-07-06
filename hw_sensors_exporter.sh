#!/bin/ksh
# hw_sensors_exporter V1.0
# Dinos Costanti 2022 (dinos at lab02.org)
#
# Lightweight, single file Prometheus exporter for OpenBSD hw.sensors data. 
# It is written in ksh and uses netcat(nc) to serve the metrics. It has no external dependencies other than whats included in an OpenBSD base installation.
#
# Usage:
# Copy the hw_sensors_exporter.sh file somewhere in your PATH (ex. /usr/local/bin/) and run it: hw_sensors_exporter.sh &
# It will be listening for connections on 127.0.0.1 port 9120 by default but you can change that near the end of this script.

set -e

function sensors_to_metrics {
	#cat example_data.txt | while read -r sensor; do
	sysctl hw.sensors | while read -r sensor; do
		#printf "\n%s\n" "$sensor"
		
		#Extract text enclosed in () as Description.
		description="${sensor#*'('}"
		if [ ! "$description" = "$sensor" ]; then
			description="${description%')'*}"
			sensor="${sensor%' ('*}${sensor#*')'}"
		else
			description=''
		fi
		#Get status after the ','
		status="${sensor#*', '}"
		if [ "$status" = "$sensor" ]; then
			status=''
		fi
		#Clear everything after ',' and replace '=' with ' '
		sensor="${sensor%%','*}"
		sensor="${sensor%'='*} ${sensor#*'='}"
		#printf "Sensor:%s \nDescription:%s\nStatus:%s\n" "$sensor" "$description" "$status"
		
		#Load in array (split on spaces). 
		#sensor_data[0] is the mib, sensor_data[1] is the value and sensor_data[2] is the unit if any.
		set -A sensor_data $sensor
		
		#Sensor name and id
		sensor_id="${sensor_data[0]##*'.'}"
		sensor_name="${sensor_id%'.'*}"
		sensor_id="${sensor_name#${sensor_name%%*([0-9])}}"
		sensor_name="${sensor_name%%*([0-9])}"
		#printf "sensor_name:%s Sensor_id:%s\n" "$sensor_name" "$sensor_id"
		
		#Conroller name and id
		controller_id="${sensor_data[0]%'.'*}"
		controller_id="${controller_id##*'.'}"
		controller_name="${controller_id%'.'*}"
		controller_id="${controller_name#${controller_name%%*([0-9])}}"
		controller_name="${controller_name%%*([0-9])}"
		#printf "controller_name:%s Controller_id:%s\n\n" "$controller_name" "$controller_id"
		
		#construct metric. ex: hw_sensors_cpu_temp{unit="degC",controller_id="0",sensor_id="0"} 44.00
		mib="hw_sensors_${controller_name}_${sensor_name}"
		unit="${sensor_data[2]}"
		
		if [ ! -z "${description}" ]; then
			printf "# HELP %s %s\n" "$mib" "$description"
		fi
		printf "# TYPE %s gauge\n" "$mib"
		
		if [ -z "${unit}" ]; then
			printf "%s{controller_id=\"%s\",sensor_id=\"%s\"} %s\n" "$mib" "$controller_id" "$sensor_id" "${sensor_data[1]}"
		else
			printf "%s{unit=\"%s\",controller_id=\"%s\",sensor_id=\"%s\"} %s\n" "$mib" "$unit" "$controller_id" "$sensor_id" "${sensor_data[1]}"
		fi
		
	done
}

if  [ ! -p "/tmp/hw_sensors_exporter" ] ; then
	mkfifo /tmp/hw_sensors_exporter
fi

#Serve the metrics
while true ; do {  
	read line < /tmp/hw_sensors_exporter
	printf "HTTP/1.1 200 OK\r\n\n"
	sensors_to_metrics
}  | nc -lN 127.0.0.1 9120 > /tmp/hw_sensors_exporter  
done


