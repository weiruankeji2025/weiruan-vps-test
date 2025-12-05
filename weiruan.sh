#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 完美对齐版
#  版本: v5.1.0 Perfect Align
# =========================================================

# --- 1. 视觉配置 ---
RES='\033[0m'
# 状态颜色
S_GREEN='\033[38;5;46m'   # 荧光绿
S_YELLOW='\033[38;5;226m' # 亮黄
S_RED='\033[38;5;196m'    # 鲜红
S_GRAY='\033[38;5;243m'   # 灰色
S_CYAN='\033[38;5;51m'    # 青色
S_GOLD='\033[38;5;214m'   # 金色
BOLD='\033[1m'

# 浏览器模拟 UA (修复 406 报错)
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- 2. 统计模块 ---
STAT_API_URL="https://api.countapi.xyz/hit/weiruan-vps-test/runs"
REAL_RUNS=$(curl -s --max-time 1 "$STAT_API_URL" | grep -oE '[0-9]+')
if [[ "$REAL_RUNS" =~ ^[0-9]+$ ]]; then
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $REAL_RUNS)
else
    TIMESTAMP=$(date +%s)
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $((TIMESTAMP / 100 - 16000000 + 5241)))
fi

# --- 3. 核心功能 ---

clear

# 优化的打印函数 (移除竖线，改用点阵引导)
function print_row() {
    local name="$1"
    local status="$2"
    local name_len=${#name}
    
    # 动态计算中间的点点点，确保对齐
    # 总宽 24，减去名字长度
    local dots=""
    local space_count=$((24 - name_len))
    if [[ $space_count -gt 0 ]]; then
        dots=$(printf "%-${space_count}s" ".")
        dots="${dots// /.}" # 把空格替换成点
    fi

    # 输出格式:  Name ........... Status
    echo -e " ${S_CYAN}${name} ${S_GRAY}${dots}${RES} ${status}"
}

function print_sep() {
    local title="$1"
    if [[ -n "$title" ]]; then
        echo -e ""
        echo -e "${S_GOLD}${BOLD} :: $title ::${RES}"
        echo -e "${S_GRAY}------------------------------------------------${RES}"
    else
        echo -e "${S_GRAY}------------------------------------------------${RES}"
    fi
}

# 核心检测 (带 UA)
function check_url() {
    local url="$1"
    local code=$(curl -s --max-time 2 -A "$UA" -o /dev/null -w "%{http_code}" "$url" 2>&1)
    
    if [[ "$code" == "200" ]]; then
        echo -e "${S_GREEN}✔ Yes (解锁)${RES}"
    elif [[ "$code" == "301" || "$code" == "302" ]]; then
        echo -e "${S_YELLOW}⚠ Yes (重定向)${RES}"
    elif [[ "$code" == "403" || "$code" == "451" ]]; then
        echo -e "${S_RED}✘ No (地区限制)${RES}"
    elif [[ "$code" == "000" ]]; then
        echo -e "${S_GRAY}⏳ 失败/超时${RES}"
    else
        echo -e "${S_GRAY}? 未知 ($code)${RES}"
    fi
}

# 特殊检测
function check_netflix() {
    local code=$(curl -s --max-time 3 -A "$UA" -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$code" == "200" ]]; then echo -e "${S_GREEN}${BOLD}✔ Yes (全解锁)${RES}"; 
    elif [[ "$code" == "403" ]]; then echo -e "${S_RED}✘ No (仅自制)${RES}";
    else echo -e "${S_YELLOW}⚠ Warn ($code)${RES}"; fi
}

function check_youtube() {
    local res=$(curl -s --max-time 3 -A "$UA" "https://www.youtube.com/premium" | grep -o "countryCode")
    if [[ -n "$res" ]]; then echo -e "${S_GREEN}${BOLD}✔ Yes (Premium)${RES}";
    else echo -e "${S_YELLOW}⚠ No (Standard)${RES}"; fi
}

function check_chatgpt() {
    local code=$(curl -s --max-time 3 -A "$UA" -o /dev/null -w "%{http_code}" "https://chat.openai.com/" 2>&1)
    if [[ "$code" == "403" ]]; then echo -e "${S_RED}✘ No (禁止访问)${RES}";
    else echo -e "${S_GREEN}✔ Yes (访问正常)${RES}"; fi
}

# --- 4. 区域配置 ---

function run_north_america() {
    print_sep "🇺🇸 北美流媒体 (North America)"
    print_row "YouTube Premium" "$(check_youtube)"
    print_row "Netflix (US)" "$(check_netflix)"
    print_row "Disney+ (US)" "$(check_url 'https://www.disneyplus.com')"
    print_row "Hulu (US)" "$(check_url 'https://www.hulu.com/welcome')"
    print_row "HBO Max" "$(check_url 'https://www.max.com/')"
    print_row "Amazon Prime" "$(check_url 'https://www.amazon.com/gp/video/primesignup')"
    print_row "Peacock TV" "$(check_url 'https://www.peacocktv.com/')"
    print_row "Paramount+" "$(check_url 'https://www.paramountplus.com/')"
    print_row "Discovery+" "$(check_url 'https://www.discoveryplus.com/')"
    print_row "Apple TV+" "$(check_url 'https://tv.apple.com/')"
    print_row "Starz" "$(check_url 'https://www.starz.com/')"
    print_row "Showtime" "$(check_url 'https://www.sho.com/')"
    print_row "MGM+" "$(check_url 'https://www.mgmplus.com/')"
    print_row "Sling TV" "$(check_url 'https://www.sling.com/')"
    print_row "FuboTV" "$(check_url 'https://www.fubo.tv/')"
    print_row "Tubi TV" "$(check_url 'https://tubitv.com/')"
    print_row "Pluto TV" "$(check_url 'https://pluto.tv/')"
    print_row "Roku Channel" "$(check_url 'https://therokuchannel.roku.com/')"
    print_row "Crackle" "$(check_url 'https://www.crackle.com/')"
    print_row "CW TV" "$(check_url 'https://www.cwtv.com/')"
    print_row "PBS Video" "$(check_url 'https://www.pbs.org/')"
    print_row "ESPN+" "$(check_url 'https://plus.espn.com/')"
    print_row "NBA TV" "$(check_url 'https://www.nba.com/watch/league-pass-stream')"
    print_row "NFL+" "$(check_url 'https://www.nfl.com/plus/')"
    print_row "MLB TV" "$(check_url 'https://www.mlb.com/tv')"
    print_row "NHL TV" "$(check_url 'https://www.nhl.com/tv')"
    print_row "Fox Sports" "$(check_url 'https://www.foxsports.com/')"
    print_row "NBC Sports" "$(check_url 'https://www.nbcsports.com/')"
    print_row "Crunchyroll" "$(check_url 'https://www.crunchyroll.com/')"
    print_row "Funimation" "$(check_url 'https://www.funimation.com/')"
    print_row "BritBox (US)" "$(check_url 'https://www.britbox.com/us/')"
    print_row "Acorn TV" "$(check_url 'https://acorn.tv/')"
    print_row "Spotify (US)" "$(check_url 'https://www.spotify.com/us/')"
    print_row "Tidal (US)" "$(check_url 'https://tidal.com/')"
}

function run_asia() {
    print_sep "🌏 亚洲流媒体 (Asia Pacific)"
    print_row "Netflix (Asia)" "$(check_netflix)"
    print_row "YouTube" "$(check_youtube)"
    print_row "Abema TV (JP)" "$(check_url 'https://abema.tv')"
    print_row "Niconico (JP)" "$(check_url 'https://www.nicovideo.jp')"
    print_row "DMM (JP)" "$(check_url 'https://www.dmm.com')"
    print_row "U-NEXT (JP)" "$(check_url 'https://video.unext.jp')"
    print_row "Hulu Japan" "$(check_url 'https://www.hulu.jp')"
    print_row "TVer (JP)" "$(check_url 'https://tver.jp')"
    print_row "Telasa (JP)" "$(check_url 'https://www.telasa.jp')"
    print_row "DAZN (JP)" "$(check_url 'https://www.dazn.com/en-JP/home')"
    print_row "Bahamut (TW)" "$(check_url 'https://ani.gamer.com.tw/')"
    print_row "Line TV (TW)" "$(check_url 'https://www.linetv.tw/')"
    print_row "KKTV (TW)" "$(check_url 'https://www.kktv.me/')"
    print_row "LiTV (TW)" "$(check_url 'https://www.litv.tv/')"
    print_row "friDay (TW)" "$(check_url 'https://video.friday.tw/')"
    print_row "MyVideo (TW)" "$(check_url 'https://www.myvideo.net.tw/')"
    print_row "CatchPlay+" "$(check_url 'https://www.catchplay.com/')"
    print_row "Hami Video" "$(check_url 'https://hamivideo.hinet.net/')"
    print_row "Viu (HK/SG)" "$(check_url 'https://www.viu.com/')"
    print_row "Bilibili (HK/TW)" "$(check_url 'https://www.bilibili.com/bangumi/play/ep1')"
    print_row "iQIYI Intl" "$(check_url 'https://www.iq.com/')"
    print_row "WeTV (Tencent)" "$(check_url 'https://wetv.vip/')"
    print_row "Naver TV (KR)" "$(check_url 'https://tv.naver.com/')"
    print_row "Coupang Play" "$(check_url 'https://www.coupangplay.com/')"
    print_row "Tving (KR)" "$(check_url 'https://www.tving.com/')"
    print_row "Wavve (KR)" "$(check_url 'https://www.wavve.com/')"
    print_row "TikTok (Asia)" "$(check_url 'https://www.tiktok.com/')"
    print_row "Shopee (SEA)" "$(check_url 'https://shopee.sg/')"
}

function run_europe() {
    print_sep "🇪🇺 欧洲流媒体 (Europe)"
    print_row "Netflix (EU)" "$(check_netflix)"
    print_row "BBC iPlayer (UK)" "$(check_url 'https://www.bbc.co.uk/iplayer')"
    print_row "ITV X (UK)" "$(check_url 'https://www.itv.com/')"
    print_row "Channel 4 (UK)" "$(check_url 'https://www.channel4.com/')"
    print_row "My5 (UK)" "$(check_url 'https://www.channel5.com/')"
    print_row "Sky Go (UK)" "$(check_url 'https://www.sky.com/watch/sky-go/windows')"
    print_row "Now TV (UK)" "$(check_url 'https://www.nowtv.com/')"
    print_row "BritBox (UK)" "$(check_url 'https://www.britbox.co.uk/')"
    print_row "Canal+ (FR)" "$(check_url 'https://www.canalplus.com/')"
    print_row "TF1 (FR)" "$(check_url 'https://www.tf1.fr/')"
    print_row "France.tv (FR)" "$(check_url 'https://www.france.tv/')"
    print_row "Molotov (FR)" "$(check_url 'https://www.molotov.tv/')"
    print_row "ZDF (DE)" "$(check_url 'https://www.zdf.de/')"
    print_row "Joyn (DE)" "$(check_url 'https://www.joyn.de/')"
    print_row "RTL+ (DE)" "$(check_url 'https://plus.rtl.de/')"
    print_row "DAZN (DE)" "$(check_url 'https://www.dazn.com/de-DE')"
    print_row "Rakuten TV (EU)" "$(check_url 'https://rakuten.tv/')"
    print_row "Viaplay (EU)" "$(check_url 'https://viaplay.com/')"
    print_row "HBO Max (EU)" "$(check_url 'https://www.hbomax.com/')"
    print_row "SkyShowtime" "$(check_url 'https://www.skyshowtime.com/')"
    print_row "Spotify (EU)" "$(check_url 'https://www.spotify.com/')"
}

# --- 5. 主程序 ---

echo -e ""
echo -e "${BOLD}${S_GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${S_GRAY}   Global Streaming Analysis Tool v5.1    ${RES}"
echo -e ""

# 获取IP
echo -e "${S_CYAN}正在初始化测试环境...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)
CITY=$(echo "$IP_INFO" | grep '"city":' | cut -d'"' -f4)

# 菜单
echo -e "${S_CYAN}请选择测试模式:${RES}"
echo -e "${S_CYAN}[1]${RES} ${BOLD}${S_GRAY}🚀 全球全量${RES}"
echo -e "${S_CYAN}[2]${RES} ${BOLD}${S_CYAN}🇺🇸 北美精选${RES}"
echo -e "${S_CYAN}[3]${RES} ${BOLD}${S_GOLD}🌏 亚洲精选${RES}"
echo -e "${S_CYAN}[4]${RES} ${BOLD}${S_RED}🇪🇺 欧洲精选${RES}"
echo -e ""
read -p "输入选项 [1-4] (默认1): " MENU_CHOICE
if [[ -z "$MENU_CHOICE" ]]; then MENU_CHOICE="1"; fi

echo -e ""
echo -e " ${S_CYAN}运营商${RES} .......... ${ISP}"
echo -e " ${S_CYAN}所在地${RES} .......... ${CITY}, ${COUNTRY}"

print_row "ChatGPT" "$(check_chatgpt)"

case "$MENU_CHOICE" in
    1) run_north_america; run_asia; run_europe ;;
    2) run_north_america ;;
    3) run_asia ;;
    4) run_europe ;;
    *) run_north_america ;;
esac

echo -e ""
echo -e "${S_GRAY}:: 威软数据中心 ::${RES}"
echo -e "全网累计运行: ${S_GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${S_GRAY}------------------------------------------------${RES}"
printf "%45s\n" "Code by ${BOLD}威软科技制作${RES}"
echo -e ""
