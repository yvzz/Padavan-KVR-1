#!/bin/sh
# npc_script_v3
# 生成 npc 配置并启动. 二进制由 /usr/bin/npc.sh 按需下载到 /tmp/npc/npc,
# (老版本固件里此处是 /usr/bin/npc, 已随"不编译进固件"一起改掉)
killall npc
mkdir -p /tmp/npc
tmpconf="/tmp/npc/npc.conf"
LOGFILE="/tmp/npc.log"
npc_bin="/tmp/npc/npc"

if [ -f $tmpconf ] ; then 
	rm $tmpconf
fi

npc_enable=`nvram get npc_enable`
server_addr=`nvram get npc_server_addr`
server_port=`nvram get npc_server_port`
protocol=`nvram get npc_protocol`
vkey=`nvram get npc_vkey`
compress=`nvram get npc_compress`
crypt=`nvram get npc_crypt`
Log_level=`nvram get npc_log_level`

# 服务器地址: 已自带端口(形如 1.2.3.4:8284)时不再拼接 server_port,
# 否则会拼出 "1.2.3.4:8284:8024" 这种双端口, npc 必然连不上
case "$server_addr" in
	*:*) server_full="$server_addr" ;;
	*)   server_full="$server_addr:$server_port" ;;
esac

echo "[common]" >$tmpconf
echo "server_addr=$server_full" >>$tmpconf
echo "conn_type=$protocol" >>$tmpconf
echo "vkey=$vkey" >>$tmpconf
echo "auto_reconnection=true" >>$tmpconf

if [ "$compress" = "1" ] ; then
	echo "compress=true" >>$tmpconf
else
	echo "compress=false" >>$tmpconf
fi

if [ "$crypt" = "1" ] ; then
	echo "crypt=true" >>$tmpconf
else
	echo "crypt=false" >>$tmpconf
fi

if [ "$npc_enable" = "1" ] ; then
	if [ ! -s "$npc_bin" ]; then
		logger -t "NPC" "npc 二进制文件不存在: $npc_bin (等待 npc.sh 下载)"
	else
		chmod 755 "$npc_bin"
		cd /tmp/npc
		"$npc_bin" -config=$tmpconf -log_level=$Log_level -log_path=$LOGFILE -debug=false >/dev/null 2>&1 &
		logger -t "NPC" "npc 已启动, 服务器 $server_full"
	fi
fi
