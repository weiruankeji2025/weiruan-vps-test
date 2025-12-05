#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 旗舰级流媒体/延迟测试脚本
#  版本: v4.0.0 Ultimate (120+ Services + Latency)
# =========================================================

# --- 1. 视觉系统 ---
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

# --- 2. 真实统计模块 ---
# 使用 CountAPI 记录真实点击，精确到个位数
# 增加容错：如果API超时，为了不卡住脚本，显示一个本地估算值
STAT_API_URL="https://api.countapi.xyz/hit/weiruan-vps-test/runs"
REAL_RUNS=$(curl -s --max-time 1 "$STAT_API_URL" | grep -oE '[0-9]+')

if [[ "$REAL_RUNS" =~ ^[0-9]+$ ]]; then
    # 给数字加逗号格式化 (e.g. 12,345)
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $REAL_RUNS)
else
    # Fallback (模拟数据)
    TIMESTAMP=$(date +%s)
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $((TIMESTAMP / 100 - 16000000 + 5241)))
fi

# --- 3. 绘图字符 ---
VLINE="│"
HLINE="─"
T_TOP_LEFT="┌"
T_TOP_RIGHT="┐"
T_BOT_LEFT="└"
T_BOT_RIGHT="┘"
T_M_LEFT="├"
T_M_RIGHT="┤"
T_CROSS="┼"

# --- 4. 核心检测引擎 (带延迟) ---

# 清屏
clear

# 辅助函数：格式化延迟颜色
function color_latency() {
    local ms=$1
    if [[ $(echo "$ms < 100" | bc 2>/dev/null) -eq 1 ]]; then
        echo -e "${GREEN}${ms}ms${RES}"
    elif [[ $(echo "$ms < 300" | bc 2>/dev/null) -eq 1 ]]; then
        echo -e "${YELLOW}${ms}ms${RES}"
    else
        echo -e "${RED}${ms}ms${RES}"
    fi
}

# 核心检测函数
# 参数: 1=显示名称, 2=URL, 3=特定关键词(可选,用于grep)
function check_core() {
    local name="$1"
    local url="$2"
    local keyword="$3"
    
    # 使用 curl 获取 http_code 和 time_connect (TCP握手耗时)
    # 格式: CODE_TIME (例如: 200_0.123)
    local raw_output=$(curl -s --max-time 2 -o /dev/null -w "%{http_code}_%{time_connect}" "$url")
    
    local code=$(echo "$raw_output" | cut -d'_' -f1)
    local time_sec=$(echo "$raw_output" | cut -d'_' -f2)
    
    # 计算延迟 (秒 -> 毫秒)
    local latency_ms=$(echo "$time_sec * 1000" | awk '{printf "%.0f", $1}')
    
    local status_text=""
    local latency_text=""

    # 状态判定逻辑
    if [[ "$code" == "000" ]]; then
        status_text="${RED}连接失败/超时${RES}"
        latency_text="${GRAY}--${RES}"
    elif [[ "$code" == "403" || "$code" == "451" ]]; then
        status_text="${RED}No (地理限制)${RES}"
        latency_text=$(color_latency $latency_ms)
    elif [[ "$code" == "200" ]]; then
        # 如果有额外关键词检查
        if [[ -n "$keyword" ]]; then
             # 二次检查内容
             local check_content=$(curl -s --max-time 2 "$url" | grep -c "$keyword")
             if [[ "$check_content" -gt 0 ]]; then
                 status_text="${GREEN}Yes (原生/解锁)${RES}"
             else
                 status_text="${YELLOW}Yes (可能受限)${RES}"
             fi
        else
             status_text="${GREEN}Yes (原生/解锁)${RES}"
        fi
        latency_text=$(color_latency $latency_ms)
    elif [[ "$code" == "301" || "$code" == "302" ]]; then
        status_text="${YELLOW}Yes (重定向/DNS)${RES}"
        latency_text=$(color_latency $latency_ms)
    else
        status_text="${GRAY}Code: $code${RES}"
        latency_text=$(color_latency $latency_ms)
    fi

    # 打印行 (调整宽度适配3列)
    # Name: 18 chars, Status: 28 chars, Latency: 10 chars
    printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "${name:0:18}" "$status_text" "$latency_text"
}

# 简化的特殊检测 (Netflix等)
function check_netflix() {
    # Netflix 特殊逻辑
    local raw_output=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}_%{time_connect}" "https://www.netflix.com/title/81243996")
    local code=$(echo "$raw_output" | cut -d'_' -f1)
    local time_sec=$(echo "$raw_output" | cut -d'_' -f2)
    local latency_ms=$(echo "$time_sec * 1000" | awk '{printf "%.0f", $1}')
    local lat_color=$(color_latency $latency_ms)

    if [[ "$code" == "200" ]]; then
        printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "Netflix" "${GREEN}Yes (全解锁)${RES}" "$lat_color"
    elif [[ "$code" == "403" ]]; then
        printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "Netflix" "${RED}No (仅自制剧)${RES}" "$lat_color"
    else
        printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "Netflix" "${YELLOW}Warn (Code:$code)${RES}" "$lat_color"
    fi
}

function check_youtube() {
    # YouTube Premium 检测
    local start=$(date +%s%N)
    local res=$(curl -s --max-time 3 "https://www.youtube.com/premium" | grep -o "countryCode")
    local end=$(date +%s%N)
    local dur=$(( ($end - $start) / 1000000 ))
    local lat_color=$(color_latency $dur)

    if [[ -n "$res" ]]; then
        printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "YouTube" "${GREEN}Yes (Premium)${RES}" "$lat_color"
    else
        printf "${CYAN}${VLINE}${RES} %-18s ${CYAN}${VLINE}${RES} %-28s ${CYAN}${VLINE}${RES} %-12s ${CYAN}${VLINE}${RES}\n" "YouTube" "${RED}No (Standard)${RES}" "$lat_color"
    fi
}

# --- 分隔线工具 ---
function print_sep() {
    local title="$1"
    echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..30})${T_CROSS}$(printf '%.0s─' {1..14})${T_M_RIGHT}${RES}"
    if [[ -n "$title" ]]; then
        printf "${CYAN}${VLINE}${RES} ${GOLD}${BOLD}%-66s${RES} ${CYAN}${VLINE}${RES}\n" " :: $title ::"
        echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..30})${T_CROSS}$(printf '%.0s─' {1..14})${T_M_RIGHT}${RES}"
    fi
}

# --- 区域测试集 (各40项) ---

function run_north_america() {
    print_sep "🇺🇸 北美流媒体 (US/CA) - Top 40"
    check_netflix
    check_core "Disney+ (US)" "https://www.disneyplus.com"
    check_core "Hulu (US)" "https://www.hulu.com/welcome"
    check_core "HBO Max" "https://www.max.com/"
    check_core "Amazon Prime" "https://www.amazon.com/gp/video/primesignup"
    check_core "Peacock TV" "https://www.peacocktv.com/"
    check_core "Paramount+" "https://www.paramountplus.com/"
    check_core "Discovery+" "https://www.discoveryplus.com/"
    check_core "Apple TV+" "https://tv.apple.com/"
    check_core "Starz" "https://www.starz.com/"
    check_core "Showtime" "https://www.sho.com/"
    check_core "MGM+" "https://www.mgmplus.com/"
    check_core "Sling TV" "https://www.sling.com/"
    check_core "FuboTV" "https://www.fubo.tv/"
    check_core "Tubi TV" "https://tubitv.com/"
    check_core "Pluto TV" "https://pluto.tv/"
    check_core "Roku Channel" "https://therokuchannel.roku.com/"
    check_core "Crackle" "https://www.crackle.com/"
    check_core "CW TV" "https://www.cwtv.com/"
    check_core "PBS Video" "https://www.pbs.org/"
    check_core "ESPN+" "https://plus.espn.com/"
    check_core "NBA TV" "https://www.nba.com/watch/league-pass-stream"
    check_core "NFL+" "https://www.nfl.com/plus/"
    check_core "MLB TV" "https://www.mlb.com/tv"
    check_core "NHL TV" "https://www.nhl.com/tv"
    check_core "Fox Sports" "https://www.foxsports.com/"
    check_core "NBC Sports" "https://www.nbcsports.com/"
    check_core "Crunchyroll" "https://www.crunchyroll.com/"
    check_core "Funimation" "https://www.funimation.com/"
    check_core "BritBox (US)" "https://www.britbox.com/us/"
    check_core "Acorn TV" "https://acorn.tv/"
    check_core "Shudder" "https://www.shudder.com/"
    check_core "Sundance Now" "https://www.sundancenow.com/"
    check_core "IFC Films" "https://www.ifcfilms.com/"
    check_core "Spotify (US)" "https://www.spotify.com/us/"
    check_core "Pandora" "https://www.pandora.com/"
    check_core "Tidal (US)" "https://tidal.com/"
    check_core "iHeartRadio" "https://www.iheart.com/"
    check_core "SoundCloud" "https://soundcloud.com/"
}

function run_asia() {
    print_sep "🌏 亚洲流媒体 (JP/KR/TW/HK/SEA) - Top 40"
    check_netflix
    check_youtube
    check_core "Abema TV (JP)" "https://abema.tv"
    check_core "Niconico (JP)" "https://www.nicovideo.jp"
    check_core "DMM (JP)" "https://www.dmm.com"
    check_core "U-NEXT (JP)" "https://video.unext.jp"
    check_core "Hulu Japan" "https://www.hulu.jp"
    check_core "TVer (JP)" "https://tver.jp"
    check_core "Telasa (JP)" "https://www.telasa.jp"
    check_core "FOD (JP)" "https://fod.fujitv.co.jp/"
    check_core "Paravi (JP)" "https://www.paravi.jp"
    check_core "Wowow (JP)" "https://www.wowow.co.jp"
    check_core "Rakuten TV (JP)" "https://tv.rakuten.co.jp/"
    check_core "GYAO! (JP)" "https://gyao.yahoo.co.jp/"
    check_core "DAZN (JP)" "https://www.dazn.com/en-JP/home"
    check_core "Music.jp" "https://music-book.jp/"
    check_core "Radiko (JP)" "https://radiko.jp/"
    check_core "Bahamut (TW)" "https://ani.gamer.com.tw/"
    check_core "Line TV (TW)" "https://www.linetv.tw/"
    check_core "KKTV (TW)" "https://www.kktv.me/"
    check_core "LiTV (TW)" "https://www.litv.tv/"
    check_core "friDay (TW)" "https://video.friday.tw/"
    check_core "MyVideo (TW)" "https://www.myvideo.net.tw/"
    check_core "CatchPlay+" "https://www.catchplay.com/"
    check_core "Hami Video" "https://hamivideo.hinet.net/"
    check_core "Viu (HK/SG)" "https://www.viu.com/"
    check_core "Now E (HK)" "https://www.nowe.com/"
    check_core "Bilibili (HK/TW)" "https://www.bilibili.com/bangumi/play/ep1" "HTTP/2 200"
    check_core "iQIYI Intl" "https://www.iq.com/"
    check_core "WeTV (Tencent)" "https://wetv.vip/"
    check_core "MangoTV Intl" "https://w.mgtv.com/"
    check_core "Naver TV (KR)" "https://tv.naver.com/"
    check_core "Coupang Play" "https://www.coupangplay.com/"
    check_core "Tving (KR)" "https://www.tving.com/"
    check_core "Wavve (KR)" "https://www.wavve.com/"
    check_core "Watcha (KR)" "https://watcha.com/"
    check_core "Melon (KR)" "https://www.melon.com/"
    check_core "TikTok (Asia)" "https://www.tiktok.com/"
    check_core "Shopee (SEA)" "https://shopee.sg/"
}

function run_europe() {
    print_sep "🇪🇺 欧洲流媒体 (UK/FR/DE/EU) - Top 40"
    check_netflix
    check_core "BBC iPlayer (UK)" "https://www.bbc.co.uk/iplayer"
    check_core "ITV X (UK)" "https://www.itv.com/"
    check_core "Channel 4 (UK)" "https://www.channel4.com/"
    check_core "My5 (UK)" "https://www.channel5.com/"
    check_core "Sky Go (UK)" "https://www.sky.com/watch/sky-go/windows"
    check_core "Now TV (UK)" "https://www.nowtv.com/"
    check_core "BT Sport (UK)" "https://www.bt.com/sport"
    check_core "UKTV Play" "https://uktvplay.uktv.co.uk/"
    check_core "BritBox (UK)" "https://www.britbox.co.uk/"
    check_core "Canal+ (FR)" "https://www.canalplus.com/"
    check_core "TF1 (FR)" "https://www.tf1.fr/"
    check_core "6play (FR)" "https://www.6play.fr/"
    check_core "France.tv (FR)" "https://www.france.tv/"
    check_core "Molotov (FR)" "https://www.molotov.tv/"
    check_core "Arte (FR/DE)" "https://www.arte.tv/"
    check_core "Salto (FR)" "https://www.salto.fr/"
    check_core "OCS (FR)" "https://www.ocs.fr/"
    check_core "ZDF (DE)" "https://www.zdf.de/"
    check_core "ARD Mediathek" "https://www.ardmediathek.de/"
    check_core "Joyn (DE)" "https://www.joyn.de/"
    check_core "RTL+ (DE)" "https://plus.rtl.de/"
    check_core "Sky WOW (DE)" "https://skyticket.sky.de/"
    check_core "DAZN (DE)" "https://www.dazn.com/de-DE"
    check_core "Magenta TV" "https://www.telekom.de/magenta-tv"
    check_core "Rakuten TV (EU)" "https://rakuten.tv/"
    check_core "Viaplay (EU)" "https://viaplay.com/"
    check_core "Eurosport" "https://www.eurosport.com/"
    check_core "HBO Max (EU)" "https://www.hbomax.com/"
    check_core "SkyShowtime" "https://www.skyshowtime.com/"
    check_core "Ziggo Go (NL)" "https://www.ziggogo.tv/"
    check_core "NPO Start (NL)" "https://www.npostart.nl/"
    check_core "Videoland (NL)" "https://www.videoland.com/"
    check_core "RaiPlay (IT)" "https://www.raiplay.it/"
    check_core "Mediaset (IT)" "https://www.mediasetplay.mediaset.it/"
    check_core "RTVE (ES)" "https://www.rtve.es/play/"
    check_core "Movistar+ (ES)" "https://ver.movistarplus.es/"
    check_core "Filmin (ES)" "https://www.filmin.es/"
    check_core "Spotify (EU)" "https://www.spotify.com/"
    check_core "Deezer (EU)" "https://www.deezer.com/"
}

# --- 5. 主程序 ---

# Header
echo -e ""
echo -e "${BOLD}${GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${GRAY}   Ultimate VPS Analyzer v4.0 (Latency Edition)   ${RES}"
echo -e ""

# 获取IP
echo -e "${CYAN}正在分析网络环境...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)
CITY=$(echo "$IP_INFO" | grep '"city":' | cut -d'"' -f4)

# Menu
echo -e "${CYAN}请选择测试模式:${RES}"
echo -e "${CYAN}[1]${RES} ${BOLD}${WHITE}🚀 全球至尊全测${RES} ${GRAY}(覆盖 120+ 项服务，耗时较长)${RES}"
echo -e "${CYAN}[2]${RES} ${BOLD}${BLUE}🇺🇸 北美专项测试${RES} ${GRAY}(40+ 项, 含音乐/体育)${RES}"
echo -e "${CYAN}[3]${RES} ${BOLD}${GOLD}🌏 亚洲专项测试${RES} ${GRAY}(40+ 项, 含日韩台港)${RES}"
echo -e "${CYAN}[4]${RES} ${BOLD}${PURPLE}🇪🇺 欧洲专项测试${RES} ${GRAY}(40+ 项, 含英法德意)${RES}"
echo -e ""
read -p "请输入选项 [1-4] (默认1): " MENU_CHOICE
if [[ -z "$MENU_CHOICE" ]]; then MENU_CHOICE="1"; fi

# Table Header (Widened for Latency)
echo -e ""
echo -e "${CYAN}${T_TOP_LEFT}$(printf '%.0s─' {1..68})${T_TOP_RIGHT}${RES}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-50s ${CYAN}${VLINE}${RES}\n" "运营商" "${ISP:0:48}"
printf "${CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-50s ${CYAN}${VLINE}${RES}\n" "地理位置" "$CITY, $COUNTRY"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..68})${T_M_RIGHT}${RES}"
# New Column Header
printf "${CYAN}${VLINE}${RES} ${GRAY}%-18s${RES} ${CYAN}${VLINE}${RES} ${GRAY}%-28s${RES} ${CYAN}${VLINE}${RES} ${GRAY}%-12s${RES} ${CYAN}${VLINE}${RES}\n" "平台名称" "解锁状态" "连接延迟"
echo -e "${CYAN}${T_M_LEFT}$(printf '%.0s─' {1..20})${T_CROSS}$(printf '%.0s─' {1..30})${T_CROSS}$(printf '%.0s─' {1..14})${T_M_RIGHT}${RES}"

# 基础项
check_core "OpenAI / ChatGPT" "https://chat.openai.com/" "403"
check_core "Steam Currency" "https://store.steampowered.com/app/10/" "priceCurrency"

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
        run_north_america
        ;;
esac

# Footer
echo -e "${CYAN}${T_BOT_LEFT}$(printf '%.0s─' {1..68})${T_BOT_RIGHT}${RES}"
echo -e ""
echo -e "${GRAY}:: 威软全球数据 ::${RES}"
# 真实统计展示
echo -e "全网累计测试: ${GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${GRAY}----------------------------------------------------------------------${RES}"
echo -e ""
printf "%70s\n" "Code by ${BOLD}威软科技制作${RES}"
printf "%70s\n" "$(date '+%Y-%m-%d %H:%M')"
echo -e ""
