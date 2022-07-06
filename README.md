# hw_sensors_exporter
Lightweight, single file Prometheus exporter for OpenBSD hw.sensors data.

It's fully self contained and has no external dependencies other than whats included in the OpenBSD base installation.
It is written in ksh and uses netcat(nc) to serve the metrics. 

# Usage
Copy the hw_sensors_exporter.sh file somewhere in your PATH (ex. /usr/local/bin/) and run it: hw_sensors_exporter.sh &

It will start listening for connections on 127.0.0.1 port 9120 by default but you can change that near the end of this script.

# Notes
It is a bit hacky as I tried to do everything in ksh to minimize forking but I'm no ksh expert by a long shot.
