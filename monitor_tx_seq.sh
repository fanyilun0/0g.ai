#!/bin/bash

# 企业微信机器人webhook地址
WEBHOOK_URL="your_webhook_url_here"

# 获取当前日期格式化字符串
DATE=$(date +"%Y-%m-%d")
LOG_FILE="$HOME/0g-storage-node/run/log/zgs.log.${DATE}"

# 调试信息
echo "Debug: Using log file: $LOG_FILE"

# 检查文件权限
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: No read permission for log file: $LOG_FILE"
    exit 1
fi

# 获取公网IP地址
IP_ADDR=$(curl -s ifconfig.me)
if [ -z "$IP_ADDR" ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
fi

if [ -z "$IP_ADDR" ]; then
    echo "Error: Failed to get IP address"
    exit 1
fi

# 检查日志文件是否存在
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

# 显示文件内容的最后几行用于调试
echo "Debug: Last few lines of log file:"
tail -n 5 "$LOG_FILE"

# 使用更灵活的grep模式来提取tx_seq
TX_SEQ=$(grep -o '[Tt][Xx]_[Ss][Ee][Qq][:=][[:space:]]*[0-9]\+' "$LOG_FILE" | tail -n 1 | grep -o '[0-9]\+')

# 调试信息
echo "Debug: Extracted tx_seq: $TX_SEQ"

if [ -z "$TX_SEQ" ]; then
    echo "Error: Failed to extract tx_seq number"
    # 显示grep的完整输出用于调试
    echo "Debug: Full grep output:"
    grep -o '[Tt][Xx]_[Ss][Ee][Qq][:=][[:space:]]*[0-9]\+' "$LOG_FILE"
    exit 1
fi

# 构建要发送的JSON数据
JSON_DATA="{\"msgtype\":\"text\",\"text\":{\"content\":\"Server IP: $IP_ADDR\nCurrent tx_seq: $TX_SEQ\"}}"

# 发送到企业微信机器人
curl -s -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to send message to WeChat Work bot"
    exit 1
fi

echo "Successfully sent IP and tx_seq to WeChat Work bot"
