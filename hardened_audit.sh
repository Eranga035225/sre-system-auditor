
# --- Configuration ---
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load variables from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
fi

WEBHOOK_URL="${SLACK_WEBHOOK}"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ... (rest of the functions stay the same)
# -- Functions --

get_system_stats(){
	CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
	MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
	DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

	echo "\"cpu_usage_percent\": \"$CPU_USAGE\", \"mem_usage-percent\": \"$MEM_USAGE\", \"disk_usage_percent\": \"$DISK_USAGE\""

}
get_open_ports() {
    # Grabs listening ports and the process name
    PORTS=$(ss -tlnp | awk 'NR>1 {print $4 " (" $7 ")"}' | xargs | sed 's/ / , /g')
    echo "\"open_ports\": \"$PORTS\""
}

get_top_files() {
    # Finds top 5 largest files in /var/log (common culprit for disk issues)
    TOP_FILES=$(du -ah /var/log 2>/dev/null | sort -rh | head -n 5 | awk '{print $2 " (" $1 ")"}' | xargs | sed 's/ / , /g')
    echo "\"top_large_files\": \"$TOP_FILES\""
}

get_failed_logins() {
    # Checks for failed SSH attempts (Security Audit)
    # Note: Use /var/log/secure on RHEL/CentOS
    FAILED_COUNT=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l)
    echo "\"failed_login_attempts\": \"$FAILED_COUNT\""
}

# --- Main Execution ---

# Build JSON Payload
JSON_PAYLOAD=$(cat <<EOF
{
  "hostname": "$HOSTNAME",
  "timestamp": "$TIMESTAMP",
  $(get_system_stats),
  $(get_open_ports),
  $(get_top_files),
  $(get_failed_logins)
}
EOF
)

# Send to Webhook
curl -X POST -H 'Content-type: application/json' --data "$JSON_PAYLOAD" $WEBHOOK_URL

echo "Report sent for $HOSTNAME at $TIMESTAMP"
