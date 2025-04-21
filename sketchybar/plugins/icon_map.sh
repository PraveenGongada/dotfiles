#!/usr/bin/env bash

# Create a cache directory if it doesn't exist
CACHE_DIR="$HOME/.cache/sketchybar"
mkdir -p "$CACHE_DIR"

# Cache file for icon mappings
ICON_CACHE="$CACHE_DIR/icon_cache.txt"

# Create the cache file if it doesn't exist
if [ ! -f "$ICON_CACHE" ]; then
  touch "$ICON_CACHE"
fi

# Check if the app is already in cache
APP_NAME="$1"
CACHED_ICON=$(grep "^$APP_NAME|" "$ICON_CACHE" | cut -d '|' -f2)

if [ -n "$CACHED_ICON" ]; then
  # Cache hit, return the icon
  echo "$CACHED_ICON"
  exit 0
fi

### START-OF-ICON-MAP
function __icon_map() {
  case "$1" in
  "Live")
    icon_result=":ableton:"
    ;;
  "Activity Monitor")
    icon_result=":activity_monitor:"
    ;;
  "Adobe Bridge"*)
    icon_result=":adobe_bridge:"
    ;;
  "Affinity Designer")
    icon_result=":affinity_designer:"
    ;;
  "Affinity Designer 2")
    icon_result=":affinity_designer_2:"
    ;;
  "Affinity Photo")
    icon_result=":affinity_photo:"
    ;;
  "Affinity Photo 2")
    icon_result=":affinity_photo_2:"
    ;;
  "Affinity Publisher")
    icon_result=":affinity_publisher:"
    ;;
  "Affinity Publisher 2")
    icon_result=":affinity_publisher_2:"
    ;;
  "Airmail")
    icon_result=":airmail:"
    ;;
  "Alacritty")
    icon_result=":alacritty:"
    ;;
  "Alfred")
    icon_result=":alfred:"
    ;;
  "Android Messages")
    icon_result=":android_messages:"
    ;;
  "Android Studio")
    icon_result=":android_studio:"
    ;;
  "Anki")
    icon_result=":anki:"
    ;;
  "Anytype")
    icon_result=":anytype:"
    ;;
  "App Eraser")
    icon_result=":app_eraser:"
    ;;
  "App Store")
    icon_result=":app_store:"
    ;;
  "Arc")
    icon_result=":arc:"
    ;;
  "Arduino" | "Arduino IDE")
    icon_result=":arduino:"
    ;;
  "Atom")
    icon_result=":atom:"
    ;;
  "Audacity")
    icon_result=":audacity:"
    ;;
  "Bambu Studio")
    icon_result=":bambu_studio:"
    ;;
  "MoneyMoney")
    icon_result=":bank:"
    ;;
  "Battle.net")
    icon_result=":battle_net:"
    ;;
  "Bear")
    icon_result=":bear:"
    ;;
  "BetterTouchTool")
    icon_result=":bettertouchtool:"
    ;;
  "Bilibili" | "哔哩哔哩")
    icon_result=":bilibili:"
    ;;
  "Bitwarden")
    icon_result=":bit_warden:"
    ;;
  "Blender")
    icon_result=":blender:"
    ;;
  "BluOS Controller")
    icon_result=":bluos_controller:"
    ;;
  "Calibre")
    icon_result=":book:"
    ;;
  "Brave Browser")
    icon_result=":brave_browser:"
    ;;
  "BusyCal")
    icon_result=":busycal:"
    ;;
  "Calculator" | "Calculette")
    icon_result=":calculator:"
    ;;
  "Calendar" | "日历" | "Fantastical" | "Cron" | "Amie" | "Calendrier" | "カレンダー" | "Notion Calendar")
    icon_result=":calendar:"
    ;;
  "calibre")
    icon_result=":calibre:"
    ;;
  "Caprine")
    icon_result=":caprine:"
    ;;
  "Amazon Chime")
    icon_result=":chime:"
    ;;
  "Citrix Workspace" | "Citrix Viewer")
    icon_result=":citrix:"
    ;;
  "Claude")
    icon_result=":claude:"
    ;;
  "ClickUp")
    icon_result=":click_up:"
    ;;
  "Code" | "Code - Insiders")
    icon_result=":code:"
    ;;
  "Cold Turkey Blocker")
    icon_result=":cold_turkey_blocker:"
    ;;
  "Color Picker" | "数码测色计")
    icon_result=":color_picker:"
    ;;
  "Copilot")
    icon_result=":copilot:"
    ;;
  "CotEditor")
    icon_result=":coteditor:"
    ;;
  "Creative Cloud")
    icon_result=":creative_cloud:"
    ;;
  "Cursor")
    icon_result=":cursor:"
    ;;
  "Cypress")
    icon_result=":cypress:"
    ;;
  "DataGrip")
    icon_result=":datagrip:"
    ;;
  "DataSpell")
    icon_result=":dataspell:"
    ;;
  "DaVinci Resolve")
    icon_result=":davinciresolve:"
    ;;
  "DBeaver")
    icon_result=":dbeaver:"
    ;;
  "Deezer")
    icon_result=":deezer:"
    ;;
  "Default")
    icon_result=":default:"
    ;;
  "CleanMyMac X")
    icon_result=":desktop:"
    ;;
  "DEVONthink 3")
    icon_result=":devonthink3:"
    ;;
  "DingTalk" | "钉钉" | "阿里钉")
    icon_result=":dingtalk:"
    ;;
  "Discord" | "Discord Canary" | "Discord PTB")
    icon_result=":discord:"
    ;;
  "Docker" | "Docker Desktop")
    icon_result=":docker:"
    ;;
  "GrandTotal" | "Receipts")
    icon_result=":dollar:"
    ;;
  "Double Commander")
    icon_result=":doublecmd:"
    ;;
  "Drafts")
    icon_result=":drafts:"
    ;;
  "draw.io")
    icon_result=":draw_io:"
    ;;
  "Dropbox")
    icon_result=":dropbox:"
    ;;
  "Element")
    icon_result=":element:"
    ;;
  "Emacs")
    icon_result=":emacs:"
    ;;
  "Evernote Legacy")
    icon_result=":evernote_legacy:"
    ;;
  "FaceTime" | "FaceTime 通话")
    icon_result=":face_time:"
    ;;
  "Figma")
    icon_result=":figma:"
    ;;
  "Final Cut Pro")
    icon_result=":final_cut_pro:"
    ;;
  "Finder" | "访达")
    icon_result=":finder:"
    ;;
  "Firefox")
    icon_result=":firefox:"
    ;;
  "Firefox Developer Edition" | "Firefox Nightly")
    icon_result=":firefox_developer_edition:"
    ;;
  "Folx")
    icon_result=":folx:"
    ;;
  "Fork")
    icon_result=":fork:"
    ;;
  "Freeform")
    icon_result=":freeform:"
    ;;
  "FreeTube")
    icon_result=":freetube:"
    ;;
  "Fusion")
    icon_result=":fusion:"
    ;;
  "System Preferences" | "System Settings" | "系统设置" | "Réglages Système" | "システム設定")
    icon_result=":gear:"
    ;;
  "Ghostty")
    icon_result=":ghostty:"
    ;;
  "GitHub Desktop")
    icon_result=":git_hub:"
    ;;
  "Godot")
    icon_result=":godot:"
    ;;
  "GoLand")
    icon_result=":goland:"
    ;;
  "Chromium" | "Google Chrome" | "Google Chrome Canary")
    icon_result=":google_chrome:"
    ;;
  "Grammarly Editor")
    icon_result=":grammarly:"
    ;;
  "Home Assistant")
    icon_result=":home_assistant:"
    ;;
  "Hyper")
    icon_result=":hyper:"
    ;;
  "IntelliJ IDEA")
    icon_result=":idea:"
    ;;
  "IINA")
    icon_result=":iina:"
    ;;
  "Adobe Illustrator"* | "Illustrator")
    icon_result=":illustrator:"
    ;;
  "Adobe InDesign"* | "InDesign")
    icon_result=":indesign:"
    ;;
  "Infuse")
    icon_result=":infuse:"
    ;;
  "Inkdrop")
    icon_result=":inkdrop:"
    ;;
  "Inkscape")
    icon_result=":inkscape:"
    ;;
  "Insomnia")
    icon_result=":insomnia:"
    ;;
  "iPhone Mirroring")
    icon_result=":iphone_mirroring:"
    ;;
  "Iris")
    icon_result=":iris:"
    ;;
  "iTerm" | "iTerm2")
    icon_result=":iterm:"
    ;;
  "Jellyfin Media Player")
    icon_result=":jellyfin:"
    ;;
  "Joplin")
    icon_result=":joplin:"
    ;;
  "카카오톡" | "KakaoTalk")
    icon_result=":kakaotalk:"
    ;;
  "Kakoune")
    icon_result=":kakoune:"
    ;;
  "KeePassXC")
    icon_result=":kee_pass_x_c:"
    ;;
  "Keyboard Maestro")
    icon_result=":keyboard_maestro:"
    ;;
  "Keynote" | "Keynote 讲演")
    icon_result=":keynote:"
    ;;
  "kitty")
    icon_result=":kitty:"
    ;;
  "Kodi")
    icon_result=":kodi:"
    ;;
  "LanguageTool for Desktop")
    icon_result=":languagetool_for_desktop:"
    ;;
  "League of Legends")
    icon_result=":league_of_legends:"
    ;;
  "LibreWolf")
    icon_result=":libre_wolf:"
    ;;
  "Adobe Lightroom")
    icon_result=":lightroom:"
    ;;
  "Lightroom Classic")
    icon_result=":lightroomclassic:"
    ;;
  "LINE")
    icon_result=":line:"
    ;;
  "Linear")
    icon_result=":linear:"
    ;;
  "LM Studio")
    icon_result=":lm_studio:"
    ;;
  "LocalSend")
    icon_result=":localsend:"
    ;;
  "Logic Pro")
    icon_result=":logicpro:"
    ;;
  "Logseq")
    icon_result=":logseq:"
    ;;
  "Canary Mail" | "HEY" | "Mail" | "Mailspring" | "MailMate" | "Superhuman" | "Spark" | "邮件" | "メール")
    icon_result=":mail:"
    ;;
  "MAMP" | "MAMP PRO")
    icon_result=":mamp:"
    ;;
  "Maps" | "Google Maps" | "マップ")
    icon_result=":maps:"
    ;;
  "Marta")
    icon_result=":marta:"
    ;;
  "Matlab")
    icon_result=":matlab:"
    ;;
  "Mattermost")
    icon_result=":mattermost:"
    ;;
  "Messages" | "信息" | "Nachrichten" | "メッセージ")
    icon_result=":messages:"
    ;;
  "Messenger")
    icon_result=":messenger:"
    ;;
  "Microsoft Edge")
    icon_result=":microsoft_edge:"
    ;;
  "Microsoft Excel")
    icon_result=":microsoft_excel:"
    ;;
  "Microsoft Outlook")
    icon_result=":microsoft_outlook:"
    ;;
  "Microsoft PowerPoint")
    icon_result=":microsoft_power_point:"
    ;;
  "Microsoft Remote Desktop")
    icon_result=":microsoft_remote_desktop:"
    ;;
  "Microsoft Teams" | "Microsoft Teams (work or school)")
    icon_result=":microsoft_teams:"
    ;;
  "Microsoft Word")
    icon_result=":microsoft_word:"
    ;;
  "Min")
    icon_result=":min_browser:"
    ;;
  "Miro")
    icon_result=":miro:"
    ;;
  "MongoDB Compass"*)
    icon_result=":mongodb:"
    ;;
  "Moonlight")
    icon_result=":moonlight:"
    ;;
  "mpv")
    icon_result=":mpv:"
    ;;
  "Mullvad Browser")
    icon_result=":mullvad_browser:"
    ;;
  "Music" | "音乐" | "Musique" | "ミュージック")
    icon_result=":music:"
    ;;
  "Neovide" | "neovide")
    icon_result=":neovide:"
    ;;
  "Neovim" | "neovim" | "nvim")
    icon_result=":neovim:"
    ;;
  "网易云音乐")
    icon_result=":netease_music:"
    ;;
  "Noodl" | "Noodl Editor")
    icon_result=":noodl:"
    ;;
  "NordVPN")
    icon_result=":nord_vpn:"
    ;;
  "Notability")
    icon_result=":notability:"
    ;;
  "Notes" | "备忘录" | "メモ")
    icon_result=":notes:"
    ;;
  "Notion")
    icon_result=":notion:"
    ;;
  "Nova")
    icon_result=":nova:"
    ;;
  "Numbers" | "Numbers 表格")
    icon_result=":numbers:"
    ;;
  "Obsidian")
    icon_result=":obsidian:"
    ;;
  "OBS")
    icon_result=":obsstudio:"
    ;;
  "OmniFocus")
    icon_result=":omni_focus:"
    ;;
  "1Password")
    icon_result=":one_password:"
    ;;
  "Open Video Downloader")
    icon_result=":open_video_downloader:"
    ;;
  "ChatGPT")
    icon_result=":openai:"
    ;;
  "OpenAI Translator")
    icon_result=":openai_translator:"
    ;;
  "OpenVPN Connect")
    icon_result=":openvpn_connect:"
    ;;
  "Opera")
    icon_result=":opera:"
    ;;
  "OrbStack")
    icon_result=":orbstack:"
    ;;
  "OrcaSlicer")
    icon_result=":orcaslicer:"
    ;;
  "Orion" | "Orion RC")
    icon_result=":orion:"
    ;;
  "Pages" | "Pages 文稿")
    icon_result=":pages:"
    ;;
  "Parallels Desktop")
    icon_result=":parallels:"
    ;;
  "Parsec")
    icon_result=":parsec:"
    ;;
  "Passwords")
    icon_result=":passwords:"
    ;;
  "Preview" | "预览" | "Skim" | "zathura" | "Aperçu" | "プレビュー")
    icon_result=":pdf:"
    ;;
  "PDF Expert")
    icon_result=":pdf_expert:"
    ;;
  "Pearcleaner")
    icon_result=":pearcleaner:"
    ;;
  "Phoenix Slides")
    icon_result=":phoenix_slides:"
    ;;
  "Photos")
    icon_result=":photos:"
    ;;
  "Adobe Photoshop"*)
    icon_result=":photoshop:"
    ;;
  "PhpStorm")
    icon_result=":php_storm:"
    ;;
  "Pi-hole Remote")
    icon_result=":pihole:"
    ;;
  "Pine")
    icon_result=":pine:"
    ;;
  "Plex")
    icon_result=":plex:"
    ;;
  "Plexamp")
    icon_result=":plexamp:"
    ;;
  "Podcasts" | "播客")
    icon_result=":podcasts:"
    ;;
  "PomoDone App")
    icon_result=":pomodone:"
    ;;
  "Postman")
    icon_result=":postman:"
    ;;
  "Proton Mail" | "Proton Mail Bridge")
    icon_result=":proton_mail:"
    ;;
  "Proton VPN" | "ProtonVPN")
    icon_result=":proton_vpn:"
    ;;
  "PrusaSlicer" | "SuperSlicer")
    icon_result=":prusaslicer:"
    ;;
  "PyCharm")
    icon_result=":pycharm:"
    ;;
  "QQ")
    icon_result=":qq:"
    ;;
  "QQ音乐" | "QQMusic")
    icon_result=":qqmusic:"
    ;;
  "Quantumult X")
    icon_result=":quantumult_x:"
    ;;
  "qutebrowser")
    icon_result=":qute_browser:"
    ;;
  "Raindrop.io")
    icon_result=":raindrop_io:"
    ;;
  "Reeder")
    icon_result=":reeder5:"
    ;;
  "Reminders" | "提醒事项" | "Rappels" | "リマインダー")
    icon_result=":reminders:"
    ;;
  "Replit")
    icon_result=":replit:"
    ;;
  "Repo Prompt")
    icon_result=":repo_prompt:"
    ;;
  "Rider" | "JetBrains Rider")
    icon_result=":rider:"
    ;;
  "Rio")
    icon_result=":rio:"
    ;;
  "Royal TSX")
    icon_result=":royaltsx:"
    ;;
  "RustDesk")
    icon_result=":rustdesk:"
    ;;
  "Safari" | "Safari浏览器" | "Safari Technology Preview")
    icon_result=":safari:"
    ;;
  "Sequel Ace")
    icon_result=":sequel_ace:"
    ;;
  "Sequel Pro")
    icon_result=":sequel_pro:"
    ;;
  "Session")
    icon_result=":session:"
    ;;
  "Setapp")
    icon_result=":setapp:"
    ;;
  "SF Symbols")
    icon_result=":sf_symbols:"
    ;;
  "Signal")
    icon_result=":signal:"
    ;;
  "sioyek")
    icon_result=":sioyek:"
    ;;
  "Sketch")
    icon_result=":sketch:"
    ;;
  "Skype")
    icon_result=":skype:"
    ;;
  "Slack")
    icon_result=":slack:"
    ;;
  "Spark Desktop")
    icon_result=":spark:"
    ;;
  "Spotify")
    icon_result=":spotify:"
    ;;
  "Spotlight")
    icon_result=":spotlight:"
    ;;
  "Studio 3T")
    icon_result=":studio_3t:"
    ;;
  "Sublime Text")
    icon_result=":sublime_text:"
    ;;
  "superProductivity")
    icon_result=":superproductivity:"
    ;;
  "Surfshark")
    icon_result=":surfshark:"
    ;;
  "Tabby")
    icon_result=":tabby:"
    ;;
  "TablePlus")
    icon_result=":tableplus:"
    ;;
  "Tana")
    icon_result=":tana:"
    ;;
  "TeamSpeak 3")
    icon_result=":team_speak:"
    ;;
  "Telegram")
    icon_result=":telegram:"
    ;;
  "Terminal" | "终端" | "ターミナル")
    icon_result=":terminal:"
    ;;
  "Typora")
    icon_result=":text:"
    ;;
  "TextEdit")
    icon_result=":textedit:"
    ;;
  "Microsoft To Do" | "Things")
    icon_result=":things:"
    ;;
  "Thunderbird")
    icon_result=":thunderbird:"
    ;;
  "TickTick")
    icon_result=":tick_tick:"
    ;;
  "TIDAL")
    icon_result=":tidal:"
    ;;
  "Tiny RDM")
    icon_result=":tinyrdm:"
    ;;
  "Todoist")
    icon_result=":todoist:"
    ;;
  "Toggl Track")
    icon_result=":toggl_track:"
    ;;
  "Tor Browser")
    icon_result=":tor_browser:"
    ;;
  "Tower")
    icon_result=":tower:"
    ;;
  "Transmit")
    icon_result=":transmit:"
    ;;
  "Trello")
    icon_result=":trello:"
    ;;
  "Tweetbot" | "Twitter")
    icon_result=":twitter:"
    ;;
  "UTM")
    icon_result=":utm:"
    ;;
  "MacVim" | "Vim" | "VimR")
    icon_result=":vim:"
    ;;
  "Vivaldi")
    icon_result=":vivaldi:"
    ;;
  "VLC")
    icon_result=":vlc:"
    ;;
  "VMware Fusion")
    icon_result=":vmware_fusion:"
    ;;
  "VSCodium")
    icon_result=":vscodium:"
    ;;
  "Warp")
    icon_result=":warp:"
    ;;
  "Weather")
    icon_result=":weather:"
    ;;
  "WebStorm")
    icon_result=":web_storm:"
    ;;
  "微信" | "WeChat")
    icon_result=":wechat:"
    ;;
  "企业微信" | "WeCom")
    icon_result=":wecom:"
    ;;
  "WezTerm")
    icon_result=":wezterm:"
    ;;
  "WhatsApp" | "‎WhatsApp")
    icon_result=":whats_app:"
    ;;
  "Xcode")
    icon_result=":xcode:"
    ;;
  "Yandex Browser" | "Yandex Browser" | "Yandex")
    icon_result=":yandex_bower:"
    ;;
  "Yandex Music")
    icon_result=":yandex_music:"
    ;;
  "Yuque" | "语雀")
    icon_result=":yuque:"
    ;;
  "Zed")
    icon_result=":zed:"
    ;;
  "Zen Browser")
    icon_result=":zen_browser:"
    ;;
  "Zeplin")
    icon_result=":zeplin:"
    ;;
  "zoom.us")
    icon_result=":zoom:"
    ;;
  "Zotero")
    icon_result=":zotero:"
    ;;
  "Zulip")
    icon_result=":zulip:"
    ;;
  *)
    icon_result=":default:"
    ;;
  esac
}
### END-OF-ICON-MAP

__icon_map "$APP_NAME"

if [ -n "$icon_result" ]; then
  echo "$APP_NAME|$icon_result" >>"$ICON_CACHE"
fi

echo "$icon_result"
