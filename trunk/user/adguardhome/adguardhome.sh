#!/bin/sh

change_dns() {
if [ "$(nvram get adg_redirect)" = 1 ]; then
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#5335
EOF
/sbin/restart_dhcpd
logger -t "AdGuardHome" "添加DNS转发到5335端口"
fi
}
del_dns() {
sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
sed -i '/server=127.0.0.1#5335/d' /etc/storage/dnsmasq/dnsmasq.conf
/sbin/restart_dhcpd
}

set_iptable()
{
    if [ "$(nvram get adg_redirect)" = 2 ]; then
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
	done

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
		ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
	done
    logger -t "AdGuardHome" "重定向53端口"
    fi
}

clear_iptable()
{
	OLD_PORT="5335"
	IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done

	IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done
	
}

getconfig(){
adg_file="/etc/storage/adg.sh"
if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
	cat > "$adg_file" <<-\EEE
bind_host: 0.0.0.0
bind_port: 3000
auth_name: root
auth_pass: root
language: zh-cn
rlimit_nofile: 0
dns:
  bind_host: 0.0.0.0
  port: 5335
  protection_enabled: true
  filtering_enabled: true
  blocking_mode: nxdomain
  blocked_response_ttl: 10
  querylog_enabled: true
  ratelimit: 20
  ratelimit_whitelist: []
  refuse_any: true
  bootstrap_dns:
  - 223.5.5.5
  all_servers: true
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts: []
  parental_sensitivity: 0
  parental_enabled: false
  safesearch_enabled: false
  safebrowsing_enabled: false
  resolveraddress: ""
  upstream_dns:
  - tls://dns.pub
  - https://dns.pub/dns-query
  - tls://dns.alidns.com
  - https://dns.alidns.com/dns-query
  - 2400:3200::1
  - 240c::6666
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  certificate_chain: ""
  private_key: ""
filters:
- enabled: true
  url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
  name: AdGuard DNS filter
  id: 1628750870
- enabled: true
  url: https://anti-ad.net/easylist.txt
  name: 'CHN: anti-AD'
  id: 1628750871
- enabled: false
  url: https://raw.hellogithub.com/hosts
  name: GitHub-hosts
  id: 1666724350
- enabled: true
  url: https://cats-team.github.io/AdRules/dns.txt
  name: AdRules
  id: 1666257451
- enabled: false
  url: https://adrules.top/hosts.txt
  name: adrules-hosts
  id: 1677725146
- enabled: false
  url: https://adrules.top/dns.txt
  name: adrules-dns
  id: 1677725147
- enabled: false
  url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
  name: OISD Blocklist Full
  id: 1677725150
user_rules:
- '#屏蔽苹果OTA更新#'
- '||xp.apple.com^'
- '||mesu.apple.com^'
- '||.apple.com^'
- '||ocsp.apple.com^'
- '||appldnld.apple.com^'
- '||world-gen.g.aaplimg.com^'
- '# 酷安信息流及评论区广告#'
- '||ctobsnssdk.com^'
- '||pangolin.snssdk.com^'
- '||pangolin-sdk-toutiao.com^'
- '||pangolin-sdk-toutiao-b.com^'
- '||pglstatp-toutiao.com^'
- '||dm.toutiao.com^'
- '||ulogs.umeng.com^'
- '||aaid.umeng.com^'
- '||tnc*.zijieapi.com^'
- '||mssdk-bu.bytedance.com^'
- '#穿山甲#'
- '||wxsnsdy.wxs.qq.com^'
- '||wxa.wxs.qq.com^'
- '||wxsnsdythumb.wxs.qq.com^'
- '||is.snssdk.com^'
- '||i.snssdk.com^'
- '||p3-tt.byteimg.com^'
- '||success.ctobsnssdk.com^'
- '||sf16-static.i18n-pglstatp.com^'
- '||sf3-fe-tos.pglstatp-toutiao.com^'
- '||ad.zijieapi.com^'
- '||api-access.pangolin-sdk-toutiao.com^'
- '||mobads.baidu.com^'
- '||ad.qq.com^'
- '||ks.pull.yximgs.com^'
- '||open.e.kuaishou.com^'
- '||open.e.kuaishou.cn^'
- '||open.e.kuaishou^'
- '||open.kwaizt.com^'
- '||bd.pull.yximgs.com^'
- '||jstatic.3.cn^'
- '||p1-lm.adukwai.com^'
- '||p2-lm.adukwai.com^'
- '||p3-lm.adukwai.com^'
- '||p4-lm.adukwai.com^'
- '||p5-lm.adukwai.com^'
- '||m.jingxi.com^'
- '||chat1.jd.com^'
- '||www.csjplatform.com^'
- '||xlmzc.cnjp-exp.com^'
- '||lm10111.jtrincc.cn^'
- '||ali-ad.a.yximgs.com^'
- '||qqdata.ab.qq.com^'
- '||tx-ad.a.yximgs.com^'
- '||p1-lm.adkwai.com^'
- '||video-dsp.pddpic.com^'
- '||v1-lm.adukwai.com^'
- '||v2-lm.adukwai.com^'
- '||v3-lm.adukwai.com^'
- '||v4-lm.adukwai.com^'
- '||v5-lm.adukwai.com^'
- '||pgdt.ugdtimg.com^'
- '||tx-kmpaudio.pull.yximgs.com^'
- '||hmma.baidu.com^'
- '||apiyd.my91app.com^'
- '||open.kuaishouzt^'
- '||qzs.gdtimg.com^'
- '||sdkoptedge.chinanetcenter.com^'
- '||roi.soulapp.cn^'
- '||bd.pull.yximgs.com^'
- '||bd-adaptive.pull.yximgs.com^'
- '||bd-livemate.pull.yximgs.com^'
- '||bd-origin.pull.yximgs.com^'
- '||bd-pclivemate.pull.yximgs.com^'
- '||bd-proxy.pull.yximgs.com^'
- '||bd-rwk.pull.etoote.com^'
- '||httpdns.bcelive.com^'
- '||skdisplay.jd.com^'
- '||p9-be-pack-sign.pglstatp-toutiao.com^'
- '||v6-be-pack.pglstatp-toutiao.com^'
- '||log-api.pangolin-sdk-toutiao-b.com^'
- '||api-access.pangolin-sdk-toutiao-b.com^'
- '||pangolin-sdk-toutiao-b.com^'
- '||pig.pupuapi.com^'
- '||pglstatp-toutiao.com^'
- '||thumb.1010pic.com^'
- '||thumb2018.1010pic.com^'
- '||1010pic.com^'
- '# 电视白名单 #'
- '@@||jiexi.bulisite.top^$important'
- ""
dhcp:
  enabled: false
  interface_name: ""
  gateway_ip: ""
  subnet_mask: ""
  range_start: ""
  range_end: ""
  lease_duration: 86400
  icmp_timeout_msec: 1000
clients: []
log_file: ""
verbose: false
schema_version: 3
EEE
	chmod 755 "$adg_file"
fi
}

dl_adg(){
    logger -t "AdGuardHome" "下载AdGuardHome"

    # 尝试从本地地址下载
    if [ -f "/media/AiDisk_a1/nas/adg/AdGuardHome" ]; then
        cp /media/AiDisk_a1/nas/adg/AdGuardHome /tmp/AdGuardHome/AdGuardHome
    else
        logger -t "AdGuardHome" "本地AdGuardHome文件不存在，尝试从网络下载"
        
        # 第一选择（网络下载）
        if ! wget --no-check-certificate -O /media/AiDisk_a1/nas/adg/AdGuardHome_linux_mipsle_softfloat.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.106.0/AdGuardHome_linux_mipsle_softfloat.tar.gz; then
            logger -t "AdGuardHome" "第一选择网络下载失败，尝试第二选择"

            # 第二选择（网络下载）
            if ! wget --no-check-certificate -O /tmp/AdGuardHome/AdGuardHome https://cdn.jsdelivr.net/gh/bauw2008/e8820s-3.4-Padavan/trunk/user/adguardhome/AdGuardHome; then
                logger -t "AdGuardHome" "AdGuardHome下载失败，请检查是否能正常访问下载源!程序将退出。"
                nvram set adg_enable=0
                exit 0
            fi
        fi

        # 解压缩
        tar -xzf /media/AiDisk_a1/nas/adg/AdGuardHome_linux_mipsle_softfloat.tar.gz -C /media/AiDisk_a1/nas/adg/
        if [ ! -f "/media/AiDisk_a1/nas/adg/AdGuardHome" ]; then
            logger -t "AdGuardHome" "解压缩AdGuardHome失败，请检查压缩包是否有效。程序将退出。"
            nvram set adg_enable=0
            exit 0
        fi

        # 将解压后的文件复制到 /tmp/AdGuardHome 目录中
        cp /media/AiDisk_a1/nas/adg/AdGuardHome /tmp/AdGuardHome/AdGuardHome
    fi

    logger -t "AdGuardHome" "AdGuardHome下载成功。"
    chmod 755 /tmp/AdGuardHome/AdGuardHome
}

start_adg(){
    mkdir -p /tmp/AdGuardHome
    mkdir -p /etc/storage/AdGuardHome
    if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ]; then
        dl_adg
    fi
    getconfig
    change_dns
    set_iptable
    logger -t "AdGuardHome" "运行AdGuardHome"
    eval "/tmp/AdGuardHome/AdGuardHome -c $adg_file -w /tmp/AdGuardHome -v" &
}

stop_adg(){
    rm -rf /tmp/AdGuardHome
    killall -9 AdGuardHome
    del_dns
    clear_iptable
}

case $1 in
start)
    start_adg
    ;;
stop)
    stop_adg
    ;;
*)
    echo "check"
    ;;
esac
