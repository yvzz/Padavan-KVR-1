# Padavan-KVR #

![](https://views.whatilearened.today/views/github/yvzz/padavan-KVR-1.svg)[![](https://deepwiki.com/badge.svg)](https://deepwiki.com/yvzz/padavan-KVR-1)

基于 [vb1980/Padavan-KVR](https://github.com/vb1980/Padavan-KVR.git) 固件（浅色主题）二次维护，最初 fork 自 [fightroad/Padavan-KVR](https://github.com/fightroad/Padavan-KVR.git)。

继承并整合了 hanwckf、chongshengB、padavanonly 的源码，主要特点：

1. 采用 padavanonly 源码的 5.0.4.0 无线驱动，支持 KVR（802.11k/v/r 漫游）
2. 整合 chongshengB 源码的插件体系，并在 Web 管理界面「自定义菜单」中新增了一批内网穿透 / 组网类插件
3. 部分优化来自 immortalwrt 的 Padavan 源码
4. 最近的更新代码来自 hanwckf 与 MeIsReallyBa 大佬的 4.4 内核分支
   - https://github.com/hanwckf/padavan-4.4
   - https://github.com/MeIsReallyBa/padavan-4.4

上游四位源码地址供参考：

- https://github.com/hanwckf/rt-n56u
- https://github.com/chongshengB/rt-n56u
- https://github.com/padavanonly/rt-n56u
- https://github.com/immortalwrt/padavan

## 默认登录与 WiFi 信息

管理地址

- `192.168.2.1`

管理账号 / 密码

- `admin` / `admin`

WiFi（默认 SSID 为机型名 `BOARD_PID`，**不带 MAC 后缀**）

- 2.4G：`机型名`，如 `K2P`
- 5G：`机型名_5G`，如 `K2P_5G`
- 访客：`机型名_GUEST` / `机型名_GUEST_5G`
- WiFi 密码：`1234567890`

> 早期版本 SSID 带 MAC 后四位（如 `K2P_9981`），现固件已改为纯机型名。若要恢复 MAC 后缀，在 `trunk/user/shared/defaults.h` 的 `DEF_WLAN_*_SSID` 定义中加 `MAC` 拼接并同步 `rc.c` 的填充逻辑。

## 支持的机型

- 板级配置见 `trunk/configs/boards/`，编译模板见 `trunk/configs/templates/`，支持机型涵盖 K2P、NEWIFI3、MSG1500、JCG-Q20、CR660x、RM2100、MI-R3G/R4A 等数十款 MT7621 / MT76x8 设备。
- 已内置在线编译工作流（`.github/workflows/`）：`K2P.yml`、`MI-MINI.yml`、`R2100.yml`、`RM2100.yml`，可 fork 后直接 Actions 在线编译。
- 自定义增减插件：编辑对应机型的 `trunk/configs/templates/<机型>.config`，将 `CONFIG_FIRMWARE_INCLUDE_*` 开关改为 `y`/`n`。
- ⚠️ 对 7612 无线芯片的支持已知有问题，含 7612 的机型（如 B70）无法正常工作。

## 自定义菜单 / 插件说明

固件在 Web 管理界面「自定义菜单」页提供大量插件开关。本节区分两个常被混淆的概念：

- **菜单已接入**：Web UI 上能看到的二级菜单项（由 `Advanced_web.asp` + `state.js` 注册）。
- **默认编译进固件**：`.config` 模板里 `CONFIG_FIRMWARE_INCLUDE_*=y`，二进制/脚本随固件烧入。

⚠️ **本仓库默认的 K2P 编译模板基本是精简的**：Web 二级菜单里看到的开关很多，但绝大多数插件在 `trunk/configs/templates/K2P.config` 里 **没有** 显式开启 `CONFIG_FIRMWARE_INCLUDE_*`，因此**默认编译出来的固件里很多插件不包含二进制**。需要在对应 `.config` 里把开关改为 `y`，或在 fork 后用 GitHub Actions 改 Workflow 的 `ENABLED_PLUGINS` 才会编入。

下表对照「Web 二级菜单 ↔ 默认编译状态」，用于核对哪些默认可用、哪些需要手动开启：

组网 / 内网穿透

| 插件 | Web 菜单 | K2P 默认编译 | 说明 |
| --- | --- | --- | --- |
| EasyTier（P2P 虚拟局域网，Rust） | ✅ | ❌ 二进制运行期下载 | 首次启用自动下载到 `/tmp/easytier/` |
| Tailscale（WireGuard 系零配置组网） | ✅ | ❌ 二进制运行期下载 | 同上 |
| VNT 客户端（`vntcli`） | ✅ | ❌ 二进制运行期下载 | 同上 |
| VNT 服务端（`vnts`） | ✅ | ❌ 二进制运行期下载 | 同上 |
| NPC（nps 客户端，内网穿透） | ✅ | ❌ 二进制运行期下载 | 同上 |
| WireGuard | ✅ | ❌ 内核模块编译关闭 | `CONFIG_FIRMWARE_INCLUDE_WIREGUARD=n`，需手动开 |
| **皎月连（NAT 穿透）** | ✅ | ❌ 未编译 | `CONFIG_FIRMWARE_INCLUDE_NATPIERCE` 默认未设置 |
| **FRP（frpc / frps）** | ✅ | ❌ 未编译 | `CONFIG_FIRMWARE_INCLUDE_FRPC=n` / `FRPS=n` |

DNS / 动态域名

| 插件 | Web 菜单 | K2P 默认编译 | 说明 |
| --- | --- | --- | --- |
| 阿里云 DDNS（`aliddns`） | ✅ | ❌ 需手动开 |
| DNSPod DDNS（`ddnspod`） | ✅ | ❌ 需手动开 |

网络工具 / 应用

| 插件 | Web 菜单 | K2P 默认编译 | 说明 |
| --- | --- | --- | --- |
| Alist（网盘聚合） | ✅ | ❌ 需手动开 |
| 巴法云（IoT / MQTT，仓库 `bafa/`） | ✅ | ❌ 需手动开 |
| VirtualHere（USB 共享） | ✅ | ❌ 需手动开 |
| V2RayA（代理） | ✅ | ❌ 需手动开 |
| Caddy / Cloudflared / 阿里云盘 WebDAV / 网易云解锁 / UU 加速器 / Lucky / 微信推送 | ✅ | ❌ 默认均未编译 | 仓库目录齐全，需手动翻 `.config` 开关 |

其它

- `K2P.config` 里默认开启的零碎工具：`TTYD`、`OpenSSH`、`tcpdump`、`curl`、`OpenVPN`、`xUPNPD`、`srelay`、`socat`、`MTR`、`htop`、`nano`、`iperf3`、`MiniEAP` 等。
- Shadowsocks、pdnsd DNS 加速、MentoHust 校园网认证等老插件：源码在仓库，Web 菜单无独立开关，需自己加 `dir_y +=` 进 `trunk/user/Makefile`。

如何快速检查一个插件当前是否编入了你的固件？

- 在路由器上 `ls /usr/bin/ | grep -iE "插件名|二进制名"`，存在即编入。
- 不存在 → 打开 Web 「自定义菜单」页，对应开关即便亮着也只代表 Web 标记，不会凭空变出二进制。

## 移除 WireGuard 内核模块（可选）

不需要 WireGuard 的，去 `trunk/configs/boards/<机型>/kernel-3.4.x.config` 把 `CONFIG_WIREGUARD=y` 改为 `# CONFIG_WIREGUARD is not set`，可省约 900KB+ 内核体积。

## 个性化

修改背景图：刷机后在 `/etc/storage/` 新建 `bg` 文件夹，放入 `wood.jpg` 即可，路径为 `/etc/storage/bg/wood.jpg`。

修改 LOGO：替换 `trunk/user/www/n56u_ribbon_fixed/bootstrap/img/asus_logo.png`（像素 150×70）。

修改默认管理地址 / WiFi 名称 / 账号密码：见 `trunk/user/shared/defaults.h`。

修改 `/tmp` 分区大小（默认 100M）：`trunk/user/scripts/dev_init.sh` 中的 `size_tmp="100M"`。

修改 `/etc/storage` 分区大小（以 NEWIFI3 d2 32M 闪存为例）：

1. `trunk/configs/boards/<机型>/kernel-3.4.x.config` 中 `CONFIG_MTD_STORE_PART_SIZ=0x200000`
2. `trunk/user/scripts/dev_init.sh` 中 `size_etc="6M"`
3. `trunk/user/scripts/mtd_storage.sh` 中 `mtd_part_size=65536`

计算方式：先确认闪存大小，减去编译后固件大小得到可用空间。如 32M 闪存、固件 18M，则可用 14M = 14680064 字节，十六进制为 `0xe00000`。将 `CONFIG_MTD_STORE_PART_SIZ` 改为 `0xe00000`、`size_etc` 改为 `14M`、`mtd_part_size` 改为 `14680064`。**切记 storage 分区 + 固件大小必须小于闪存总大小，不能超过！**

## 编译

本地编译方法同其他 Padavan 源码（需先构建 toolchain）。推荐使用 `.github/workflows/` 下的在线工作流，fork 仓库后在 Actions 中选择机型即可编译，无需本地环境。