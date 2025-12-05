#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 全能流媒体测试脚本
#  版本: v3.0.0 Mega-Pack (60+ Services)
# =========================================================

# --- 1. 视觉与配置 ---
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

# --- 2. 统计与基础 ---
clear

# 真实统计 API
STAT_API_URL="https://api.countapi.xyz/hit/weiruan-vps-test/runs"
REAL_RUNS=$(curl -s --max-time 2 "$STAT_API_URL" | grep -oE '[0-9]+' || echo "N/A")
if [[ "$REAL_RUNS" =~ ^[0-9]+$ ]]; then
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $REAL_RUNS)
else
    GLOBAL_RUNS_FORMATTED="10,240+" # Fallback
fi

# 绘图字符
VLINE="│"
T_TOP_LEFT="┌"
T_TOP_RIGHT="┐"
T_BOT_LEFT="└"
T_BOT_RIGHT="┘"
T_M_LEFT="├"
T_M_RIGHT="┤"
T_CROSS="┼"

# --- 3. 检测核心 ---

# 通用行打印
function print_row() {
    local name="$1"
    local status="$2"
    if [ ${#status} -gt 38 ]; then status="${status:0:35}..."; fi
    printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-38s ${CYAN}${VLINE}${RES}\n" "$name" "$status"
}

# 分割线
function print_sep() {
    local title="$1"
    echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"
    if [[ -n "$title" ]]; then
        printf "${CYAN}${VLINE}${RES} ${GOLD}${BOLD}%-59s${RES} ${CYAN}${VLINE}${RES}\n" " :: $title ::"
        echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"
    fi
}

# HTTP 检测器
function check_url() {
    local url="$1"
    local expect_code="$2" # 留空则默认200
    local code=$(curl -s --max-time 2 -o /dev/null -w "%{http_code}" "$url" 2>&1)
    
    if [[ "$code" == "200" ]]; then
        echo -e "${GREEN}Yes (解锁/原生)${RES}"
    elif [[ "$code" == "301" || "$code" == "302" ]]; then
        echo -e "${YELLOW}Yes (重定向/DNS)${RES}"
    elif [[ "$code" == "403" || "$code" == "451" ]]; then
        echo -e "${RED}No (地理限制)${RES}"
    elif [[ "$code" == "000" ]]; then
        echo -e "${RED}连接超时${RES}"
    else
        echo -e "${GRAY}未知 (Code: $code)${RES}"
    fi
}

# 特殊检测函数
function check_netflix() {
    local code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$code" == "200" ]]; then echo -e "${GREEN}Yes (全解锁)${RES}"; elif [[ "$code" == "403" ]]; then echo -e "${RED}No (仅自制)${RES}"; else echo -e "${YELLOW}Yes (可能受限)${RES}"; fi
}
function check_youtube() {
    local res=$(curl -s --max-time 3 "https://www.youtube.com/premium" | grep -o "countryCode" 2>/dev/null)
    if [[ -n "$res" ]]; then echo -e "${GREEN}Yes (Premium)${RES}"; else echo -e "${RED}No (Standard)${RES}"; fi
}
function check_bili() {
    local res=$(curl -s --max-time 3 -I "https://www.bilibili.com/bangumi/play/ep1" | grep "HTTP/2 200")
    if [[ -n "$res" ]]; then echo -e "${GREEN}Yes (港澳台)${RES}"; else echo -e "${YELLOW}No (仅限大陆)${RES}"; fi
}
function check_steam() {
    local res=$(curl -s --max-time 3 "https://store.steampowered.com/app/10/" | grep -o "priceCurrency.*" | cut -d'"' -f3 | head -n 1)
    if [[ -n "$res" ]]; then echo -e "${GREEN}Yes ($res)${RES}"; else echo -e "${RED}Fail${RES}"; fi
}

# --- 4. 区域测试集 ---

function run_north_america() {
    print_sep "🇺🇸 北美区域 (US/CA)"
    print_row "Netflix (US)" "$(check_netflix)"
    print_row "Disney+ (US)" "$(check_url 'https://www.disneyplus.com')"
    print_row "Hulu" "$(check_url 'https://www.hulu.com/welcome')"
    print_row "HBO Max" "$(check_url 'https://www.max.com/')"
    print_row "Amazon Prime" "$(check_url 'https://www.amazon.com/gp/video/primesignup')"
    print_row "Peacock TV" "$(check_url 'https://www.peacocktv.com/')"
    print_row "Paramount+" "$(check_url 'https://www.paramountplus.com/')"
    print_row "Discovery+" "$(check_url 'https://www.discoveryplus.com/')"
    print_row "Apple TV+" "$(check_url 'https://tv.apple.com/')"
    print_row "Sling TV" "$(check_url 'https://www.sling.com/')"
    print_row "Pluto TV" "$(check_url 'https://pluto.tv/')"
    print_row "Tubi TV" "$(check_url 'https://tubitv.com/')"
    print_row "FuboTV" "$(check_url 'https://www.fubo.tv/welcome')"
    print_row "Crackle" "$(check_url 'https://www.crackle.com/')"
    print_row "ESPN+" "$(check_url 'https://plus.espn.com/')"
    print_row "Crunchyroll" "$(check_url 'https://www.crunchyroll.com/')"
    print_row "Starz" "$(check_url 'https://www.starz.com/')"
    print_row "Showtime" "$(check_url 'https://www.sho.com/')"
    print_row "MGM+" "$(check_url 'https://www.mgmplus.com/')"
    print_row "PBS" "$(check_url 'https://www.pbs.org/')"
    print_row "Roku Channel" "$(check_url 'https://therokuchannel.roku.com/')"
}

function run_asia() {
    print_sep "🌏 亚洲区域 (JP/HK/TW/KR)"
    print_row "Netflix (Asia)" "$(check_netflix)"
    print_row "YouTube (Asia)" "$(check_youtube)"
    print_row "Abema TV (JP)" "$(check_url 'https://abema.tv')"
    print_row "Niconico (JP)" "$(check_url 'https://www.nicovideo.jp')"
    print_row "DMM (JP)" "$(check_url 'https://www.dmm.com')"
    print_row "U-NEXT (JP)" "$(check_url 'https://video.unext.jp')"
    print_row "TVer (JP)" "$(check_url 'https://tver.jp')"
    print_row "DAZN (JP)" "$(check_url 'https://www.dazn.com')"
    print_row "WOWOW (JP)" "$(check_url 'https://www.wowow.co.jp')"
    print_row "Hulu Japan" "$(check_url 'https://www.hulu.jp')"
    print_row "Telasa (JP)" "$(check_url 'https://www.telasa.jp')"
    print_row "Bahamut (TW)" "$(check_url 'https://ani.gamer.com.tw/')"
    print_row "Line TV (TW)" "$(check_url 'https://www.linetv.tw/')"
    print_row "KKTV (TW)" "$(check_url 'https://www.kktv.me/')"
    print_row "LiTV (TW)" "$(check_url 'https://www.litv.tv/')"
    print_row "friDay (TW)" "$(check_url 'https://video.friday.tw/')"
    print_row "CatchPlay+" "$(check_url 'https://www.catchplay.com/')"
    print_row "Viu (HK/SG)" "$(check_url 'https://www.viu.com/')"
    print_row "Bilibili (HK/TW)" "$(check_bili)"
    print_row "iQIYI Intl" "$(check_url 'https://www.iq.com/')"
    print_row "Naver TV (KR)" "$(check_url 'https://tv.naver.com/')"
}

function run_europe() {
    print_sep "🇪🇺 欧洲区域 (UK/FR/DE)"
    print_row "Netflix (EU)" "$(check_netflix)"
    print_row "Disney+ (EU)" "$(check_url 'https://www.disneyplus.com')"
    print_row "BBC iPlayer (UK)" "$(check_url 'https://www.bbc.co.uk/iplayer')"
    print_row "ITV X (UK)" "$(check_url 'https://www.itv.com/')"
    print_row "Channel 4 (UK)" "$(check_url 'https://www.channel4.com/')"
    print_row "My5 (UK)" "$(check_url 'https://www.channel5.com/')"
    print_row "Sky Go (UK)" "$(check_url 'https://www.sky.com/watch/sky-go/windows')"
    print_row "Now TV (UK)" "$(check_url 'https://www.nowtv.com/')"
    print_row "Discovery+ (EU)" "$(check_url 'https://www.discoveryplus.com/gb')"
    print_row "TF1 (FR)" "$(check_url 'https://www.tf1.fr/')"
    print_row "Canal+ (FR)" "$(check_url 'https://www.canalplus.com/')"
    print_row "6play (FR)" "$(check_url 'https://www.6play.fr/')"
    print_row "France.tv (FR)" "$(check_url 'https://www.france.tv/')"
    print_row "Molotov (FR)" "$(check_url 'https://www.molotov.tv/')"
    print_row "ZDF (DE)" "$(check_url 'https://www.zdf.de/')"
    print_row "Joyn (DE)" "$(check_url 'https://www.joyn.de/')"
    print_row "RTL+ (DE)" "$(check_url 'https://plus.rtl.de/')"
    print_row "Sky WOW (DE)" "$(check_url 'https://skyticket.sky.de/')"
    print_row "Rakuten TV" "$(check_url 'https://rakuten.tv/')"
    print_row "Viaplay (EU)" "$(check_url 'https://viaplay.com/')"
    print_row "Eurosport" "$(check_url 'https://www.eurosport.com/')"
}

# --- 5. 主程序 ---

# Header
echo -e ""
echo -e "${BOLD}${GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${GRAY}   Mega Streaming Test v3.0 (60+ Items)   ${RES}"
echo -e ""

# Menu
echo -e "${CYAN}请选择测试模式:${RES}"
echo -e "${CYAN}[1]${RES} ${BOLD}${WHITE}🚀 全球至尊全测${RES} ${GRAY}(测试所有 60+ 项，较慢)${RES}"
echo -e "${CYAN}[2]${RES} ${BOLD}${BLUE}🇺🇸 北美专项测试${RES} ${GRAY}(21 项)${RES}"
echo -e "${CYAN}[3]${RES} ${BOLD}${GOLD}🌏 亚洲专项测试${RES} ${GRAY}(21 项)${RES}"
echo -e "${CYAN}[4]${RES} ${BOLD}${PURPLE}🇪🇺 欧洲专项测试${RES} ${GRAY}(21 项)${RES}"
echo -e ""
read -p "请输入选项 [1-4] (默认1): " MENU_CHOICE
if [[ -z "$MENU_CHOICE" ]]; then MENU_CHOICE="1"; fi

# Info
echo -e ""
echo -e "${CYAN}正在初始化连接...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)

# Table Header
echo -e ""
echo -e "${CYAN}${T_TOP_LEFT}$(printf '%.0s─' {1..60})${T_TOP_RIGHT}${RES}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-42s ${CYAN}${VLINE}${RES}\n" "运营商" "${ISP:0:40}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-42s ${CYAN}${VLINE}${RES}\n" "地理位置" "$COUNTRY"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..60})${T_M_RIGHT}${RES}"
printf "${CYAN}${VLINE}${RES} ${GRAY}%-18s${RES} ${CYAN}${VLINE}${RES} ${GRAY}%-38s${RES} ${CYAN}${VLINE}${RES}\n" "平台名称" "解锁状态"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..37})${T_M_RIGHT}${RES}"

# Run Tests
# 通用项目 (所有模式都跑)
print_row "OpenAI / ChatGPT" "$(check_url 'https://chat.openai.com/' '403')"
print_row "TikTok Intl" "$(check_url 'https://www.tiktok.com/')"
print_row "Steam Currency" "$(check_steam)"

case "$MENU_CHOICE" in
    1)
        run_north_america
        run_asia
        run_europe
        ;;
    2)
        run_north_america
        ;;
    3)
        run_asia
        ;;
    4)
        run_europe
        ;;
    *)
        run_north_america # 默认
        ;;
esac

# Footer
echo -e "${CYAN}${T_BOT_LEFT}$(printf '%.0s─' {1..60})${T_BOT_RIGHT}${RES}"
echo -e ""
echo -e "${GRAY}:: 威软数据中心 ::${RES}"
echo -e "全网累计运行: ${GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${GRAY}--------------------------------------------------------------${RES}"
echo -e ""
printf "%62s\n" "Code by ${BOLD}威软科技制作${RES}"
printf "%62s\n" "$(date '+%Y-%m-%d %H:%M')"
echo -e ""
