# hw_sensors_exporter
Lightweight, single file Prometheus exporter for OpenBSD hw.sensors data.

It's fully self contained and has no external dependencies other than whats included in the OpenBSD base installation.
It is written in sh and uses netcat(nc) to serve the metrics. 

## Usage
```
hw_sensors_exporter.sh [-l listening_ip_address] [-p port] [-h]
```

## Installation
```
Copy the hw_sensors_exporter.sh file somewhere in your PATH (ex. /usr/local/bin/) 
and run it: hw_sensors_exporter.sh &
 
It will start listening for connections on 127.0.0.1 port 9120 by default but you can change that:
hw_sensors_exporter.sh -l 192.168.0.1 -p 9120 &

```

## Notes
It is a bit hacky as I tried to do almost everything in sh to minimize forking.
