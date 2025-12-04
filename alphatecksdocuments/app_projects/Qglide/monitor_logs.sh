#!/bin/bash

# QGlide Wireless Log Monitor Script
# Usage: ./monitor_logs.sh [filter]
# Examples:
#   ./monitor_logs.sh              # Monitor all QGlide logs
#   ./monitor_logs.sh zego         # Monitor Zego-related logs
#   ./monitor_logs.sh error        # Monitor errors only

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default filter
FILTER="${1:-qglide}"

echo -e "${GREEN}=== QGlide Log Monitor ===${NC}"
echo -e "${BLUE}Filter: $FILTER${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}No device connected!${NC}"
    echo "Connecting wirelessly..."
    
    # Try to connect (you may need to set your IP)
    read -p "Enter device IP address (or press Enter to skip): " DEVICE_IP
    if [ ! -z "$DEVICE_IP" ]; then
        adb connect $DEVICE_IP:5555
        sleep 2
    fi
    
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}Failed to connect. Please connect device first.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Device connected!${NC}"
echo ""

# Clear previous logs
adb logcat -c

# Monitor logs with filter
case "$FILTER" in
    "zego")
        echo -e "${BLUE}Monitoring Zego/Call Service logs...${NC}"
        adb logcat | grep -iE "(zego|callservice|📞|token|room)"
        ;;
    "error")
        echo -e "${RED}Monitoring errors only...${NC}"
        adb logcat | grep -iE "(qglide|zego|callservice)" | grep -iE "(error|exception|failed)"
        ;;
    "login")
        echo -e "${BLUE}Monitoring login/auth logs...${NC}"
        adb logcat | grep -iE "(login|auth|token|zego|callservice)"
        ;;
    "api")
        echo -e "${BLUE}Monitoring API logs...${NC}"
        adb logcat | grep -iE "(api|response|token|data|keys)"
        ;;
    "all")
        echo -e "${BLUE}Monitoring all logs...${NC}"
        adb logcat
        ;;
    *)
        echo -e "${BLUE}Monitoring QGlide logs (filter: $FILTER)...${NC}"
        adb logcat | grep -iE "$FILTER"
        ;;
esac


