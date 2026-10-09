THISDIR := $(shell pwd)

all:

extract_test:

config_test:

clean:

# npc 二进制不编译进固件: 启用时由 /usr/bin/npc.sh 从 GitHub Releases
# 按需下载, 优先放 /etc/storage/bin (flash, 不占内存), 空间不足回退 /tmp/npc,
# 版本可由 Web 页指定(留空=最新版)
romfs:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_NPC),y)
	$(ROMFSINST) -p +x $(THISDIR)/npc.sh /usr/bin/npc.sh
	$(ROMFSINST) /etc_ro/npc_script.sh
endif
