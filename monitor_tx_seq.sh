#!/bin/bash

# 企业微信机器人webhook地址
WEBHOOK_URL="your_webhook_url_here"

# 获取当前日期格式化字符串
DATE=$(date +"%Y-%m-%d")
LOG_FILE="$HOME/0g-storage-node/run/log/zgs.log.${DATE}"

# 获取公网IP地址
IP_ADDR=$(curl -s ifconfig.me)
if [ -z "$IP_ADDR" ]; then
    # 备选方案:使用hostname -I获取第一个IP
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

# 提取最后一个tx_seq号码
TX_SEQ=$(grep -o 'tx_seq:[0-9]\+' "$LOG_FILE" | tail -n 1 | cut -d':' -f2)

if [ -z "$TX_SEQ" ]; then
    echo "Error: Failed to extract tx_seq number"
    exit 1
fi

# 构建要发送的JSON数据,包含IP地址和tx_seq
JSON_DATA="{\"msgtype\":\"text\",\"text\":{\"content\":\"Server IP: $IP_ADDR\nCurrent tx_seq: $TX_SEQ\"}}"

# 发送到企业微信机器人
curl -s -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to send message to WeChat Work bot"
    exit 1
fi

echo "Successfully sent IP and tx_seq to WeChat Work bot"
