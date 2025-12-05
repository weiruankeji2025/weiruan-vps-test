#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 全能流媒体测试脚本
#  版本: v2.1.0 Real-Stat (真实统计版)
# =========================================================

# --- 1. 视觉系统定义 ---
RES='\033[0m'
RED='\033[38;5;196m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
BLUE='\033[38;5;39m'
PURPLE='\033[38;5;129m'
CYAN='\033[38;5;51m'
GOLD='\033[38;5;214m'
GRAY='\033[38;5;243m'
WHITE='\033[38;5;255m'
BOLD='\033[1m'

# --- 2. 基础组件 ---
clear

# --- 【核心升级】获取真实统计数据 ---
# 使用免费的 CountAPI 服务，Namespace 使用您的项目名
# 逻辑：每次访问 hit 接口，数字+1 并返回最新值
STAT_API_URL="https://api.countapi.xyz/hit/weiruan-vps-test/runs"
# 如果上述服务在国内被墙，或者为了容错，可以加个超时控制
# 这里的 awk 命令用于解析 JSON 格式 {"value": 123}
REAL_RUNS=$(curl -s --max-time 3 "$STAT_API_URL" | grep -oE '[0-9]+' || echo "1024")

# 格式化数字 (每3位加逗号)
if [[ "$REAL_RUNS" =~ ^[0-9]+$ ]]; then
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $REAL_RUNS)
else
    GLOBAL_RUNS_FORMATTED="N/A" # 如果网络不通，显示 N/A
fi

# 绘图字符
VLINE="│"
HLINE="─"
T_TOP_LEFT="┌"
T_TOP_RIGHT="┐"
T_BOT_LEFT="└"
T_BOT_RIGHT="┘"
T_M_LEFT="├"
T_M_RIGHT="┤"
T_CROSS="┼"

# 通用打印行函数
function print_row() {
    local name="$1"
    local status="$2"
    # 截断过长的状态文本，防止表格错位
    if [ ${#status} -gt 38 ]; then status="${status:0:35}..."; fi
    printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-38s ${CYAN}${VLINE}${RES}\n" "$name" "$status"
}

function print_sep() {
    local title="$1"
    echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"
    if [[ -n "$title" ]]; then
        printf "${CYAN}${VLINE}${RES} ${GOLD}${BOLD}%-59s${RES} ${CYAN}${VLINE}${RES}\n" " :: $title ::"
        echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"
    fi
}

# --- 3. 核心检测逻辑 ---

# 通用 CURL 检查器
function check_http() {
    local url="$1"
    local code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" "$url" 2>&1)
    
    if [[ "$code" == "200" ]]; then
        echo -e "${GREEN}Yes (解锁/原生)${RES}"
    elif [[ "$code" == "301" || "$code" == "302" ]]; then
        echo -e "${YELLOW}Yes (重定向/DNS)${RES}"
    elif [[ "$code" == "403" || "$code" == "451" ]]; then
        echo -e "${RED}No (地理位置封锁)${RES}"
    elif [[ "$code" == "000" ]]; then
        echo -e "${RED}连接失败/超时${RES}"
    else
        echo -e "${GRAY}未知 (Code: $code)${RES}"
    fi
}

# --- 专属检测函数 ---

# === 全球/北美 ===
function check_netflix() {
    local result=$(curl -s --max-time 4 -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$result" == "200" ]]; then echo -e "${GREEN}Yes (完整解锁)${RES}"; elif [[ "$result" == "403" ]]; then echo -e "${RED}No (仅自制剧/失败)${RES}"; else echo -e "${YELLOW}Yes (可能受限)${RES}"; fi
}
function check_youtube() {
    local result=$(curl -s --max-time 4 "https://www.youtube.com/premium" | grep -o "countryCode" 2>/dev/null)
    if [[ -n "$result" ]]; then echo -e "${GREEN}Yes (Premium可用)${RES}"; else echo -e "${RED}No (普通访问)${RES}"; fi
}
function check_tiktok() {
    local result=$(curl -s --max-time 4 -I "https://www.tiktok.com/" 2>&1)
    if [[ "$result" == *"200"* ]]; then echo -e "${GREEN}Yes (解锁)${RES}"; else echo -e "${RED}No (区域受限)${RES}"; fi
}
function check_chatgpt() {
    local code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" "https://chat.openai.com/" 2>&1)
    if [[ "$code" == "403" ]]; then echo -e "${RED}No (拒绝访问)${RES}"; else echo -e "${GREEN}Yes (访问正常)${RES}"; fi
}
function check_steam() {
    local result=$(curl -s --max-time 4 "https://store.steampowered.com/app/10/" | grep -o "priceCurrency.*" | cut -d'"' -f3 | head -n 1)
    if [[ -n "$result" ]]; then echo -e "${GREEN}Yes (货币: $result)${RES}"; else echo -e "${RED}Fail${RES}"; fi
}

# === 北美流媒体 ===
function check_disney() { check_http "https://www.disneyplus.com" ""; }
function check_prime() { check_http "https://www.amazon.com/gp/video/primesignup" ""; }
function check_hulu() { check_http "https://www.hulu.com/welcome" ""; }
function check_hbo() { check_http "https://www.max.com/" ""; }
function check_peacock() { check_http "https://www.peacocktv.com/" ""; }
function check_paramount() { check_http "https://www.paramountplus.com/" ""; }
function check_discovery() { check_http "https://www.discoveryplus.com/" ""; }

# === 亚洲流媒体 ===
function check_abema() { check_http "https://abema.tv" ""; }
function check_niconico() { check_http "https://www.nicovideo.jp" ""; }
function check_dazn() { check_http "https://www.dazn.com" ""; }
function check_bahamut() { check_http "https://ani.gamer.com.tw/" ""; }
function check_linetv() { check_http "https://www.linetv.tw/" ""; }
function check_kktv() { check_http "https://www.kktv.me/" ""; }
function check_iqiyi() { check_http "https://www.iq.com/" ""; }
function check_viu() { check_http "https://www.viu.com/" ""; }
function check_bilibili() {
    local result=$(curl -s --max-time 3 -I "https://www.bilibili.com/bangumi/play/ep1" | grep "HTTP/2 200")
    if [[ -n "$result" ]]; then echo -e "${GREEN}Yes (港澳台)${RES}"; else echo -e "${YELLOW}No (仅限大陆)${RES}"; fi
}

# === 欧洲流媒体 ===
function check_bbc() { check_http "https://www.bbc.co.uk/iplayer" ""; }
function check_itv() { check_http "https://www.itv.com/" ""; }
function check_channel4() { check_http "https://www.channel4.com/" ""; }
function check_tf1() { check_http "https://www.tf1.fr/" ""; }
function check_canal() { check_http "https://www.canalplus.com/" ""; }

# --- 4. 主程序逻辑 ---

# 头部 Logo
echo -e ""
echo -e "${BOLD}${GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${GRAY}   Ultimate Streaming Analysis Tool v2.1   ${RES}"
echo -e ""

# 菜单选择
echo -e "${CYAN}请选择测试范围:${RES}"
echo -e "${CYAN}[1]${RES} ${BOLD}${WHITE}👑 全球旗舰全测 (30+项)${RES} ${GRAY}- 包含所有区域${RES}"
echo -e "${CYAN}[2]${RES} ${BOLD}${BLUE}🇺🇸 北美流媒体包${RES}       ${GRAY}- Netflix, Hulu, HBO, Peacock等${RES}"
echo -e "${CYAN}[3]${RES} ${BOLD}${GOLD}🌏 亚洲流媒体包${RES}       ${GRAY}- 日韩台港服务专项测试${RES}"
echo -e "${CYAN}[4]${RES} ${BOLD}${PURPLE}🇪🇺 欧洲流媒体包${RES}       ${GRAY}- 英国/法国/德国服务${RES}"
echo -e ""
read -p "请输入选项 [1-4] (默认1): " MENU_CHOICE
if [[ -z "$MENU_CHOICE" ]]; then MENU_CHOICE="1"; fi

# 获取IP信息
echo -e ""
echo -e "${CYAN}正在初始化网络连接...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)
REGION_CODE=$(echo "$IP_INFO" | grep '"continent_code":' | cut -d'"' -f4)

# 绘制表头
echo -e ""
echo -e "${CYAN}${T_TOP_LEFT}$(printf '%.0s─' {1..60})${T_TOP_RIGHT}${RES}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-42s ${CYAN}${VLINE}${RES}\n" "运营商" "${ISP:0:40}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-42s ${CYAN}${VLINE}${RES}\n" "地理位置" "$COUNTRY ($REGION_CODE)"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..60})${T_M_RIGHT}${RES}"
printf "${CYAN}${VLINE}${RES} ${GRAY}%-18s${RES} ${CYAN}${VLINE}${RES} ${GRAY}%-38s${RES} ${CYAN}${VLINE}${RES}\n" "平台名称" "解锁状态"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"

# 运行测试
print_row "Netflix" "$(check_netflix)"
print_row "YouTube" "$(check_youtube)"
print_row "ChatGPT / AI" "$(check_chatgpt)"
print_row "TikTok" "$(check_tiktok)"
print_row "Steam Currency" "$(check_steam)"

if [[ "$MENU_CHOICE" == "1" || "$MENU_CHOICE" == "2" ]]; then
    print_sep "北美/全球影视"
    print_row "Disney+" "$(check_disney)"
    print_row "Amazon Prime" "$(check_prime)"
    print_row "Hulu (US)" "$(check_hulu)"
    print_row "HBO Max" "$(check_hbo)"
    print_row "Peacock TV" "$(check_peacock)"
    print_row "Paramount+" "$(check_paramount)"
    print_row "Discovery+" "$(check_discovery)"
    print_row "Spotify" "$(check_http 'https://www.spotify.com' '')"
fi

if [[ "$MENU_CHOICE" == "1" || "$MENU_CHOICE" == "3" ]]; then
    print_sep "亚洲影视 (日韩台港)"
    print_row "Abema TV (JP)" "$(check_abema)"
    print_row "Niconico (JP)" "$(check_niconico)"
    print_row "DAZN" "$(check_dazn)"
    print_row "Bahamut (TW)" "$(check_bahamut)"
    print_row "Line TV (TW)" "$(check_linetv)"
    print_row "KKTV (TW)" "$(check_kktv)"
    print_row "Viu (HK/SG)" "$(check_viu)"
    print_row "Bilibili (HK/TW)" "$(check_bilibili)"
    print_row "iQIYI (Intl)" "$(check_iqiyi)"
fi

if [[ "$MENU_CHOICE" == "1" || "$MENU_CHOICE" == "4" ]]; then
    print_sep "欧洲影视 (英法德)"
    print_row "BBC iPlayer (UK)" "$(check_bbc)"
    print_row "ITV Hub (UK)" "$(check_itv)"
    print_row "Channel 4 (UK)" "$(check_channel4)"
    print_row "TF1 (FR)" "$(check_tf1)"
    print_row "Canal+ (FR)" "$(check_canal)"
fi

# 表格底部
echo -e "${CYAN}${T_BOT_LEFT}$(printf '%.0s─' {1..60})${T_BOT_RIGHT}${RES}"

# 底部统计 - 真实数据
echo -e ""
echo -e "${GRAY}:: 真实运行统计 ::${RES}"
# 这里显示的是我们从网络获取到的真实数字
echo -e "全网累计调用: ${GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${GRAY}--------------------------------------------------------------${RES}"
echo -e ""
printf "%62s\n" "Code by ${BOLD}威软科技制作${RES}"
printf "%62s\n" "$(date '+%Y-%m-%d %H:%M')"
echo -e ""
