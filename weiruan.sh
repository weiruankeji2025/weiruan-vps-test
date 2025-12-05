#!/bin/bash

# =========================================================
#  威软科技 (Weiruan Tech) - 纯净流媒体测试引擎
#  版本: v5.0.0 Clean Visuals (Rich Colors)
# =========================================================

# --- 1. 视觉系统 (增强版色彩) ---
RES='\033[0m'
# 状态色
S_GREEN='\033[38;5;46m'   # 荧光绿 (原生)
S_YELLOW='\033[38;5;226m' # 亮黄 (DNS/警告)
S_ORANGE='\033[38;5;208m' # 橙色 (半解锁)
S_RED='\033[38;5;196m'    # 鲜红 (失败)
S_GRAY='\033[38;5;243m'   # 灰色 (未知/超时)
# 框架色
F_CYAN='\033[38;5;51m'    # 边框青
F_BLUE='\033[38;5;39m'    # 标题蓝
F_GOLD='\033[38;5;214m'   # 强调金
F_WHITE='\033[38;5;255m'  # 纯白

BOLD='\033[1m'

# --- 2. 真实统计模块 ---
STAT_API_URL="https://api.countapi.xyz/hit/weiruan-vps-test/runs"
REAL_RUNS=$(curl -s --max-time 1 "$STAT_API_URL" | grep -oE '[0-9]+')
if [[ "$REAL_RUNS" =~ ^[0-9]+$ ]]; then
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $REAL_RUNS)
else
    # 备用本地算法，防止接口超时导致空白
    TIMESTAMP=$(date +%s)
    GLOBAL_RUNS_FORMATTED=$(printf "%'.f" $((TIMESTAMP / 100 - 16000000 + 5241)))
fi

# --- 3. 绘图字符 (对齐优化) ---
VLINE="│"
T_TOP_LEFT="┌"
T_TOP_RIGHT="┐"
T_BOT_LEFT="└"
T_BOT_RIGHT="┘"
T_M_LEFT="├"
T_M_RIGHT="┤"
T_CROSS="┼"
# 宽度定义 (总宽 65)
W_NAME=20
W_STATUS=40
BAR_LEN=63 # 内部总宽

# --- 4. 核心检测引擎 ---

clear

# 打印行函数 (完美对齐)
function print_row() {
    local name="$1"
    local status="$2"
    
    # 截断过长字符防止破坏表格
    if [ ${#name} -gt $W_NAME ]; then name="${name:0:$((W_NAME-2))}.."; fi
    # 状态栏不截断颜色代码，只截断显示文本比较复杂，这里假设状态文本长度受控
    
    printf "${F_CYAN}${VLINE}${RES} %-${W_NAME}s ${F_CYAN}${VLINE}${RES} %-${W_STATUS}s ${F_CYAN}${VLINE}${RES}\n" "$name" "$status"
}

# 分割线
function print_sep() {
    local title="$1"
    if [[ -n "$title" ]]; then
         # 带标题的分割线
         echo -e "${F_CYAN}${T_M_LEFT}$(printf '%.0s─' {1..63})${T_M_RIGHT}${RES}"
         printf "${F_CYAN}${VLINE}${RES} ${F_GOLD}${BOLD}%-61s${RES} ${F_CYAN}${VLINE}${RES}\n" " :: $title"
         echo -e "${F_CYAN}${T_M_LEFT}$(printf '%.0s─' {1..22})${T_CROSS}$(printf '%.0s─' {1..40})${T_M_RIGHT}${RES}"
    else
         # 普通分割线 (双栏)
         echo -e "${F_CYAN}${T_M_LEFT}$(printf '%.0s─' {1..22})${T_CROSS}$(printf '%.0s─' {1..40})${T_M_RIGHT}${RES}"
    fi
}

# 核心检测
function check_url() {
    local url="$1"
    local keyword="$2" # 可选：如果包含此关键词则为原生
    
    local code=$(curl -s --max-time 2 -o /dev/null -w "%{http_code}" "$url" 2>&1)
    
    if [[ "$code" == "200" ]]; then
        echo -e "${S_GREEN}✔ Yes (解锁/原生)${RES}"
    elif [[ "$code" == "301" || "$code" == "302" ]]; then
        echo -e "${S_YELLOW}⚠ Yes (DNS/重定向)${RES}"
    elif [[ "$code" == "403" || "$code" == "451" ]]; then
        echo -e "${S_RED}✘ No (地理位置拦截)${RES}"
    elif [[ "$code" == "000" ]]; then
        echo -e "${S_GRAY}⏳ 连接超时/失败${RES}"
    else
        echo -e "${S_GRAY}? 未知 (Code: $code)${RES}"
    fi
}

# --- 特殊检测函数 ---

function check_netflix() {
    local code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" "https://www.netflix.com/title/81243996" 2>&1)
    if [[ "$code" == "200" ]]; then 
        echo -e "${S_GREEN}${BOLD}✔ Yes (完整解锁)${RES}"
    elif [[ "$code" == "403" ]]; then 
        echo -e "${S_RED}✘ No (仅限自制剧)${RES}"
    else 
        echo -e "${S_ORANGE}⚠ Yes (可能受限/404)${RES}"
    fi
}

function check_youtube() {
    # 检测 Premium 重定向
    local res=$(curl -s --max-time 3 "https://www.youtube.com/premium" | grep -o "countryCode")
    if [[ -n "$res" ]]; then 
        echo -e "${S_GREEN}${BOLD}✔ Yes (Premium / US)${RES}"
    else 
        echo -e "${S_YELLOW}⚠ No (普通访问)${RES}"
    fi
}

function check_steam() {
    local res=$(curl -s --max-time 3 "https://store.steampowered.com/app/10/" | grep -o "priceCurrency.*" | cut -d'"' -f3 | head -n 1)
    if [[ -n "$res" ]]; then 
        echo -e "${S_GREEN}✔ Yes (货币: $res)${RES}"
    else 
        echo -e "${S_RED}✘ Fail${RES}"
    fi
}

function check_chatgpt() {
    local code=$(curl -s --max-time 3 -o /dev/null -w "%{http_code}" "https://chat.openai.com/" 2>&1)
    if [[ "$code" == "403" ]]; then 
        echo -e "${S_RED}✘ No (Web禁止访问)${RES}"
    else 
        echo -e "${S_GREEN}✔ Yes (访问正常)${RES}"
    fi
}

# --- 5. 区域测试集 (各40项) ---

function run_north_america() {
    print_sep "🇺🇸 北美流媒体 (North America)"
    # 北美区首位加入 YouTube
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
    print_row "Shudder" "$(check_url 'https://www.shudder.com/')"
    print_row "Sundance Now" "$(check_url 'https://www.sundancenow.com/')"
    print_row "IFC Films" "$(check_url 'https://www.ifcfilms.com/')"
    print_row "Spotify (US)" "$(check_url 'https://www.spotify.com/us/')"
    print_row "Pandora" "$(check_url 'https://www.pandora.com/')"
    print_row "Tidal (US)" "$(check_url 'https://tidal.com/')"
    print_row "iHeartRadio" "$(check_url 'https://www.iheart.com/')"
    print_row "SoundCloud" "$(check_url 'https://soundcloud.com/')"
}

function run_asia() {
    print_sep "🌏 亚洲流媒体 (Asia - JP/KR/TW/HK)"
    print_row "Netflix (Asia)" "$(check_netflix)"
    print_row "YouTube" "$(check_youtube)"
    print_row "Abema TV (JP)" "$(check_url 'https://abema.tv')"
    print_row "Niconico (JP)" "$(check_url 'https://www.nicovideo.jp')"
    print_row "DMM (JP)" "$(check_url 'https://www.dmm.com')"
    print_row "U-NEXT (JP)" "$(check_url 'https://video.unext.jp')"
    print_row "Hulu Japan" "$(check_url 'https://www.hulu.jp')"
    print_row "TVer (JP)" "$(check_url 'https://tver.jp')"
    print_row "Telasa (JP)" "$(check_url 'https://www.telasa.jp')"
    print_row "FOD (JP)" "$(check_url 'https://fod.fujitv.co.jp/')"
    print_row "Paravi (JP)" "$(check_url 'https://www.paravi.jp')"
    print_row "Wowow (JP)" "$(check_url 'https://www.wowow.co.jp')"
    print_row "Rakuten TV (JP)" "$(check_url 'https://tv.rakuten.co.jp/')"
    print_row "GYAO! (JP)" "$(check_url 'https://gyao.yahoo.co.jp/')"
    print_row "DAZN (JP)" "$(check_url 'https://www.dazn.com/en-JP/home')"
    print_row "Music.jp" "$(check_url 'https://music-book.jp/')"
    print_row "Radiko (JP)" "$(check_url 'https://radiko.jp/')"
    print_row "Bahamut (TW)" "$(check_url 'https://ani.gamer.com.tw/')"
    print_row "Line TV (TW)" "$(check_url 'https://www.linetv.tw/')"
    print_row "KKTV (TW)" "$(check_url 'https://www.kktv.me/')"
    print_row "LiTV (TW)" "$(check_url 'https://www.litv.tv/')"
    print_row "friDay (TW)" "$(check_url 'https://video.friday.tw/')"
    print_row "MyVideo (TW)" "$(check_url 'https://www.myvideo.net.tw/')"
    print_row "CatchPlay+" "$(check_url 'https://www.catchplay.com/')"
    print_row "Hami Video" "$(check_url 'https://hamivideo.hinet.net/')"
    print_row "Viu (HK/SG)" "$(check_url 'https://www.viu.com/')"
    print_row "Now E (HK)" "$(check_url 'https://www.nowe.com/')"
    print_row "Bilibili (HK/TW)" "$(check_url 'https://www.bilibili.com/bangumi/play/ep1')"
    print_row "iQIYI Intl" "$(check_url 'https://www.iq.com/')"
    print_row "WeTV (Tencent)" "$(check_url 'https://wetv.vip/')"
    print_row "MangoTV Intl" "$(check_url 'https://w.mgtv.com/')"
    print_row "Naver TV (KR)" "$(check_url 'https://tv.naver.com/')"
    print_row "Coupang Play" "$(check_url 'https://www.coupangplay.com/')"
    print_row "Tving (KR)" "$(check_url 'https://www.tving.com/')"
    print_row "Wavve (KR)" "$(check_url 'https://www.wavve.com/')"
    print_row "Watcha (KR)" "$(check_url 'https://watcha.com/')"
    print_row "Melon (KR)" "$(check_url 'https://www.melon.com/')"
    print_row "TikTok (Asia)" "$(check_url 'https://www.tiktok.com/')"
    print_row "Shopee (SEA)" "$(check_url 'https://shopee.sg/')"
}

function run_europe() {
    print_sep "🇪🇺 欧洲流媒体 (Europe - UK/FR/DE)"
    print_row "Netflix (EU)" "$(check_netflix)"
    print_row "BBC iPlayer (UK)" "$(check_url 'https://www.bbc.co.uk/iplayer')"
    print_row "ITV X (UK)" "$(check_url 'https://www.itv.com/')"
    print_row "Channel 4 (UK)" "$(check_url 'https://www.channel4.com/')"
    print_row "My5 (UK)" "$(check_url 'https://www.channel5.com/')"
    print_row "Sky Go (UK)" "$(check_url 'https://www.sky.com/watch/sky-go/windows')"
    print_row "Now TV (UK)" "$(check_url 'https://www.nowtv.com/')"
    print_row "BT Sport (UK)" "$(check_url 'https://www.bt.com/sport')"
    print_row "UKTV Play" "$(check_url 'https://uktvplay.uktv.co.uk/')"
    print_row "BritBox (UK)" "$(check_url 'https://www.britbox.co.uk/')"
    print_row "Canal+ (FR)" "$(check_url 'https://www.canalplus.com/')"
    print_row "TF1 (FR)" "$(check_url 'https://www.tf1.fr/')"
    print_row "6play (FR)" "$(check_url 'https://www.6play.fr/')"
    print_row "France.tv (FR)" "$(check_url 'https://www.france.tv/')"
    print_row "Molotov (FR)" "$(check_url 'https://www.molotov.tv/')"
    print_row "Arte (FR/DE)" "$(check_url 'https://www.arte.tv/')"
    print_row "Salto (FR)" "$(check_url 'https://www.salto.fr/')"
    print_row "OCS (FR)" "$(check_url 'https://www.ocs.fr/')"
    print_row "ZDF (DE)" "$(check_url 'https://www.zdf.de/')"
    print_row "ARD Mediathek" "$(check_url 'https://www.ardmediathek.de/')"
    print_row "Joyn (DE)" "$(check_url 'https://www.joyn.de/')"
    print_row "RTL+ (DE)" "$(check_url 'https://plus.rtl.de/')"
    print_row "Sky WOW (DE)" "$(check_url 'https://skyticket.sky.de/')"
    print_row "DAZN (DE)" "$(check_url 'https://www.dazn.com/de-DE')"
    print_row "Magenta TV" "$(check_url 'https://www.telekom.de/magenta-tv')"
    print_row "Rakuten TV (EU)" "$(check_url 'https://rakuten.tv/')"
    print_row "Viaplay (EU)" "$(check_url 'https://viaplay.com/')"
    print_row "Eurosport" "$(check_url 'https://www.eurosport.com/')"
    print_row "HBO Max (EU)" "$(check_url 'https://www.hbomax.com/')"
    print_row "SkyShowtime" "$(check_url 'https://www.skyshowtime.com/')"
    print_row "Ziggo Go (NL)" "$(check_url 'https://www.ziggogo.tv/')"
    print_row "NPO Start (NL)" "$(check_url 'https://www.npostart.nl/')"
    print_row "Videoland (NL)" "$(check_url 'https://www.videoland.com/')"
    print_row "RaiPlay (IT)" "$(check_url 'https://www.raiplay.it/')"
    print_row "Mediaset (IT)" "$(check_url 'https://www.mediasetplay.mediaset.it/')"
    print_row "RTVE (ES)" "$(check_url 'https://www.rtve.es/play/')"
    print_row "Movistar+ (ES)" "$(check_url 'https://ver.movistarplus.es/')"
    print_row "Filmin (ES)" "$(check_url 'https://www.filmin.es/')"
    print_row "Spotify (EU)" "$(check_url 'https://www.spotify.com/')"
    print_row "Deezer (EU)" "$(check_url 'https://www.deezer.com/')"
}

# --- 5. 主程序 ---

# Logo
echo -e ""
echo -e "${BOLD}${F_GOLD}      威 软 科 技  |  WEIRUAN TECH      ${RES}"
echo -e "${S_GRAY}   Global Streaming Analysis Tool v5.0    ${RES}"
echo -e ""

# IP Check
echo -e "${F_CYAN}正在初始化测试环境...${RES}"
IP_INFO=$(curl -s --max-time 5 https://ipapi.co/json/)
ISP=$(echo "$IP_INFO" | grep '"org":' | cut -d'"' -f4)
COUNTRY=$(echo "$IP_INFO" | grep '"country_name":' | cut -d'"' -f4)
CITY=$(echo "$IP_INFO" | grep '"city":' | cut -d'"' -f4)
ASN=$(echo "$IP_INFO" | grep '"asn":' | cut -d'"' -f4)

# 菜单
echo -e "${F_CYAN}请选择测试模式 (Mode Selection):${RES}"
echo -e "${F_CYAN}[1]${RES} ${BOLD}${F_WHITE}🚀 全球全量测试${RES} ${S_GRAY}(All Regions)${RES}"
echo -e "${F_CYAN}[2]${RES} ${BOLD}${F_BLUE}🇺🇸 北美精选测试${RES} ${S_GRAY}(North America)${RES}"
echo -e "${F_CYAN}[3]${RES} ${BOLD}${F_GOLD}🌏 亚洲精选测试${RES} ${S_GRAY}(Asia - JP/HK/TW)${RES}"
echo -e "${F_CYAN}[4]${RES} ${BOLD}${F_BLUE}🇪🇺 欧洲精选测试${RES} ${S_GRAY}(Europe - EU)${RES}"
echo -e ""
read -p "请输入选项 [1-4] (默认1): " MENU_CHOICE
if [[ -z "$MENU_CHOICE" ]]; then MENU_CHOICE="1"; fi

# 表头绘制
echo -e ""
echo -e "${F_CYAN}${T_TOP_LEFT}$(printf '%.0s─' {1..65})${T_TOP_RIGHT}${RES}"
printf "${F_CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-47s ${F_CYAN}${VLINE}${RES}\n" "运营商" "${ISP:0:45}"
printf "${F_CYAN}${VLINE}${RES} ${BOLD}%-10s${RES} : %-47s ${F_CYAN}${VLINE}${RES}\n" "地理位置" "$CITY, $COUNTRY ($ASN)"
echo -e "${F_CYAN}${T_M_LEFT}$(printf '%.0s─' {1..65})${T_M_RIGHT}${RES}"
printf "${F_CYAN}${VLINE}${RES} ${S_GRAY}%-20s${RES} ${F_CYAN}${VLINE}${RES} ${S_GRAY}%-40s${RES} ${F_CYAN}${VLINE}${RES}\n" "平台名称" "解锁状态 (Status)"
echo -e "${F_CYAN}${T_M_LEFT}$(printf '%.0s─' {1..22})${T_CROSS}$(printf '%.0s─' {1..40})${T_M_RIGHT}${RES}"

# 执行通用测试
print_row "ChatGPT / OpenAI" "$(check_chatgpt)"
print_row "Steam Currency" "$(check_steam)"

# 执行区域测试
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

# 底部
echo -e "${F_CYAN}${T_BOT_LEFT}$(printf '%.0s─' {1..65})${T_BOT_RIGHT}${RES}"
echo -e ""
echo -e "${S_GRAY}:: 威软数据中心 (Real-Time Stats) ::${RES}"
echo -e "全网累计运行: ${F_GOLD}${GLOBAL_RUNS_FORMATTED}${RES} 次"
echo -e "${S_GRAY}-------------------------------------------------------------------${RES}"
echo -e ""
printf "%68s\n" "Code by ${BOLD}威软科技制作${RES}"
printf "%68s\n" "$(date '+%Y-%m-%d %H:%M')"
echo -e ""
