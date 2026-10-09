#!/bin/sh
# npc (nps 客户端) 控制器
# 二进制不编译进固件: 启用时按需从 GitHub Releases 下载, 支持指定版本(留空=最新版)

NPC_REPO="yisier/nps"
NPC_TARBALL="linux_mipsle_client.tar.gz"
NPC_FALLBACK_VER="v0.26.38"
NPC_DIR="/tmp/npc"
NPC_BIN="$NPC_DIR/npc"
NPC_VER_FILE="$NPC_DIR/npc.ver"
# 标记: 用于把老固件遗留的 /etc/storage/npc_script.sh 迁移成新版本(只迁移一次)
# 改动 npc_script.sh 逻辑时必须同步+1, 否则 /etc/storage 里的旧版不会被新版覆盖,
# 页面上的"服务器地址/端口"等设置改了也不生效(实际执行的始终是旧脚本)
NPC_SCRIPT_TAG="npc_script_v3"

npc_enable=`nvram get npc_enable`
http_username=`nvram get http_username`
[ -z "$http_username" ] && http_username=admin

# busybox wget 不一定支持 --no-check-certificate, 按需启用
WGET_SSL=""
if wget --help 2>&1 | grep -q "no-check-certificate" ; then
	WGET_SSL="--no-check-certificate"
fi

# 自愈/升级: /etc/storage/npc_script.sh 缺失, 或是老固件遗留下来的老版本(无标记)时从 /etc_ro 刷新
if [ ! -s "/etc/storage/npc_script.sh" ] || ! grep -q "$NPC_SCRIPT_TAG" /etc/storage/npc_script.sh 2>/dev/null ; then
	if [ -s "/etc_ro/npc_script.sh" ] ; then
		# 升级前备份旧脚本, 万一用户手改过内容不至于丢失
		[ -s "/etc/storage/npc_script.sh" ] && cp -f /etc/storage/npc_script.sh /etc/storage/npc_script.sh.bak
		cp -f /etc_ro/npc_script.sh /etc/storage/npc_script.sh
		chmod 755 /etc/storage/npc_script.sh
		logger -t "npc" "npc_script.sh 已更新到 $NPC_SCRIPT_TAG (旧版备份为 npc_script.sh.bak)"
	fi
fi

check_net()
{
	/bin/ping -c 3 www.baidu.com -w 5 >/dev/null 2>&1
	if [ "$?" = "0" ]; then
		return 1
	else
		return 2
	fi
}

# 取 GitHub 上最新 release 的版本号
npc_latest_ver()
{
	_npc_tag=""
	if [ -x /usr/bin/curl ]; then
		_npc_tag=`curl -s -k --connect-timeout 5 https://api.github.com/repos/$NPC_REPO/releases/latest 2>/dev/null | grep '"tag_name"' | head -n1 | cut -d'"' -f4`
	fi
	if [ -z "$_npc_tag" ]; then
		_npc_tag=`wget -q -T 5 -t 2 $WGET_SSL -O - https://api.github.com/repos/$NPC_REPO/releases/latest 2>/dev/null | grep '"tag_name"' | head -n1 | cut -d'"' -f4`
	fi
	echo "$_npc_tag"
}

# 下载文件: 优先 curl, 其次 wget; 成功返回 0
npc_dl()
{
	rm -f "$2"
	if [ -x /usr/bin/curl ]; then
		curl -L -k --connect-timeout 15 -o "$2" "$1" 2>/dev/null
	fi
	if [ ! -s "$2" ]; then
		wget -q -T 30 -t 2 $WGET_SSL -O "$2" "$1" 2>/dev/null
	fi
	[ -s "$2" ]
}

# 确保 $NPC_BIN 存在且版本匹配
npc_ensure_bin()
{
	npc_version=`nvram get npc_version`
	if [ -n "$npc_version" ]; then
		npc_dl_ver="$npc_version"
	else
		npc_dl_ver=`npc_latest_ver`
		if [ -z "$npc_dl_ver" ]; then
			npc_dl_ver="$NPC_FALLBACK_VER"
			logger -t "npc" "获取最新版本失败, 使用 $npc_dl_ver"
		else
			logger -t "npc" "使用最新版本 $npc_dl_ver"
		fi
	fi

	mkdir -p $NPC_DIR

	# 已存在且版本一致, 无需重新下载
	if [ -s "$NPC_BIN" ] && [ "`cat $NPC_VER_FILE 2>/dev/null`" = "$npc_dl_ver" ]; then
		return 0
	fi

	logger -t "npc" "开始下载 npc $npc_dl_ver ..."
	rm -f $NPC_BIN $NPC_DIR/npc.tar.gz
	npc_dl "https://github.com/$NPC_REPO/releases/download/$npc_dl_ver/$NPC_TARBALL" "$NPC_DIR/npc.tar.gz"
	if [ -s "$NPC_DIR/npc.tar.gz" ]; then
		tar -xz -C $NPC_DIR -f $NPC_DIR/npc.tar.gz 2>/dev/null
		rm -f $NPC_DIR/npc.tar.gz
		# 包内为 npc 与 conf/; 个别版本会多套一层 npc/ 目录
		[ -f $NPC_DIR/nps/npc ] && mv -f $NPC_DIR/nps/npc $NPC_BIN
		rm -rf $NPC_DIR/nps $NPC_DIR/conf
	fi

	if [ -s "$NPC_BIN" ]; then
		chmod 755 $NPC_BIN
		echo "$npc_dl_ver" > $NPC_VER_FILE
		nvram set npc_ver="$npc_dl_ver"
		logger -t "npc" "npc $npc_dl_ver 下载完成"
		return 0
	fi

	nvram set npc_ver="下载失败"
	logger -t "npc" "npc 下载失败(版本 $npc_dl_ver), 5 分钟后自动重试"
	return 1
}

npc_start()
{
	killall -9 npc npc_script.sh 2>/dev/null
	npc_ensure_bin || return 1
	if [ ! -s "/etc/storage/npc_script.sh" ]; then
		logger -t "npc" "npc_script.sh 不存在, 无法启动"
		return 1
	fi
	/etc/storage/npc_script.sh
	sleep 1
	sed -i '/npc/d' /etc/storage/cron/crontabs/$http_username 2>/dev/null
	cat >> /etc/storage/cron/crontabs/$http_username << EOF
*/5 * * * * /bin/sh /usr/bin/npc.sh C >/dev/null 2>&1
EOF
	[ ! -z "`pidof npc`" ] && logger -t "npc" "npc启动成功" || logger -t "npc" "npc启动失败, 请检查配置"
}

npc_close()
{
	if [ ! -z "`pidof npc`" ]; then
		killall -9 npc npc_script.sh 2>/dev/null
		[ -z "`pidof npc`" ] && logger -t "npc" "已停止 npc"
	fi
	sed -i '/npc/d' /etc/storage/cron/crontabs/$http_username 2>/dev/null
}

check_npc()
{
	check_net
	result_net=$?
	if [ "$result_net" = "1" ] ;then
		if [ -z "`pidof npc`" ] && [ "$npc_enable" = "1" ];then
			npc_start
		fi
	else
		logger -t "npc" "npc断线重连"
	fi
}

case $1 in
start)
	npc_start
	;;
stop)
	npc_close
	;;
restart)
	npc_close
	npc_start
	;;
C)
	check_npc
	;;
esac
