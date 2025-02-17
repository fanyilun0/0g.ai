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

# 检查存储节点同步状态
function check_storage_status() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            echo "Could not install jq. Please install it manually."
            exit 1
        fi
    fi

    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get node status"
        exit 1
    fi
    
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    echo "获取状态成功 - 区块: $logSyncHeight, 节点数: $connectedPeers"
}

# 获取节点状态
check_storage_status
NODE_STATUS="区块高度: $logSyncHeight\n节点连接数: $connectedPeers"

# 构建要发送的JSON数据
JSON_DATA="{\"msgtype\":\"text\",\"text\":{\"content\":\"服务器IP: $IP_ADDR\n当前tx_seq: $TX_SEQ\n$NODE_STATUS\"}}"

# 发送到企业微信机器人
curl -s -H "Content-Type: application/json" -X POST -d "$JSON_DATA" "$WEBHOOK_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to send message to WeChat Work bot"
    exit 1
fi

echo "Successfully sent IP and tx_seq to WeChat Work bot"
