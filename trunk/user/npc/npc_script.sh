#!/bin/sh
# npc_script_v5
# 生成 npc 配置并启动. 二进制由 /usr/bin/npc.sh 按需下载
# (优先 /etc/storage/bin/npc, 空间不足时回退 /tmp/npc/npc)
#
# 关键点: 必须先干净地杀掉旧实例并等它真正退出再启动.
# 新旧实例并存会吃光内存和线程, tokio 起不来线程会直接 panic:
#   OS can't spawn worker thread: Resource temporarily unavailable (os error 11)

LOGFILE="/tmp/npc.log"
tmpconf="/tmp/npc/npc.conf"
mkdir -p /tmp/npc

# 1) 停掉旧实例: SIGKILL + 等待真正退出
npc_alive()
{
	for _p in `pidof npc 2>/dev/null` ; do
		[ "`awk '{print $3}' /proc/$_p/stat 2>/dev/null`" != "Z" ] && return 0
	done
	return 1
}

killall -9 npc 2>/dev/null
_i=0
while [ $_i -lt 15 ] ; do
	npc_alive || break
	killall -9 npc 2>/dev/null
	sleep 1
	_i=$((_i+1))
done

if [ -f $tmpconf ] ; then
	rm -f $tmpconf
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

# 二进制位置由 npc.sh 决定, 两个目录都认, 兼容旧版留在 /tmp 的
npc_bin=""
for _b in /etc/storage/bin/npc /tmp/npc/npc ; do
	[ -s "$_b" ] && { npc_bin="$_b"; break; }
done

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

# 日志超过 4M 清空: /tmp 是 tmpfs, 日志无限制增长会吃掉本就不多的内存
[ -s "$LOGFILE" ] && [ `stat -c %s "$LOGFILE"` -gt 4194304 ] && echo "" > $LOGFILE

if [ "$npc_enable" = "1" ] ; then
	if [ -z "$npc_bin" ]; then
		logger -t "【NPC】" "npc 二进制文件不存在 (等待 npc.sh 下载)"
	else
		chmod 755 "$npc_bin"
		cd "$(dirname "$npc_bin")"
		# 限制 tokio 工作线程数: 默认按 CPU 核数起线程, 小内存路由器上
		# 线程栈一多就容易分配失败(EAGAIN)直接 panic
		[ -z "$NPC_WORKER_THREADS" ] && NPC_WORKER_THREADS=2
		TOKIO_WORKER_THREADS=$NPC_WORKER_THREADS "$npc_bin" -config=$tmpconf -log_level=$Log_level -log_path=$LOGFILE -debug=false >/dev/null 2>&1 &
		logger -t "【NPC】" "npc 已启动, 服务器 $server_full, PID $!"
	fi
fi
