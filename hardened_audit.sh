# --Configuration -- 
WEBHOOK_URL=""
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S') 



# -- Functions --

get_system_stats(){
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
	MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
	DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

	echo "\"cpu_usage_percent\": \"$CPU_USAGE\", \"mem_usage-percent\": \"$MEM_USAGE\", \"disk_usage_percent\": \"$DISK_USAGE\""

}
