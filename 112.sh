#!/usr/bin/env bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export LANG=en_US.UTF-8

red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}
rred(){ echo -e "\033[35m\033[01m$1\033[0m";}
readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}
readp(){ read -p "$(yellow "$1")" $2;}

[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit 1
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。请向作者反馈 https://github.com/kkkyg/CFwarp/issues" && rm -f CFwarp.sh && exit 1
fi
vsid=`grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1`
[[ $release = Centos && ${vsid} -lt 7 ]] && red "当前系统版本号：Centos $vsid \n不支持 Centos 7 以下系统 " && exit 1
[[ $release = Ubuntu && ${vsid} -lt 18 ]] && red "当前系统版本号：Ubuntu $vsid \n不支持 Ubuntu 18 以下系统 " && exit 1
[[ $release = Debian && ${vsid} -lt 10 ]] && red "当前系统版本号：Debian $vsid \n不支持 Debian 10 以下系统 " && exit 1

sys(){
[ -f /etc/os-release ] && grep -i pretty_name /etc/os-release | cut -d \" -f2 && return
[ -f /etc/lsb-release ] && grep -i description /etc/lsb-release | cut -d \" -f2 && return
[ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return;}
op=`sys`
version=`uname -r | awk -F "-" '{print $1}'`
main=`uname  -r | awk -F . '{print $1 }'`
minor=`uname -r | awk -F . '{print $2}'`
uname -m | grep -q -E -i "aarch" && cpu=ARM64 || cpu=AMD64
vi=`systemd-detect-virt`
if [[ $vi = openvz ]]; then
yellow "正在检测openvz架构的vps是否开启TUN………"&& sleep 2
TUN=$(cat /dev/net/tun 2>&1)
[[ ${TUN} = "cat: /dev/net/tun: File descriptor in bad state" ]] && green "检测完毕：已开启TUN，支持安装wireguard-go模式的WARP，继续……" || (red "检测完毕：未开启TUN，不支持安装WARP(+)，请与VPS厂商沟通或后台设置以开启TUN" && exit 1)
fi
[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
[[ $(type -P curl) ]] || (yellow "检测到curl未安装，升级安装中" && $yumapt update;$yumapt install curl)
 
ud4='sed -i "5 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf && sed -i "6 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf'
ud6='sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf && sed -i "8 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf'
ud4ud6='sed -i "5 s/^/PostUp = ip -4 rule add from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf && sed -i "6 s/^/PostDown = ip -4 rule delete from $(ip route get 162.159.192.1 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf && sed -i "7 s/^/PostUp = ip -6 rule add from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf && sed -i "8 s/^/PostDown = ip -6 rule delete from $(ip route get 2606:4700:d0::a29f:c001 | grep -oP '"'src \K\S+') lookup main\n/"'" wgcf-profile.conf'
c1="sed -i '/0\.0\.0\.0\/0/d' wgcf-profile.conf"
c2="sed -i '/\:\:\/0/d' wgcf-profile.conf"
c3="sed -i 's/engage.cloudflareclient.com/162.159.192.1/g' wgcf-profile.conf"
c4="sed -i 's/engage.cloudflareclient.com/2606:4700:d0::a29f:c001/g' wgcf-profile.conf"
c5="sed -i 's/1.1.1.1/8.8.8.8,2001:4860:4860::8888/g' wgcf-profile.conf"
c6="sed -i 's/1.1.1.1/2001:4860:4860::8888,8.8.8.8/g' wgcf-profile.conf"
yellow " 请稍等3秒……正在扫描vps类型及参数中……"

ShowWGCF(){
v6=$(curl -s6m5 https://ip.gs -k)
v4=$(curl -s4m5 https://ip.gs -k)
isp4=`curl -s https://api.ip.sb/geoip/$v4 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
isp6=`curl -s https://api.ip.sb/geoip/$v6 -k | awk -F "isp" '{print $2}' | awk -F "offset" '{print $1}' | sed "s/[,\":]//g"`
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
[[ -e /etc/wireguard/wgcf+p.log ]] && cfplus="WARP+普通账户(有限WARP+流量)，设备名称：$(grep -s 'Device name' /etc/wireguard/wgcf+p.log | awk '{ print $NF }')" || cfplus="WARP+Teams账户(无限WARP+流量)"
AE="阿联酋（United Arab Emirates）";AU="澳大利亚（Australia）";BG="保加利亚（Bulgaria）";BR="巴西（Brazil）";CA="加拿大（Canada）";CH="瑞士（Switzerland）";CL="智利（Chile)";CN="中国（China）";CO="哥伦比亚（Colombia）";DE="德国（Germany)";ES="西班牙（Spain)";FI="芬兰（Finland）";FR="法国（France）";HK="香港（Hong Kong）";ID="印度尼西亚（Indonesia）";IE="爱尔兰（Ireland）";IL="以色列（Israel）";IN="印度（India）";IT="意大利（Italy）";JP="日本（Japan）";KR="韩国（South Korea）";LU="卢森堡（Luxembourg）";MX="墨西哥（Mexico）";MY="马来西亚（Malaysia）";NL="荷兰（Netherlands）";NZ="新西兰（New Zealand）";PH="菲律宾（Philippines）";RO="罗马尼亚（Romania）";RU="俄罗斯（Russian）";SA="沙特（Saudi Arabia）";SE="瑞典（Sweden）";SG="新加坡（Singapore）";TW="台湾（Taiwan）";UK="英国（United Kingdom）";US="美国（United States）";VN="越南（Vietnam）";ZA="南非（South Africa）"
if [[ -n $v4 ]]; then
result4=$(curl -4 --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
[[ "$result4" == "404" ]] && NF="遗憾哦，当前IP仅解锁奈飞Netflix自制剧..."
[[ "$result4" == "403" ]] && NF="死心了，当前IP不支持解锁奈飞Netflix....."
[[ "$result4" == "000" ]] && NF="检测到网络有问题，再次进入脚本可能就好了.."
[[ "$result4" == "200" ]] && NF="恭喜呀，当前IP可解锁奈飞Netflix流媒体..."
g4=$(eval echo \$$(curl -s https://api.ip.sb/geoip/$v4 -k | awk -F "country_code" '{print $2}' | awk -F "region_code" '{print $1}' | sed "s/[,\":}]//g"))
wgcfv4=$(curl -s4 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
case ${wgcfv4} in 
plus) 
WARPIPv4Status=$(white "IPV4 WARP+状态：\c" ; rred "运行中，$cfplus" ; white " [ Cloudflare服务商 ]获取IPV4：\c" ; rred "$v4" ; white " IPV4 奈飞NF解锁情况：\c" ; rred "$NF  \c"; white " IPV4 所在地区：\c" ; rred "$g4");;  
on) 
WARPIPv4Status=$(white "IPV4 WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " [ Cloudflare服务商 ]获取IPV4：\c" ; green "$v4" ; white " IPV4 奈飞NF解锁情况：\c" ; green "$NF  \c"; white " IPV4 所在地区：\c" ; green "$g4");;
off) 
WARPIPv4Status=$(white "IPV4 WARP状态：\c" ; yellow "关闭中" ; white " [ $isp4服务商 ]获取IPV4：\c" ; yellow "$v4" ; white " IPV4 奈飞NF解锁情况：\c" ; yellow "$NF  \c"; white " IPV4 所在地区：\c" ; yellow "$g4");; 
esac 
else
WARPIPv4Status=$(white "IPV4 状态：\c" ; red "不存在IPV4地址 ")
fi 
if [[ -n $v6 ]]; then
result6=$(curl -6 --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
[[ "$result6" == "404" ]] && NF="遗憾哦，当前IP仅解锁奈飞Netflix自制剧..."
[[ "$result6" == "403" ]] && NF="死心了，当前IP不支持解锁奈飞Netflix....."
[[ "$result6" == "000" ]] && NF="检测到网络有问题，再次进入脚本可能就好了.."
[[ "$result6" == "200" ]] && NF="恭喜呀，当前IP可解锁奈飞Netflix流媒体..."
g6=$(eval echo \$$(curl -s https://api.ip.sb/geoip/$v6 -k | awk -F "country_code" '{print $2}' | awk -F "region_code" '{print $1}' | sed "s/[,\":}]//g"))
wgcfv6=$(curl -s6 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2) 
case ${wgcfv6} in 
plus) 
WARPIPv6Status=$(white "IPV6 WARP+状态：\c" ; rred "运行中，$cfplus" ; white " [ Cloudflare服务商 ]获取IPV6：\c" ; rred "$v6" ; white " IPV6 奈飞NF解锁情况：\c" ; rred "$NF  \c"; white " IPV6 所在地区：\c" ; rred "$g6");;  
on) 
WARPIPv6Status=$(white "IPV6 WARP状态：\c" ; green "运行中，WARP普通账户(无限WARP流量)" ; white " [ Cloudflare服务商 ]获取IPV4：\c" ; green "$v6" ; white " IPV6 奈飞NF解锁情况：\c" ; green "$NF  \c"; white " IPV6 所在地区：\c" ; green "$g6");;
off) 
WARPIPv6Status=$(white "IPV6 WARP状态：\c" ; yellow "关闭中" ; white " [ $isp6服务商 ]获取IPV4：\c" ; yellow "$v6" ; white " IPV6 奈飞NF解锁情况：\c" ; yellow "$NF  \c"; white " IPV6 所在地区：\c" ; yellow "$g6");;
esac 
else
WARPIPv6Status=$(white "IPV6 状态：\c" ; red "不存在IPV6地址 ")
fi 
}

STOPwgcf(){
if [[ $(type -P warp-cli) ]]; then
red "已安装Socks5-WARP(+)，不支持当前选择的Wgcf-WARP(+)的安装方案" && bash CFwarp.sh
fi
}

WGCFv4(){
systemctl stop wg-quick@wgcf >/dev/null 2>&1
ShowWGCF
if [[ -n $v4 && -n $v6 ]]; then
green "vps真IP特征:原生v4+v6双栈vps\n现添加Wgcf-WARP-IPV4单栈"
ABC1=$ud4 && ABC2=$c2 && ABC3=$c5 && WGCFins
fi
if [[ -n $v6 && -z $v4 ]]; then
green "vps真IP特征:原生v6单栈vps\n现添加Wgcf-WARP-IPV4单栈"
ABC1=$c2 && ABC2=$c4 && ABC3=$c6 && WGCFins
fi
if [[ -z $v6 && -n $v4 ]]; then
green "vps真IP特征:原生v4单栈vps\n现添加Wgcf-WARP-IPV4单栈"
STOPwgcf && ABC1=$ud4 && ABC2=$c2 && ABC3=$c3 && ABC4=$c5 && WGCFins
fi
}

WGCFmenu(){
white "------------------------------------------------------------------------------------------------"
white " 当前VPS IPV4接管出站流量情况如下 "
blue " ${WARPIPv4Status}"
white "------------------------------------------------------------------------------------------------"
white " 当前VPS IPV6接管出站流量情况如下"
blue " ${WARPIPv6Status}"
white "------------------------------------------------------------------------------------------------"
}
back(){
white "------------------------------------------------------------------------------------------------"
white " 回主菜单，请按任意键"
white " 退出脚本，请按Ctrl+C"
get_char && bash CFwarp.sh
}

IP_Status_menu(){
white "------------------------------------------------------------------------------------------------"
WGCFmenu
}

WG(){
systemctl restart wg-quick@wgcf >/dev/null 2>&1
ShowWGCF
[[ $wgcfv4 =~ on|plus || $wgcfv6 =~ on|plus ]]
}

CheckWARP(){
yellow "请稍等3秒，获取WARP的IP中…………"
i=0
wg-quick down wgcf >/dev/null 2>&1
systemctl start wg-quick@wgcf >/dev/null 2>&1
while [ $i -le 4 ]; do let i++
WG && green "WARP的IP获取成功" && break || red "WARP的IP获取失败"
done
}

get_char(){
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}

WGCFins(){
rm -rf /usr/local/bin/wgcf /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go wgcf-account.toml wgcf-profile.conf
ShowWGCF
[[ $isp6 = 'ISPpro Internet KG' && $vi = lxc ]] && echo -e nameserver 2a01:4f8:c2c:123f::1 > /etc/resolv.conf
if [[ $release = Centos ]]; then
yum install epel-release -y;yum install iptables -y;yum install iproute wireguard-tools -y
elif [[ $release = Debian ]]; then
apt install iptables -y;apt install lsb-release -y;echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" | tee /etc/apt/sources.list.d/backports.list
apt update -y;apt install iproute2 openresolv -y;apt install wireguard-tools --no-install-recommends -y      		
elif [[ $release = Ubuntu ]]; then
apt update -y;apt install iptables -y;apt install iproute2 openresolv -y;apt install wireguard-tools --no-install-recommends -y			
fi
[[ $cpu = AMD64 ]] && wget -N https://cdn.jsdelivr.net/gh/kkkyg/CFwarp/wgcf_2.2.9_amd64 -O /usr/local/bin/wgcf && chmod +x /usr/local/bin/wgcf         
[[ $cpu = ARM64 ]] && wget -N https://cdn.jsdelivr.net/gh/kkkyg/CFwarp/wgcf_2.2.9_arm64 -O /usr/local/bin/wgcf && chmod +x /usr/local/bin/wgcf
if [[ $main -lt 5 || $minor -lt 6 ]]; then
[[ -e /usr/bin/wireguard-go ]] || wget -N https://cdn.jsdelivr.net/gh/kkkyg/CFwarp/wireguard-go -O /usr/bin/wireguard-go && chmod +x /usr/bin/wireguard-go
fi
if [[ $vi =~ lxc|openvz ]]; then
[[ -e /usr/bin/wireguard-go ]] || wget -N https://cdn.jsdelivr.net/gh/kkkyg/CFwarp/wireguard-go -O /usr/bin/wireguard-go && chmod +x /usr/bin/wireguard-go
fi
mkdir -p /etc/wireguard/ >/dev/null 2>&1
echo | wgcf register
until [[ -e wgcf-account.toml ]]
do
yellow "申请WARP普通账户过程中可能会多次提示：429 Too Many Requests，请耐心等待" && sleep 1
echo | wgcf register
done
wgcf generate
yellow "开始自动设置WARP的MTU最佳网络吞吐量值，以优化WARP网络！"
MTUy=1500
MTUc=10
v6=$(curl -s6m5 https://ip.gs -k)
v4=$(curl -s4m5 https://ip.gs -k)
if [[ -n $v6 && -z $v4 ]]; then
ping='ping6'
IP1='2606:4700:4700::1111'
IP2='2001:4860:4860::8888'
else
ping='ping'
IP1='1.1.1.1'
IP2='8.8.8.8'
fi
while true; do
if ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP1} >/dev/null 2>&1 || ${ping} -c1 -W1 -s$((${MTUy} - 28)) -Mdo ${IP2} >/dev/null 2>&1; then
MTUc=1
MTUy=$((${MTUy} + ${MTUc}))
else
MTUy=$((${MTUy} - ${MTUc}))
if [[ ${MTUc} = 1 ]]; then
break
fi
fi
if [[ ${MTUy} -le 1360 ]]; then
MTUy='1360'
break
fi
done
MTU=$((${MTUy} - 80))
green "MTU最佳网络吞吐量值= $MTU 已设置完毕"
sed -i "s/MTU.*/MTU = $MTU/g" wgcf-profile.conf
echo $ABC1 | sh
echo $ABC2 | sh
echo $ABC3 | sh
echo $ABC4 | sh
cp -f wgcf-profile.conf /etc/wireguard/wgcf.conf >/dev/null 2>&1
mv -f wgcf-profile.conf /etc/wireguard >/dev/null 2>&1
mv -f wgcf-account.toml /etc/wireguard >/dev/null 2>&1
systemctl enable wg-quick@wgcf >/dev/null 2>&1
CheckWARP
ShowWGCF && WGCFmenu && back
}

WARPun(){
cwg(){
wg-quick down wgcf >/dev/null 2>&1
systemctl disable wg-quick@wgcf >/dev/null 2>&1
$yumapt autoremove wireguard-tools
}
wj="rm -rf /usr/local/bin/wgcf /etc/wireguard/wgcf.conf /etc/wireguard/wgcf-profile.conf /etc/wireguard/wgcf-account.toml /etc/wireguard/wgcf+p.log /etc/wireguard/ID /usr/bin/wireguard-go wgcf-account.toml wgcf-profile.conf"    
[[ ! $(type -P wg-quick) ]] && (red "并没有安装WARP功能，无法卸载" && CFwarp.sh) || (cwg ; $wj ; rm -rf CFwarp.sh ; green "WARP已全部卸载完成" && ShowWGCF && WGCFmenu && S5menu && back)
}

start_menu(){
ShowWGCF
clear
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
bblue " WARP-WGCF/SOCKS5安装脚本：Beta1"
yellow " 详细说明 https://github.com/kkkyg/CFwarp  YouTube频道：甬哥侃侃侃"    
yellow " 切记：进入脚本快捷方式 bash CFwarp.sh "    
green "  1. 安装Wgcf-WARP:虚拟IPV4"      
green "  2. WARP卸载"
green "  0. 退出脚本 "
red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
white " VPS系统信息如下："
white " VPS操作系统: $(blue "$op") \c" && white " 内核版本: $(blue "$version") \c" && white " CPU架构 : $(blue "$cpu") \c" && white " 虚拟化类型: $(blue "$vi")"
IP_Status_menu
readp "请输入数字:" Input
case "$Input" in     
 1 ) WGCFv4;;
 2 ) WARPun;;
 0 ) exit 0
esac
}
start_menu "first"
