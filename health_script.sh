#!/bin/bash

LOGFILE="/home/user/server-health-monitor/logs/report.log"

# ==========================================
# Email Configuration
# ==========================================

ADMIN_EMAIL="robinjoserobert2@gmail.com"

CPU_LIMIT=80
RAM_LIMIT=80
DISK_LIMIT=80

# ==========================================
# Calculate Current Usage
# ==========================================

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100-$8)}')
RAM_USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2*100}')
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

# ==========================================
# Email Alert Function
# ==========================================

send_alert() {

BODY="

******** SERVER HEALTH ALERT ********

Hostname      : $(hostname)
IP Address    : $(hostname -I)

Date          : $(date)

CPU Usage     : ${CPU_USAGE}%
RAM Usage     : ${RAM_USAGE}%
Disk Usage    : ${DISK_USAGE}%

Thresholds

CPU  > ${CPU_LIMIT}%
RAM  > ${RAM_LIMIT}%
Disk > ${DISK_LIMIT}%

Please investigate the server immediately.

"

echo "$BODY" | mail -s "🚨 Server Health Alert - $(hostname)" "$ADMIN_EMAIL"

}

# ==========================================
# Start Logging
# ==========================================

echo "==========================================" >> "$LOGFILE"
echo "Server Health Report" >> "$LOGFILE"
echo "Date: $(date)" >> "$LOGFILE"
echo "Hostname: $(hostname)" >> "$LOGFILE"
echo "IP Address: $(hostname -I)" >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "CPU Usage" >> "$LOGFILE"
echo "Usage : ${CPU_USAGE}%" >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Memory Usage" >> "$LOGFILE"
free -h >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Disk Usage" >> "$LOGFILE"
df -h >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Top 5 Memory Consuming Processes" >> "$LOGFILE"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -6 >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Top 5 CPU Consuming Processes" >> "$LOGFILE"
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -6 >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Zombie Processes" >> "$LOGFILE"

ZOMBIES=$(ps aux | awk '$8=="Z"')

if [ -z "$ZOMBIES" ]
then
    echo "No Zombie Processes Found" >> "$LOGFILE"
else
    echo "$ZOMBIES" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"

##################################################

echo "Network Status" >> "$LOGFILE"
ip link show >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Running Services" >> "$LOGFILE"
systemctl list-units --type=service --state=running >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Load Average" >> "$LOGFILE"
uptime >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################

echo "Logged In Users" >> "$LOGFILE"
who >> "$LOGFILE"
echo "" >> "$LOGFILE"

##################################################
# Threshold Checking
##################################################

echo "Threshold Status" >> "$LOGFILE"

ALERT=false

if [ "$CPU_USAGE" -ge "$CPU_LIMIT" ]; then
    echo "⚠ CPU usage exceeded (${CPU_USAGE}%)" >> "$LOGFILE"
    ALERT=true
fi

if [ "$RAM_USAGE" -ge "$RAM_LIMIT" ]; then
    echo "⚠ RAM usage exceeded (${RAM_USAGE}%)" >> "$LOGFILE"
    ALERT=true
fi

if [ "$DISK_USAGE" -ge "$DISK_LIMIT" ]; then
    echo "⚠ Disk usage exceeded (${DISK_USAGE}%)" >> "$LOGFILE"
    ALERT=true
fi

if [ "$ALERT" = false ]; then
    echo "All system resources are within limits." >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"

##################################################
# Send Email Alert
##################################################

if [ "$ALERT" = true ]; then
    send_alert
    echo "Email Alert Sent to $ADMIN_EMAIL" >> "$LOGFILE"
else
    echo "No Email Alert Needed" >> "$LOGFILE"
fi

echo "" >> "$LOGFILE"

echo "==========================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"
