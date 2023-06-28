#!/bin/sh
version='1.0'
# Copyright (c) 2022 Dinos Costanti <dinos@lab02.org>
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.



set -e

listen='127.0.0.1'
port='9120'
help="hw_sensors_exporter.sh [-l listening_ip_address] [-p port] [-h]"

function sensors_to_metrics {
	#cat example_data.txt | while read -r sensor; do
	/sbin/sysctl hw.sensors | while read -r sensor; do
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
		
		#Load in array (split on spaces). 
		#sensor_data[0] is the mib, sensor_data[1] is the value and sensor_data[2] is the unit if any.
		set -A sensor_data $sensor
		
		#Sensor name and id
		sensor_id="${sensor_data[0]##*'.'}"
		sensor_name="${sensor_id%'.'*}"
		sensor_id="${sensor_name#${sensor_name%%*([0-9])}}"
		sensor_name="${sensor_name%%*([0-9])}"
		
		#Conroller name and id
		controller_id="${sensor_data[0]%'.'*}"
		controller_id="${controller_id##*'.'}"
		controller_name="${controller_id%'.'*}"
		controller_id="${controller_name#${controller_name%%*([0-9])}}"
		controller_name="${controller_name%%*([0-9])}"
		
		#construct metric. ex: hw_sensors_cpu_temp{unit="degC",controller_id="0",sensor_id="0"} 44.00
		mib="hw_sensors_${controller_name}_${sensor_name}"
		unit="${sensor_data[2]}"
		
		if [ ! -z "${description}" ]; then
			print "# HELP ${mib} ${description}"
		fi
		print "# TYPE ${mib} gauge"
		
		if [ -z "${unit}" ]; then
			print "${mib}{controller_id=\"${controller_id}\",sensor_id=\"${sensor_id}\"} ${sensor_data[1]}"
		else
			print "${mib}{unit=\"${unit}\",controller_id=\"${controller_id}\",sensor_id=\"${sensor_id}\"} ${sensor_data[1]}"
		fi
		
	done
}

while getopts 'hl:p:' name; do
	case $name in
	l)	
		listen=$OPTARG ;;
	p)	
		port=$OPTARG ;;
	h)	
		print "${help}"
		exit ;;
	?)	
		print "${help}"
		exit 2 ;;
	esac
done
shift $(($OPTIND - 1))


if  [ ! -p "/tmp/hw_sensors_exporter" ] ; then
	mkfifo /tmp/hw_sensors_exporter
fi

#Serve the metrics
while true ; do {  
	read line < /tmp/hw_sensors_exporter
	print "HTTP/1.1 200 OK\n"
	sensors_to_metrics
}  | nc -lN $listen $port > /tmp/hw_sensors_exporter  
done


