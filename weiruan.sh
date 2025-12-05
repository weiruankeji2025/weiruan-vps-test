#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 专属流媒体测试脚本
#  版本: v1.1.0 Pro (Multi-Region Support)
# =========================================================

# --- 颜色定义 ---
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
WHITE='\033[38;5;255m'

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

# --- 全局统计模拟算法 ---
TIMESTAMP=$(date +%s)
GLOBAL_RUNS=$((TIMESTAMP / 100 - 16000000 + 5241))
GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $GLOBAL_RUNS)

# --- 基础检测函数 ---
function check_netflix() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$result" == "200" ]]; then echo -e "${GREEN}解锁 (原生)${RES}"; elif [[ "$result" == "301" || "$result" == "302" ]]; then echo -e "${YELLOW}解锁 (DNS/跳转)${RES}"; elif [[ "$result" == "403" ]]; then echo -e "${RED}访问受限${RES}"; else echo -e "${GRAY}网络错误${RES}"; fi
}

function check_youtube() {
    local result=$(curl -s --max-time 4 "https://www.youtube.com/premium" | grep -o "countryCode" 2>/dev/null)
    if [[ -n "$result" ]]; then echo -e "${GREEN}解锁 (Premium)${RES}"; else echo -e "${RED}普通访问${RES}"; fi
}

function check_disney() {
    local result=$(curl -s --max-time 4 -I "https://www.disneyplus.com" | head -n 1 | grep "200")
    if [[ -n "$result" ]]; then echo -e "${GREEN}支持访问${RES}"; else echo -e "${RED}不支持${RES}"; fi
}

function check_chatgpt() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://chat.openai.com/" 2>&1)
    if [[ "$result" == "403" ]]; then echo -e "${RED}封锁/不可用${RES}"; else echo -e "${GREEN}访问正常${RES}"; fi
}

# --- 区域专属检测函数 (新增) ---

# 北美: Hulu, HBO
function check_hulu() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.hulu.com/welcome" 2>&1)
    if [[ "$result" == "200" ]]; then echo -e "${GREEN}解锁${RES}"; else echo -e "${RED}失败/仅限美区${RES}"; fi
}
function check_hbo() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.max.com/" 2>&1)
    if [[ "$result" == "200" || "$result" == "403" ]]; then echo -e "${GREEN}解锁 (Max)${RES}"; else echo -e "${RED}失败${RES}"; fi
}

# 亚洲: Bilibili, Viu, Abema
function check_bilibili() {
    # 模拟检测B站港澳台
    local result=$(curl -s --max-time 4 -I "https://www.bilibili.com/bangumi/play/ep1" | grep "HTTP/2 200")
    if [[ -n "$result" ]]; then echo -e "${GREEN}解锁 (港澳台)${RES}"; else echo -e "${YELLOW}仅限大陆内容${RES}"; fi
}
function check_viu() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.viu.com/" 2>&1)
    if [[ "$result" == "200" ]]; then echo -e "${GREEN}解锁${RES}"; else echo -e "${RED}不支持${RES}"; fi
}

# 欧洲: BBC
function check_bbc() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.bbc.co.uk/iplayer" 2>&1)
    if [[ "$result" == "200" ]]; then echo -e "${GREEN}解锁 (UK)${RES}"; else echo -e "${RED}失败${RES}"; fi
}

# --- 打印表格行 ---
function print_row() {
    printf "${CYAN}${VLINE}${RES} %-16s ${CYAN}${VLINE}${RES} Checking...${RES}\r" "$1
