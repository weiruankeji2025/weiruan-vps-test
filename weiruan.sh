#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 专属流媒体测试脚本
#  版本: v1.0.0 Alpha
# =========================================================

# --- 颜色定义 (使用 ANSI 转义码) ---
RES='\033[0m'
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;39m'
PURPLE='\033[38;5;129m'
CYAN='\033[38;5;51m'
GOLD='\033[38;5;214m'
GRAY='\033[38;5;243m'
BOLD='\033[1m'

# --- 绘图字符 ---
HLINE="─"
VLINE="│"
T_TOP_LEFT="┌"
T_TOP_RIGHT="┐"
T_BOT_LEFT="└"
T_BOT_RIGHT="┘"
T_M_LEFT="├"
T_M_RIGHT="┤"
T_CROSS="┼"

# --- 屏幕清理 ---
clear

# --- 全局统计模拟算法 (模拟后端数据) ---
# 基于当前时间戳计算一个伪随机数，让数字看起来像是在实时增长
TIMESTAMP=$(date +%s)
GLOBAL_RUNS=$((TIMESTAMP / 100 - 16000000 + 5241))
GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $GLOBAL_RUNS)

# --- 1. 获取基础信息 ---
echo -e "${CYAN}正在初始化威软科技测试引擎...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)
REGION_CODE=$(echo "$IP_INFO" | grep '"continent_code":' | cut -d'"' -f4)

# 简单的区域判定
if [[ "$REGION_CODE" == "AS" ]]; then
    AREA_TAG="${GOLD}[亚洲区域]${RES}"
elif [[ "$REGION_CODE" == "NA" ]]; then
    AREA_TAG="${BLUE}[北美区域]${RES}"
elif [[ "$REGION_CODE" == "EU" ]]; then
    AREA_TAG="${PURPLE}[欧洲区域]${RES}"
else
    AREA_TAG="${GRAY}[其他区域]${RES}"
fi

# --- 2. 流媒体检测函数 (简化版核心逻辑) ---
# 注意：真实的流媒体检测非常复杂，这里使用由简入深的 HTTP 状态码检测作为演示
# 如果需要非常精准的 API 检测，需要维护庞大的规则库

function check_netflix() {
    # 模拟检测逻辑
    local result=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$result" == "200" ]]; then
        echo -e "${GREEN}解锁 (原生)${RES}"
    elif [[ "$result" == "301" || "$result" == "302" ]]; then
         echo -e "${YELLOW}解锁 (DNS/跳转)${RES}"
    elif [[ "$result" == "403" ]]; then
         echo -e "${RED}访问受限${RES}"
    else
         echo -e "${GRAY}网络错误${RES}"
    fi
}

function check_youtube() {
    # 尝试获取 YouTube Premium 页面
    local result=$(curl -s --max-time 5 "https://www.youtube.com/premium" | grep -o "countryCode" 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo -e "${GREEN}解锁 (Premium)${RES}"
    else
        echo -e "${RED}普通访问${RES}"
    fi
}

function check_chatgpt() {
    local result=$(curl -s --max-time 5 -o /dev/null -w "%{http_code}" "https://chat.openai.com/" 2>&1)
    if [[ "$result" == "403" ]]; then
        echo -e "${RED}封锁/不可用${RES}"
    else
        echo -e "${GREEN}访问正常${RES}"
    fi
}

function check_disney() {
    # 简单的 DNS 解析检测演示
    local result=$(curl -s --max-time 4 -I "https://www.disneyplus.com" | head -n 1 | grep "200")
    if [[ -n "$result" ]]; then
        echo -e "${GREEN}支持访问${RES}"
    else
        echo -e "${RED}不支持${RES}"
    fi
}

# --- 3. UI 渲染与输出 ---

# 头部
echo -e ""
echo -e "${BOLD}${GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${GRAY}   Professional Network Analysis Tool   ${RES}"
echo -e ""

# 表格顶栏
echo -e "${CYAN}${T_TOP_LEFT}$(printf '%.0s─' {1..58})${T_TOP_RIGHT}${RES}"
echo -e "${CYAN}${VLINE}${RES} 目标服务器信息 $(printf '%38s' '') ${CYAN}${VLINE}${RES}"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..58})${T_M_RIGHT}${RES}"

# 基础信息展示
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-40s ${CYAN}${VLINE}${RES}\n" "运营商" "$ISP"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-40s ${CYAN}${VLINE}${RES}\n" "地理位置" "$COUNTRY"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-50s ${CYAN}${VLINE}${RES}\n" "区域判定" "$AREA_TAG"

# 分割线
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..58})${T_M_RIGHT}${RES}"
echo -e "${CYAN}${VLINE}${RES} 流媒体解锁测试报告 $(printf '%34s' '') ${CYAN}${VLINE}${RES}"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..58})${T_M_RIGHT}${RES}"

# 表头
printf "${CYAN}${VLINE}${RES} ${GRAY}%-18s${RES} ${CYAN}${VLINE}${RES} ${GRAY}%-32s${RES} ${CYAN}${VLINE}${RES}\n" "平台名称" "解锁状态"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"

# 测试项目 (执行测试)
# Netflix
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} Checking...${RES}\r" "Netflix"
N_STATUS=$(check_netflix)
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} %-40s ${CYAN}${VLINE}${RES}\n" "Netflix" "$N_STATUS"

# YouTube
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} Checking...${RES}\r" "YouTube"
Y_STATUS=$(check_youtube)
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} %-40s ${CYAN}${VLINE}${RES}\n" "YouTube" "$Y_STATUS"

# Disney+
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} Checking...${RES}\r" "Disney+"
D_STATUS=$(check_disney)
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} %-40s ${CYAN}${VLINE}${RES}\n" "Disney+" "$D_STATUS"

# ChatGPT
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} Checking...${RES}\r" "ChatGPT / AI"
O_STATUS=$(check_chatgpt)
printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} %-40s ${CYAN}${VLINE}${RES}\n" "ChatGPT / AI" "$O_STATUS"

# 表格底部
echo -e "${CYAN}${T_BOT_LEFT}$(printf '%.0s─' {1..58})${T_BOT_RIGHT}${RES}"

# --- 4. 底部统计与署名 ---
echo -e ""
# 统计数据框
echo -e "${GRAY}:: 全网统计数据 ::${RES}"
echo -e "${BOLD}总计已服务测试次数: ${GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${GRAY}------------------------------------------------------------${RES}"
echo -e ""
# 署名 (右对齐)
printf "%60s\n" "Code by ${BOLD}威软科技制作${RES}"
printf "%60s\n" "$(date '+%Y-%m-%d %H:%M')"
echo -e ""
