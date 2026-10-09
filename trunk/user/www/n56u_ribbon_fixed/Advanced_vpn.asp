<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 组网服务</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();
<% easytier_status(); %>
<% easytier_web_status(); %>
<% tailscale_status(); %>
<% tailscaled_status(); %>
<% vntcli_status(); %>
<% vnts_status(); %>
<% npc_status(); %>
<% login_state_hook(); %>

/* VNT客户端: 子网配置 / 端口映射 列表 */
var m_routelist = [<% get_nvram_list("VNTCLI", "VNTCLIroute"); %>];
var mroutelist_ifield = 4;
if(m_routelist.length > 0){
	var m_routelist_ifield = m_routelist[0].length;
	for (var i = 0; i < m_routelist.length; i++) {
		m_routelist[i][mroutelist_ifield] = i;
	}
}
var m_mapplist = [<% get_nvram_list("VNTCLI", "VNTCLImapp"); %>];
var mmapplist_ifield = 5;
if(m_mapplist.length > 0){
	var m_mapplist_ifield = m_mapplist[0].length;
	for (var i = 0; i < m_mapplist.length; i++) {
		m_mapplist[i][mmapplist_ifield] = i;
	}
}

/* 一级页签(服务) 与 二级页签(各服务自己的设置/状态/日志) */
var services = ["easytier","tailscale","vntcli","vnts","npc","wireguard"];
var subTabs = {
	"easytier":  {"prefix":"et",        "subs":["cfg","web","sta","log"]},
	"tailscale": {"prefix":"tailscale", "subs":["cfg","log"]},
	"vntcli":    {"prefix":"vntcli",    "subs":["cfg","pri","sta","log","help"]},
	"vnts":      {"prefix":"vnts",      "subs":["cfg","log"]},
	"npc":       {"prefix":"npc",       "subs":[]},
	"wireguard": {"prefix":"wg",        "subs":[]}
};
var appCheck = {
	"easytier":  function(){ return found_app_easytier(); },
	"tailscale": function(){ return found_app_tailscale(); },
	"vntcli":    function(){ return found_app_vntcli(); },
	"vnts":      function(){ return found_app_vnts(); },
	"npc":       function(){ return found_app_npc(); },
	"wireguard": function(){ return found_app_wireguard(); }
};

/* 各服务在 httpd variables.c 里注册的变量组名 */
var sidGroups = {
	"easytier":  "EASYTIER",
	"tailscale": "TAILSCALE",
	"vntcli":    "VNTCLI",
	"vnts":      "VNTS",
	"npc":       "NpcConf",
	"wireguard": "WIREGUARD"
};

/* 只提交本固件已编译服务的变量组: 未编译的组在 httpd 的 svcLinks[] 里没有注册,
   写进 sid_list 会让 update_variables_ex() 取到越界的 sid, apply 直接失败 */
function build_sid_list(){
	if (!document.form || !document.form.sid_list)
		return;
	var list = "LANHostConfig;General;";
	for (var i = 0; i < services.length; i++) {
		var svc = services[i];
		if (sidGroups[svc] && appCheck[svc]())
			list = sidGroups[svc] + ";" + list;
	}
	document.form.sid_list.value = list;
}

/* 第一个已编译进固件的服务, 作为默认/回退页签 */
function firstVisibleService(){
	for (var i = 0; i < services.length; i++) {
		if (appCheck[services[i]]())
			return services[i];
	}
	return services[0];
}

/* hash 形式: "#<服务>" 或 "#<服务>-<二级页签>", 例: #easytier-sta */
function parseHash(h){
	h = (h || '').replace('#','');
	var i = h.indexOf('-');
	if (i < 0)
		return [h, ''];
	return [h.slice(0, i), h.slice(i + 1)];
}

function showSub(svc, sub){
	var p = subTabs[svc].prefix, arr = subTabs[svc].subs;
	for (var i = 0; i < arr.length; i++) {
		if (arr[i] == sub) {
			$j('#tab_' + p + '_' + arr[i]).parents('li').addClass('active');
			$j('#wnd_' + p + '_' + arr[i]).show();
		} else {
			$j('#wnd_' + p + '_' + arr[i]).hide();
			$j('#tab_' + p + '_' + arr[i]).parents('li').removeClass('active');
		}
	}
}

function showService(svc, sub){
	if (!svc || subTabs[svc] == undefined || !appCheck[svc]())
		svc = firstVisibleService();
	var arr = subTabs[svc].subs;
	if (!sub || arr.indexOf(sub) < 0)
		sub = arr[0];
	for (var i = 0; i < services.length; i++) {
		if (services[i] == svc) {
			$j('#tab_net_' + services[i]).parents('li').addClass('active');
			$j('#wnd_net_' + services[i]).show();
		} else {
			$j('#wnd_net_' + services[i]).hide();
			$j('#tab_net_' + services[i]).parents('li').removeClass('active');
		}
	}
	showSub(svc, sub);
	window.location.hash = '#' + svc + (sub ? ('-' + sub) : '');
}

function showTab(curHash){
	var r = parseHash(curHash);
	showService(r[0], r[1]);
}

/* 重新加载页面并保持当前页签(hash), 避免刷新后跳回默认页签 */
function reloadTab(hash){
	hash = hash || window.location.hash;
	if (window.location.hash != hash)
		window.location.hash = hash;
	window.location.reload();
}

$j(document).ready(function(){

	/* 未编译进本固件的服务, 隐藏对应一级页签 */
	for (var i = 0; i < services.length; i++) {
		if (!appCheck[services[i]]())
			$j('#tab_net_' + services[i]).parents('li').hide();
	}

	$j('.svctab, .subtab').click(function(){
		showTab($j(this).attr('href').toLowerCase());
		return false;
	});

	if (appCheck["easytier"]())
		init_itoggle('easytier_web_enable');

	if (appCheck["tailscale"]()) {
		init_itoggle('tailscale_dns');
		init_itoggle('tailscale_route');
		init_itoggle('tailscale_exit');
		init_itoggle('tailscale_reset');
		init_itoggle('tailscale_ssh');
		init_itoggle('tailscale_shields');
	}

	if (appCheck["vntcli"]()) {
		init_itoggle('vntcli_log');
		init_itoggle('vntcli_proxy');
		init_itoggle('vntcli_wg');
		init_itoggle('vntcli_first');
		init_itoggle('vntcli_finger');
		init_itoggle('vntcli_serverw');
		init_itoggle('vntcli_disable_relay');
	}

	if (appCheck["vnts"]()) {
		init_itoggle('vnts_enable', change_vnts_enable);
		init_itoggle('vnts_log');
		init_itoggle('vnts_web_enable', change_vnts_web_enable_bridge);
		init_itoggle('vnts_web_wan');
		init_itoggle('vnts_sfinger');
		init_itoggle('vnts_disable_group');
		init_itoggle('vnts_disable_relay');
	}

	if (appCheck["npc"]())
		init_itoggle('npc_enable', change_npc_enable_bridge);

	if (appCheck["wireguard"]())
		init_itoggle('wireguard_enable');

	/* 进入页面时按 URL hash 定位到对应服务/页签 */
	showTab(window.location.hash);

});

</script>
<script>

function initial(){
	show_banner(2);
	show_menu(5, 26, 0);
	show_footer();
	build_sid_list();

	if (appCheck["vntcli"]()) {
		showROUTEList();
		showMAPPList();
	}
	if (appCheck["easytier"]()) {
		fill_status_et(easytier_status());
		fill_status_etweb(easytier_web_status());
		change_easytier_enable(1);
	}
	if (appCheck["tailscale"]()) {
		fill_status_ts(tailscaled_status());
		fill_status_ts2(tailscale_status());
		change_tailscale_enable();
	}
	if (appCheck["vntcli"]()) {
		fill_status_vc(vntcli_status());
		change_vntcli_enable(1);
		change_vntcli_model(1);
	}
	if (appCheck["vnts"]()) {
		fill_status_vs(vnts_status());
		change_vnts_enable(1);
		change_vnts_web_enable_bridge(1);
	}
	if (appCheck["npc"]()) {
		fill_status_npc(npc_status());
		change_npc_enable_bridge(1);
	}

	if (!login_safe())
		textarea_scripts_enabled(0);

	showTab(window.location.hash);
}

function textarea_scripts_enabled(v){
	if (document.form['scripts.easytier.toml'])
		inputCtrl(document.form['scripts.easytier.toml'], v);
	if (document.form['scripts.vnt.conf'])
		inputCtrl(document.form['scripts.vnt.conf'], v);
	if (document.form['scripts.npc_script.sh'])
		inputCtrl(document.form['scripts.npc_script.sh'], v);
	if (document.form['scripts.wg0.conf'])
		inputCtrl(document.form['scripts.wg0.conf'], v);
}

function applyRule(){
	showLoading();
	build_sid_list();

	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_vpn.asp";
	/* next_page 带回页签 hash, 避免应用后跳回默认页签 */
	document.form.next_page.value = "/Advanced_vpn.asp" + window.location.hash;

	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

/* ============ WireGuard ============ */
function button_restartwg(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' Restartwg '
	});
}

/* ============ EasyTier ============ */
function fill_status_et(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("easytier_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function fill_status_etweb(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("easytier_web_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function change_easytier_enable(mflag){
	var m = document.form.easytier_enable.value;
	var is_easytier_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restarteasytier.value = is_easytier_enable;

	var is_easytier_file = (m == "2") ? 1 : 0;
	showhide_div("easytier_file_tr", is_easytier_file);
	showhide_div("easytier_file_td", is_easytier_file);

	var is_config_server = (m == "1") ? 1 : 0;
	showhide_div("config_server_tr", is_config_server);
	showhide_div("config_server_td", is_config_server);
	showhide_div("hostname_tr", is_config_server);
	showhide_div("hostname_td", is_config_server);
}

function button_restarteasytier() {
	var m = document.form.easytier_enable.value;
	var actionMode = (m == "1" || m == "2") ? ' Restarteasytier ' : ' Updateeasytier ';
	change_easytier_enable(m);
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', { 'action_mode': actionMode });
}

function clearLog_EASYTIER(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' CleareasytierLog ',
		'next_host': 'Advanced_vpn.asp#easytier-log'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-log'); }, 3000);
	});
}

function button_et_peer(){
	var $j = jQuery.noConflict();
	$j('#btn_peer').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetpeer ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_connector(){
	var $j = jQuery.noConflict();
	$j('#btn_connector').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetconnector ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_stun(){
	var $j = jQuery.noConflict();
	$j('#btn_stun').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetstun ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_route(){
	var $j = jQuery.noConflict();
	$j('#btn_route').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetroute ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_peer_center(){
	var $j = jQuery.noConflict();
	$j('#btn_peer_center').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetpeer_center ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_vpn_portal(){
	var $j = jQuery.noConflict();
	$j('#btn_vpn_portal').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetvpn_portal ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_node(){
	var $j = jQuery.noConflict();
	$j('#btn_node').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetnode ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_proxy(){
	var $j = jQuery.noConflict();
	$j('#btn_proxy').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetproxy ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_et_status() {
	var $j = jQuery.noConflict();
	$j('#btn_status').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetstatus ',
		'next_host': 'Advanced_vpn.asp#easytier-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#easytier-sta'); }, 3000);
	});
}

function button_etweb(){
	var port = document.form.easytier_html_port.value;
	if (port == '')
		var port = '11210';
	var porturl = window.location.protocol + '//' + window.location.hostname + ":" + port;
	window.open(porturl, 'easytier-web');
}

/* ============ Tailscale ============ */
function fill_status_ts(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("tailscaled_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function fill_status_ts2(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("tailscale_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function change_tailscale_enable(mflag){
	var m = document.form.tailscale_enable.value;
	var is_tailscale_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restarttailscale.value = is_tailscale_enable;

	var is_tailscale_cmd = (m == "2") ? 1 : 0;
	var is_tailscale_df = (m == "1") ? 1 : 0;

	showhide_div("tailscale_cmd_tr", is_tailscale_cmd);
	showhide_div("tailscale_cmd_td", is_tailscale_cmd);
	showhide_div("tailscale_dns_tr", is_tailscale_df);
	showhide_div("tailscale_dns_td", is_tailscale_df);
	showhide_div("tailscale_route_tr", is_tailscale_df);
	showhide_div("tailscale_route_td", is_tailscale_df);
	showhide_div("tailscale_routes_tr", is_tailscale_df);
	showhide_div("tailscale_routes_td", is_tailscale_df);
	showhide_div("tailscale_exit_tr", is_tailscale_df);
	showhide_div("tailscale_exit_td", is_tailscale_df);
	showhide_div("tailscale_exitip_tr", is_tailscale_df);
	showhide_div("tailscale_exitip_td", is_tailscale_df);
	showhide_div("tailscale_server_tr", is_tailscale_df);
	showhide_div("tailscale_server_td", is_tailscale_df);
	showhide_div("tailscale_ssh_tr", is_tailscale_df);
	showhide_div("tailscale_ssh_td", is_tailscale_df);
	showhide_div("tailscale_shields_tr", is_tailscale_df);
	showhide_div("tailscale_shields_td", is_tailscale_df);
	showhide_div("tailscale_host_tr", is_tailscale_df);
	showhide_div("tailscale_host_td", is_tailscale_df);
	showhide_div("tailscale_key_tr", is_tailscale_df);
	showhide_div("tailscale_key_td", is_tailscale_df);
	showhide_div("tailscale_reset_tr", is_tailscale_df);
	showhide_div("tailscale_reset_td", is_tailscale_df);
	showhide_div("tailscale_cmd2_tr", is_tailscale_df);
	showhide_div("tailscale_cmd2_td", is_tailscale_df);
}

function button_restarttailscale() {
	var m = document.form.tailscale_enable.value;
	var actionMode = (m == "1" || m == "2") ? ' Restarttailscale ' : ' Updatetailscale ';
	change_tailscale_enable(m);
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', { 'action_mode': actionMode });
}

function clearLog_TAILSCALE(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' ClearTsLog ',
		'next_host': 'Advanced_vpn.asp#tailscale-log'
	}).always(function() {
		setTimeout(function() { reloadTab('#tailscale-log'); }, 3000);
	});
}

/* ============ VNT 客户端 ============ */
function fill_status_vc(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("vntcli_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function change_vntcli_model(mflag){
	var m = document.form.vntcli_model.value;
	var Showmodel = (m >= 1 && m <= 7);
	showhide_div("vntcli_key_tr", Showmodel);
	showhide_div("vntcli_key_td", Showmodel);
}

function change_vntcli_enable(mflag){
	var m = document.form.vntcli_enable.value;
	var is_vntcli_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restartvntcli.value = is_vntcli_enable;

	if(m == "2"){
		showhide_div("vntcli_file_tr", 1);
		showhide_div("vntcli_token_tr", 0);
		showhide_div("vntcli_token_td", 0);
		showhide_div("vntcli_ip_tr", 0);
		showhide_div("vntcli_ip_td", 0);
		showhide_div("vntcli_localadd_tr", 0);
		showhide_div("vntcli_localadd_td", 0);
		showhide_div("vntcli_serip_tr", 0);
		showhide_div("vntcli_serip_td", 0);
		showhide_div("vntcli_model_tr", 0);
		showhide_div("vntcli_model_td", 0);
		showhide_div("vntcli_key_tr", 0);
		showhide_div("vntcli_key_td", 0);
		showhide_div("vntcli_subnet_table", 0);
		showhide_div("vntcli_proxy_tr", 0);
		showhide_div("vntcli_proxy_td", 0);
		showhide_div("vntcli_first_tr", 0);
		showhide_div("vntcli_first_td", 0);
		showhide_div("vntcli_wg_tr", 0);
		showhide_div("vntcli_wg_td", 0);
		showhide_div("vntcli_finger_tr", 0);
		showhide_div("vntcli_finger_td", 0);
		showhide_div("vntcli_serverw_tr", 0);
		showhide_div("vntcli_serverw_td", 0);
		showhide_div("vntcli_desname_tr", 0);
		showhide_div("vntcli_desname_td", 0);
		showhide_div("vntcli_id_tr", 0);
		showhide_div("vntcli_id_td", 0);
		showhide_div("vntcli_tunname_tr", 0);
		showhide_div("vntcli_tunname_td", 0);
		showhide_div("vntcli_mtu_tr", 0);
		showhide_div("vntcli_mtu_td", 0);
		showhide_div("vntcli_dns_tr", 0);
		showhide_div("vntcli_dns_td", 0);
		showhide_div("vntcli_stun_tr", 0);
		showhide_div("vntcli_stun_td", 0);
		showhide_div("vntcli_port_tr", 0);
		showhide_div("vntcli_port_td", 0);
		showhide_div("vntcli_wan_tr", 0);
		showhide_div("vntcli_wan_td", 0);
		showhide_div("vntcli_punch_tr", 0);
		showhide_div("vntcli_punch_td", 0);
		showhide_div("vntcli_comp_tr", 0);
		showhide_div("vntcli_comp_td", 0);
		showhide_div("vntcli_relay_tr", 0);
		showhide_div("vntcli_relay_td", 0);
		showhide_div("vntcli_disable_relay_tr", 0);
		showhide_div("vntcli_disable_relay_td", 0);
		showhide_div("vntcli_mapping_table", 0);
	}

	if(m == "1"){
		showhide_div("vntcli_file_tr", 0);
		showhide_div("vntcli_token_tr", 1);
		showhide_div("vntcli_token_td", 1);
		showhide_div("vntcli_ip_tr", 1);
		showhide_div("vntcli_ip_td", 1);
		showhide_div("vntcli_localadd_tr", 1);
		showhide_div("vntcli_localadd_td", 1);
		showhide_div("vntcli_serip_tr", 1);
		showhide_div("vntcli_serip_td", 1);
		showhide_div("vntcli_model_tr", 1);
		showhide_div("vntcli_model_td", 1);
		showhide_div("vntcli_key_tr", 1);
		showhide_div("vntcli_key_td", 1);
		showhide_div("vntcli_subnet_table", 1);
		showhide_div("vntcli_proxy_tr", 1);
		showhide_div("vntcli_proxy_td", 1);
		showhide_div("vntcli_first_tr", 1);
		showhide_div("vntcli_first_td", 1);
		showhide_div("vntcli_wg_tr", 1);
		showhide_div("vntcli_wg_td", 1);
		showhide_div("vntcli_finger_tr", 1);
		showhide_div("vntcli_finger_td", 1);
		showhide_div("vntcli_serverw_tr", 1);
		showhide_div("vntcli_serverw_td", 1);
		showhide_div("vntcli_desname_tr", 1);
		showhide_div("vntcli_desname_td", 1);
		showhide_div("vntcli_id_tr", 1);
		showhide_div("vntcli_id_td", 1);
		showhide_div("vntcli_tunname_tr", 1);
		showhide_div("vntcli_tunname_td", 1);
		showhide_div("vntcli_mtu_tr", 1);
		showhide_div("vntcli_mtu_td", 1);
		showhide_div("vntcli_dns_tr", 1);
		showhide_div("vntcli_dns_td", 1);
		showhide_div("vntcli_stun_tr", 1);
		showhide_div("vntcli_stun_td", 1);
		showhide_div("vntcli_port_tr", 1);
		showhide_div("vntcli_port_td", 1);
		showhide_div("vntcli_wan_tr", 1);
		showhide_div("vntcli_wan_td", 1);
		showhide_div("vntcli_punch_tr", 1);
		showhide_div("vntcli_punch_td", 1);
		showhide_div("vntcli_comp_tr", 1);
		showhide_div("vntcli_comp_td", 1);
		showhide_div("vntcli_relay_tr", 1);
		showhide_div("vntcli_relay_td", 1);
		showhide_div("vntcli_disable_relay_tr", 1);
		showhide_div("vntcli_disable_relay_td", 1);
		showhide_div("vntcli_mapping_table", 1);

		o_mtu = document.form.vntcli_mtu;
		if (o_mtu && parseInt(o_mtu.value) == 0)
			o_mtu.value = "";
		if (o_mtu && parseInt(o_mtu.value) > 1500)
			o_mtu.value = "1500";
	}
}

function button_restartvntcli() {
	var m = document.form.vntcli_enable.value;
	var actionMode = (m == "1" || m == "2") ? ' Restartvntcli ' : ' Updatevntcli ';
	change_vntcli_enable(m);
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', { 'action_mode': actionMode });
}

function markrouteRULES(o, c, b) {
	document.form.group_id.value = "VNTCLIroute";
	if(b == " Add "){
		if (document.form.vntcli_routenum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.vntcli_route_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_route_x_0.focus();
			document.form.vntcli_route_x_0.select();
			return false;
		}else if(document.form.vntcli_ip_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_ip_x_0.focus();
			document.form.vntcli_ip_x_0.select();
			return false;
		}else{
			for(i=0; i<m_routelist.length; i++){
				if(document.form.vntcli_route_x_0.value==m_routelist[i][1]) {
				if(document.form.vntcli_ip_x_0.value==m_routelist[i][2]) {
					alert('<#JS_duplicate#>' + ' (' + m_routelist[i][1] + ')' );
					document.form.vntcli_route_x_0.focus();
					document.form.vntcli_ip_x_0.select();
					return false;
					}
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function markmappRULES(o, c, b) {
	document.form.group_id.value = "VNTCLImapp";
	if(b == " Add "){
		if (document.form.vntcli_mappnum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.vntcli_mappport_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mappport_x_0.focus();
			document.form.vntcli_mappport_x_0.select();
			return false;
		}else if(document.form.vntcli_mappip_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mappip_x_0.focus();
			document.form.vntcli_mappip_x_0.select();
			return false;
		}else if(document.form.vntcli_mapeerport_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mapeerport_x_0.focus();
			document.form.vntcli_mapeerport_x_0.select();
			return false;
		}else{
			for(i=0; i<m_mapplist.length; i++){
				if(document.form.vntcli_mappnet_x_0.value==m_mapplist[i][0]) {
					if(document.form.vntcli_mappport_x_0.value==m_mapplist[i][1]) {
						if(document.form.vntcli_mappip_x_0.value==m_mapplist[i][2]) {
							if(document.form.vntcli_mapeerport_x_0.value==m_mapplist[i][3]) {
								alert('<#JS_duplicate#>' + ' (' + m_mapplist[i][1] + ')' );
								document.form.vntcli_mapeerport_x_0.focus();
								document.form.vntcli_mapeerport_x_0.select();
								return false;
							}
						}
					}
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function showROUTEList(){
	var code = '<table width="100%" cellspacing="0" cellpadding="4" class="table table-list">';
	if(m_routelist.length == 0)
		code +='<tr><td colspan="5" style="text-align: center;"><div class="alert alert-info"><#IPConnection_VSList_Norule#></div></td></tr>';
	else{
	    for(var i = 0; i < m_routelist.length; i++){
		code +='<tr id="rowrl' + i + '">';
		code +='<td width="28%">&nbsp;' + m_routelist[i][0] + '</td>';
		code +='<td width="38%">&nbsp;' + m_routelist[i][1] + '</td>';
		code +='<td colspan="2" width="40%">' + m_routelist[i][2] + '</td>';
		code +='<td width="50%"></td>';
		code +='<center><td width="20%" style="text-align: center;"><input type="checkbox" name="VNTCLIroute_s" value="' + m_routelist[i][mroutelist_ifield] + '" onClick="changeBgColorrl(this,' + i + ');" id="check' + m_routelist[i][mroutelist_ifield] + '"></td></center>';
		code +='</tr>';
	    }
		code += '<tr>';
		code += '<td colspan="5">&nbsp;</td>'
		code += '<td><button class="btn btn-danger" type="submit" onclick="markrouteRULES(this, 64, \' Del \');" name="VNTCLIroute"><i class="icon icon-minus icon-white"></i></button></td>';
		code += '</tr>'
	}
	code +='</table>';
	$("MrouteRULESList_Block").innerHTML = code;
}

function showMAPPList(){
	var code = '<table width="100%" cellspacing="0" cellpadding="4" class="table table-list">';
	if(m_mapplist.length == 0)
		code +='<tr><td colspan="5" style="text-align: center;"><div class="alert alert-info"><#IPConnection_VSList_Norule#></div></td></tr>';
	else{
	    for(var i = 0; i < m_mapplist.length; i++){
		if(m_mapplist[i][0] == 0)
		vntcli_mappnet="TCP";
		else{
		vntcli_mappnet="UDP";
		}
		code +='<tr id="rowrl' + i + '">';
		code +='<td width="15%">&nbsp;' + vntcli_mappnet + '</td>';
		code +='<td width="25%">&nbsp;' + m_mapplist[i][1] + '</td>';
		code +='<td width="30%">' + m_mapplist[i][2] + '</td>';
		code +='<td width="20%">&nbsp;' + m_mapplist[i][3] + '</td>';
		code +='<td width="50%"></td>';
		code +='<center><td width="20%" style="text-align: center;"><input type="checkbox" name="VNTCLImapp_s" value="' + m_mapplist[i][mmapplist_ifield] + '" onClick="changeBgColorrl(this,' + i + ');" id="check' + m_mapplist[i][mmapplist_ifield] + '"></td></center>';
		code +='</tr>';
	    }
		code += '<tr>';
		code += '<td colspan="5">&nbsp;</td>'
		code += '<td><button class="btn btn-danger" type="submit" onclick="markmappRULES(this, 64, \' Del \');" name="VNTCLImapp"><i class="icon icon-minus icon-white"></i></button></td>';
		code += '</tr>'
	}
	code +='</table>';
	$("MmappRULESList_Block").innerHTML = code;
}

function clearLog_VNTCLI(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' ClearvntcliLog ',
		'next_host': 'Advanced_vpn.asp#vntcli-log'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-log'); }, 3000);
	});
}

function button_vntcli_info(){
	var $j = jQuery.noConflict();
	$j('#btn_info').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDvntinfo ',
		'next_host': 'Advanced_vpn.asp#vntcli-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-sta'); }, 3000);
	});
}

function button_vntcli_all(){
	var $j = jQuery.noConflict();
	$j('#btn_all').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDvntall ',
		'next_host': 'Advanced_vpn.asp#vntcli-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-sta'); }, 3000);
	});
}

function button_vntcli_list(){
	var $j = jQuery.noConflict();
	$j('#btn_list').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDvntlist ',
		'next_host': 'Advanced_vpn.asp#vntcli-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-sta'); }, 3000);
	});
}

function button_vntcli_route(){
	var $j = jQuery.noConflict();
	$j('#btn_vc_route').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDvntroute ',
		'next_host': 'Advanced_vpn.asp#vntcli-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-sta'); }, 3000);
	});
}

function button_vntcli_status() {
	var $j = jQuery.noConflict();
	$j('#btn_vc_status').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDvntstatus ',
		'next_host': 'Advanced_vpn.asp#vntcli-sta'
	}).always(function() {
		setTimeout(function() { reloadTab('#vntcli-sta'); }, 3000);
	});
}

/* ============ VNT 服务端 ============ */
function fill_status_vs(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("vnts_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function change_vnts_web_enable_bridge(mflag){
	var m = document.form.vnts_web_enable[0].checked;
	showhide_div("vnts_web_port_tr", m);
	showhide_div("vnts_web_user_tr", m);
	showhide_div("vnts_web_pass_tr", m);
	showhide_div("vnts_web_wan_tr", m);
}

function change_vnts_enable(mflag){
	var m = document.form.vnts_enable.value;
	var is_vnts_enable = (m == "1") ? "重启" : "更新";
	document.form.restartvnts.value = is_vnts_enable;
}

function button_restartvnts() {
	var m = document.form.vnts_enable.value;
	var actionMode = (m == "1") ? ' Restartvnts ' : ' Updatevnts ';
	change_vnts_enable(m);
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', { 'action_mode': actionMode });
}

function clearLog_VNTS(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' ClearvntsLog ',
		'next_host': 'Advanced_vpn.asp#vnts-log'
	}).always(function() {
		setTimeout(function() { reloadTab('#vnts-log'); }, 3000);
	});
}

function button_vnts_web(){
	var port = document.form.vnts_web_port.value;
	if (port == '')
		var port = '29870';
	var porturl = window.location.protocol + '//' + window.location.hostname + ":" + port;
	window.open(porturl, 'vnts_web');
}

/* ============ NPC 内网穿透 ============ */
function fill_status_npc(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("npc_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function change_npc_enable_bridge(mflag){
	var m = document.form.npc_enable[0].checked;
	showhide_div("npc_protocol_tr", m);
	showhide_div("npc_vkey_tr", m);
	showhide_div("npc_server_addr_tr", m);
	showhide_div("npc_server_port_tr", m);
	showhide_div("npc_compress_tr", m);
	showhide_div("npc_crypt_tr", m);
	showhide_div("npc_log_level_tr", m);
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
	<div class="container-fluid" style="padding-right: 0px">
		<div class="row-fluid">
			<div class="span3"><center><div id="logo"></div></center></div>
			<div class="span9" >
				<div id="TopBanner"></div>
			</div>
		</div>
	</div>

	<div id="Loading" class="popup_bg"></div>

	<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

	<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

	<input type="hidden" name="current_page" value="Advanced_vpn.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="EASYTIER;TAILSCALE;VNTCLI;VNTS;NpcConf;LANHostConfig;General;">
	<input type="hidden" name="group_id" value="VNTCLIroute;VNTCLImapp">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="wan_ipaddr" value="<% nvram_get_x("", "wan0_ipaddr"); %>" readonly="1">
	<input type="hidden" name="wan_netmask" value="<% nvram_get_x("", "wan0_netmask"); %>" readonly="1">
	<input type="hidden" name="dhcp_start" value="<% nvram_get_x("", "dhcp_start"); %>">
	<input type="hidden" name="dhcp_end" value="<% nvram_get_x("", "dhcp_end"); %>">
	<input type="hidden" name="vntcli_routenum_x_0" value="<% nvram_get_x("VNTCLIroute", "vntcli_routenum_x"); %>" readonly="1" />
	<input type="hidden" name="vntcli_mappnum_x_0" value="<% nvram_get_x("VNTCLImapp", "vntcli_mappnum_x"); %>" readonly="1" />

	<div class="container-fluid">
		<div class="row-fluid">
			<div class="span3">
				<!--Sidebar content-->
				<!--=====Beginning of Main Menu=====-->
				<div class="well sidebar-nav side_nav" style="padding: 0px;">
					<ul id="mainMenu" class="clearfix"></ul>
					<ul class="clearfix">
						<li>
							<div id="subMenu" class="accordion"></div>
						</li>
					</ul>
				</div>
			</div>

			<div class="span9">
				<!--Body content-->
				<div class="row-fluid">
					<div class="span12">
						<div class="box well grad_colour_dark_blue">
							<h2 class="box_head round_top">组网服务</h2>
							<div class="round_bottom">
								<div>
									<ul class="nav nav-tabs" style="margin-bottom: 10px;">
										<li class="active"><a class="svctab" id="tab_net_easytier" href="#easytier">EasyTier</a></li>
										<li><a class="svctab" id="tab_net_tailscale" href="#tailscale">Tailscale</a></li>
										<li><a class="svctab" id="tab_net_vntcli" href="#vntcli">VNT客户端</a></li>
										<li><a class="svctab" id="tab_net_vnts" href="#vnts">VNT服务端</a></li>
										<li><a class="svctab" id="tab_net_npc" href="#npc">NPC内网穿透</a></li>
										<li><a class="svctab" id="tab_net_wireguard" href="#wireguard">WireGuard</a></li>
									</ul>
								</div>

								<!-- ============ EasyTier ============ -->
								<div id="wnd_net_easytier">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a class="subtab" id="tab_et_cfg" href="#easytier-cfg">基本设置</a></li>
	<li><a class="subtab" id="tab_et_web" href="#easytier-web">自建WEB</a></li>
	<li><a class="subtab" id="tab_et_sta" href="#easytier-sta">运行状态</a></li>
	<li><a class="subtab" id="tab_et_log" href="#easytier-log">运行日志</a></li>

	</ul>
	</div>
	<div class="row-fluid">
	<div id="wnd_et_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	由 Rust 和 Tokio 驱动✨ 一个简单、安全、去中心化的异地组网方案。<br>
	<div>项目地址：<a href="https://github.com/EasyTier/Easytier" target="blank">github.com/EasyTier/Easytier</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://easytier.cn/" target="blank">easytier.cn</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=6fJoWLm7bKKBHnx0uPKjFBeQz-UVpCVZ&authKey=Zp4K7V7UQfADF6UJdP%2FgoGAhuv%2FT5qGlx%2FZEuQsOmIiiF1p8piy6lfDZnoxTaKH6&noverify=0&group_code=949700262" target="blank">949700262</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "easytier_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "easytier_ver_n"); %></span>】 </div>
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="easytier_status"></td><td></td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用easytier</th>
	<td style="border-top: 0 none;">
	<select name="easytier_enable" class="input" onChange="change_easytier_enable();" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","easytier_enable", "1","selected"); %>>【开启】WEB配置</option>
	<option value="2" <% nvram_match_x("","easytier_enable", "2","selected"); %>>【开启】配置文件</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restarteasytier" value="更新" onclick="button_restarteasytier()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基本设置</th>
	</tr>
	<tr id="easytier_file_tr">
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.easytier')"><span>点此修改 /etc/storage/easytier.toml 配置文件</span></a>&nbsp;&nbsp;&nbsp;&nbsp;配置文件生成器：<a href="https://easytier.cn/web/index.html#/config_generator" target="blank">点此跳转</a>
	<div id="scripts.easytier" style="display: none;">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="2097152" class="span12" name="scripts.easytier.toml" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.easytier.toml",""); %></textarea>
	</div>
	</td>
	</tr><tr id="easytier_file_td"><td colspan="3"></td></tr>
	<tr id="config_server_tr">
	<th width="30%" style="border-top: 0 none;" title="-w  配置Web服务器地址。格式：①完整URL： udp://127.0.0.1:22020/admin  ②仅用户名： admin，将使用官方的服务器">Web服务器地址</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="admin" id="easytier_config_server" name="easytier_config_server" value="<% nvram_get_x("","easytier_config_server"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" value="官方Web控制台" onclick="window.open('https://easytier.cn/web', '_blank')" />
	</td>
	</tr><tr id="config_server_td"><td colspan="3"></td></tr>
	<tr id="hostname_tr">
	<th width="30%" style="border-top: 0 none;" title="--hostname  指定主机名，用于在web控制台识别设备的名称">主机名</th>
	<td style="border-top: 0 none;">
	<input name="easytier_hostname" type="text" class="input" id="easytier_hostname" placeholder="<% nvram_get_x("","computer_name"); %>" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_hostname"); %>" size="32" maxlength="35" /></td>
	</td>
	</tr><tr id="hostname_td"><td colspan="3"></td></tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_bin" id="easytier_bin" placeholder="/etc/storage/bin/easytier-core" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_bin"); %></textarea>
	</td><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr id="log_tr"> 
	<th width="30%" style="border-top: 0 none;" title="--console-log-level  控制台日志级别">日志等级</th>
	<td style="border-top: 0 none;">
	<select name="easytier_log" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_log", "0","selected"); %>>默认</option>
	<option value="1" <% nvram_match_x("","easytier_log", "1","selected"); %>>警告</option>
	<option value="2" <% nvram_match_x("","easytier_log", "2","selected"); %>>信息</option>
	<option value="3" <% nvram_match_x("","easytier_log", "3","selected"); %>>调试</option>
	<option value="4" <% nvram_match_x("","easytier_log", "4","selected"); %>>跟踪</option>
	<option value="5" <% nvram_match_x("","easytier_log", "5","selected"); %>>错误</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="使用配置文件和WEB控制台时务必填写一致，用于自动放行所需的端口，默认放行ipv4和ipv6的。">端口放行</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="256" class="input" name="easytier_ports" id="easytier_ports" placeholder="11010" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_ports"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个端口使用换行分隔</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="--dev-name  指定TUN接口名称，使用配置文件和WEB控制台时务必填写一致，用于放行防火墙">TUN网卡名</th>
	<td style="border-top: 0 none;">
	<input name="easytier_tunname" type="text" class="input" id="easytier_tunname" placeholder="tun0" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_tunname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr><br>																
	</table>
	</div>
	</div>
	<!-- WEB设置 -->
	<div id="wnd_et_web" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
<div class="alert alert-info" style="margin: 10px;">
	自建WEB服务器，需要自行下载easytier-web-embed程序并更名为easytier-web上传并指定路径，也会自动在线下载。<br>
	</div>
	<table id="web_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="easytier_web_status"></td><td></td>
	</tr>
	<tr>
	<th style="border-top: 0 none;">启用WEB</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="easytier_web_enable_on_of">
	<input type="checkbox" id="easytier_web_enable_fake" <% nvram_match_x("", "easytier_web_enable", "1", "value=1 checked"); %><% nvram_match_x("", "easytier_web_enable", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="easytier_web_enable" id="easytier_web_enable_1" class="input" value="1" <% nvram_match_x("", "easytier_web_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="easytier_web_enable" id="easytier_web_enable_0" class="input" value="0" <% nvram_match_x("", "easytier_web_enable", "0", "checked"); %> /><#checkbox_No#>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基本设置</th>
	</tr>
	<td colspan="2"></td>
	<tr>
	<th style="border: 0 none;" title="-d  sqlite3数据库文件路径, 用于保存所有数据">数据库路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_db" id="easytier_web_db" placeholder="/etc/storage/easytier/et.db" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_db"); %></textarea>
	</div><br><span style="color:#888;">自定义数据库的存放路径，填写完整的路径和文件名称</span>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-c  配置服务器的监听端口，用于被 easytier-core 连接">服务端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_port" type="text" class="input" id="easytier_web_port" placeholder="22020" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_port"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-p   配置服务器的监听协议，用于被 easytier-core 连接, 可能的值：udp, tcp, ws">监听协议</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_protocol" type="text" class="input" id="easytier_web_protocol" placeholder="udp" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_protocol"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-a  restful 服务器的监听端口，作为 ApiHost 并被 web 前端使用">API端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_api" type="text" class="input" id="easytier_web_api" placeholder="11211" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_api"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-l  web 前端使用的端口">WEB端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_html_port" type="text" class="input" id="easytier_html_port" placeholder="11210" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_html_port"); %>" size="32" maxlength="55" />
	&nbsp;<input class="btn btn-success" style="" type="button" value="打开WEB控制台" onclick="button_etweb()" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="--api-host  API 服务器的 URL，用于 web 前端连接">API服务器URL</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_api_host" id="easytier_api_host" placeholder="https://config-server.easytier.cn" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_api_host"); %></textarea>
	</tr><td colspan="3"></td>
	<tr> 
	<th style="border: 0 none;" title="--geoip-db  数据库文件路径，用于查找客户端的位置，默认为嵌入文件（仅国家信息），推荐https://github.com/P3TERX/GeoLite.mmdb">IP数据库</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_geoip" id="easytier_geoip" placeholder="/etc/storage/easytier/GeoLite.mmdb" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_geoip"); %></textarea>
	</tr><td colspan="3"></td>
	<tr> 
	<th style="border: 0 none;" title="你可以通过-h获取控制台程序的参数，这里可以添加上述没有的参数，例如：--disable-registration --allow-auto-create-user">额外参数</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_extra_args" id="easytier_extra_args" placeholder="--allow-auto-create-user" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_extra_args"); %></textarea>
	</tr><td colspan="3"></td>
	<tr> 
	<th width="30%" style="border-top: 0 none;" title="--console-log-level  控制台日志级别">日志等级</th>
	<td style="border-top: 0 none;">
	<select name="easytier_web_log" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_web_log", "0","selected"); %>>默认</option>
	<option value="1" <% nvram_match_x("","easytier_web_log", "1","selected"); %>>警告</option>
	<option value="2" <% nvram_match_x("","easytier_web_log", "2","selected"); %>>信息</option>
	<option value="3" <% nvram_match_x("","easytier_web_log", "3","selected"); %>>调试</option>
	<option value="4" <% nvram_match_x("","easytier_web_log", "4","selected"); %>>跟踪</option>
	<option value="5" <% nvram_match_x("","easytier_web_log", "5","selected"); %>>错误</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<!-- <th style="border: 0 none;">html路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_html" id="easytier_web_html" placeholder="/etc/storage/easytier/web.html" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_html"); %></textarea>
	</div><br><span style="color:#888;">自定义前端html的存放路径，填写完整的路径和文件名称</span>
	</tr><td colspan="3"></td> -->
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_bin" id="easytier_web_bin" placeholder="/etc/storage/bin/easytier-web" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr>	<td style="border-top: 0 none;">


	<tr>
	<td colspan="5" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('weblog')"><span>查看WEB日志 /tmp/easytier_web.log</span></a>
	<div id="weblog" style="display: none;">
		<textarea rows="21" class="span12" style="height:219px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier_web.log",""); %></textarea>
	</td>
	</tr>
	</table>
	</table>
	<!-- 状态 -->
	<div id="wnd_et_sta" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
		<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
			<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier_cmd.log",""); %></textarea>
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center;">
			<!-- 按钮并排显示 -->
			<input class="btn btn-success" id="btn_peer" style="width:100px; margin-right: 10px;" type="button" name="et_peer" value="节点信息" onclick="button_et_peer()" />
			<input class="btn btn-success" id="btn_connector" style="width:100px; margin-right: 10px;" type="button" name="et_connector" value="连接器" onclick="button_et_connector()" />
		<input class="btn btn-success" id="btn_stun" style="width:100px; margin-right: 10px;" type="button" name="et_stun" value="STUN 信息" onclick="button_et_stun()" />
			<input class="btn btn-success" id="btn_route" style="width:100px; margin-right: 10px;" type="button" name="et_route" value="路由信息" onclick="button_et_route()" />
			<input class="btn btn-success" id="btn_peer_center" style="width:100px; margin-right: 10px;" type="button" name="et_peer_center" value="全局节点" onclick="button_et_peer_center()" />
			<input class="btn btn-success" id="btn_vpn_portal" style="width:100px; margin-right: 10px;" type="button" name="et_vpn_portal" value="WireGuard信息" onclick="button_et_vpn_portal()" />
			<input class="btn btn-success" id="btn_node" style="width:100px; margin-right: 10px;" type="button" name="et_node" value="本机信息" onclick="button_et_node()" />
			<input class="btn btn-success" id="btn_proxy" style="width:100px; margin-right: 10px;" type="button" name="et_proxy" value="代理信息" onclick="button_et_proxy()" />
			<input class="btn btn-success" id="btn_status" style="width:100px; margin-right: 10px;" type="button" name="et_status" value="运行状态" onclick="button_et_status()" />
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 5px;">
			<span style="color:#888;">🔄 点击上方按钮刷新查看</span>
		</td>
	</tr>
	</table>
	</div>

	<!-- 日志 -->
	<div id="wnd_et_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="reloadTab('#easytier-log')" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='easytier.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog_EASYTIER();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志可能包含一些隐私信息，切勿随意分享！</span>
	</td>
	</table>
	</div>

								</div>

								<!-- ============ Tailscale ============ -->
								<div id="wnd_net_tailscale" style="display:none">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a class="subtab" id="tab_tailscale_cfg" href="#tailscale-cfg">基本设置</a></li>
	<li><a class="subtab" id="tab_tailscale_log" href="#tailscale-log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="wnd_tailscale_cfg">
	<div class="alert alert-info" style="margin: 10px;">Tailscale  让您可以轻松管理对私有资源的访问，快速通过 SSH 连接到您网络上的设备，网络变得简单。
	<div>项目地址：<a href="https://github.com/tailscale/tailscale" target="blank">https://github.com/tailscale/tailscale</a></div>
  		<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "tailscale_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "tailscale_ver_n"); %></span>】 &nbsp;&nbsp;<a href="<% nvram_get_x("", "tailscale_login"); %>" target="blank"><% nvram_get_x("", "tailscale_login"); %></a>
  		<br>&nbsp;<% nvram_get_x("", "tailscale_info"); %>
	</div>
	
	<span style="color:#FF0000;" class=""></span></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">运行状态</th>
	</tr>
	<tr> <th>tailscaled</th>
            <td id="tailscaled_status" colspan="2"></td>
          </tr>
	<tr> <th>tailscale</th>
            <td id="tailscale_status" colspan="2"></td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">程序配置</th>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用Tailscale</th>
	<td style="border-top: 0 none;">
	<select name="tailscale_enable" class="input" onChange="change_tailscale_enable();" style="width: 185px;">
	<option value="0" <% nvram_match_x("","tailscale_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","tailscale_enable", "1","selected"); %>>【开启】</option>
	<option value="2" <% nvram_match_x("","tailscale_enable", "2","selected"); %>>【开启】Tailscale 自定义参数</option>
	<option value="3" <% nvram_match_x("","tailscale_enable", "3","selected"); %>>【重置】恢复初始化</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restarttailscale" value="更新" onclick="button_restarttailscale()" />
	</td>
	</tr><td colspan="3"></td>
	<tr id="tailscale_cmd_tr">
	<th width="30%" style="border-top: 0 none;">自定义参数启动
	</th>
	<td colspan="4" style="border-top: 0 none;">
	<textarea maxlength="1024" class="input" name="tailscale_cmd" id="tailscale_cmd" placeholder="up --accept-dns=false --accept-routes --advertise-routes=192.168.2.0/24 --advertise-exit-node --reset" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_cmd"); %></textarea>
	&nbsp;<a href="https://tailscale.com/kb/1241/tailscale-up/" target="blank">命令参数说明</a><br>&nbsp;<span style="color:#888;">直接填写启动命令 不需要路径和程序名。</span>
	</td>
	</tr><tr id="tailscale_cmd_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_dns_tr" >
	<th style="border-top: 0 none;">接受DNS设置</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_dns_on_of">
	<input type="checkbox" id="tailscale_dns_fake" <% nvram_match_x("", "tailscale_dns", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_dns", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="tailscale_dns" id="tailscale_dns_1" class="input" value="1" <% nvram_match_x("", "tailscale_dns", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="tailscale_dns" id="tailscale_dns_0" class="input" value="0" <% nvram_match_x("", "tailscale_dns", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_dns_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_route_tr" >
	<th style="border-top: 0 none;">接受路由</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_route_on_of">
	<input type="checkbox" id="tailscale_route_fake" <% nvram_match_x("", "tailscale_route", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_route", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">接受其他节点公布的子网路由</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_route" id="tailscale_route_1" class="input" value="1" <% nvram_match_x("", "tailscale_route", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_route" id="tailscale_route_0" class="input" value="0" <% nvram_match_x("", "tailscale_route", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_route_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_routes_tr">
	<th width="30%" style="border-top: 0 none;">本地子网</th>
	<td colspan="4" style="border-top: 0 none;">
		<textarea maxlength="1024" class="input" name="tailscale_routes" id="tailscale_routes" placeholder="192.168.2.0/24,192.168.123.0/24" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_routes"); %></textarea>
	<br>&nbsp;<span style="color:#888;">公布本地子网路由，多个网段使用英文,分隔</span>
	</td>
	</tr><tr id="tailscale_routes_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_exit_tr" >
	<th style="border-top: 0 none;">启用出口节点</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_exit_on_of">
	<input type="checkbox" id="tailscale_exit_fake" <% nvram_match_x("", "tailscale_exit", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_exit", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">使本机成为流量出口节点</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_exit" id="tailscale_exit_1" class="input" value="1" <% nvram_match_x("", "tailscale_exit", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_exit" id="tailscale_exit_0" class="input" value="0" <% nvram_match_x("", "tailscale_exit", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_exit_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_exitip_tr">
	<th width="30%" style="border-top: 0 none;">出口节点地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="128" class="input" size="15" placeholder="" id="tailscale_exitip" name="tailscale_exitip" value="<% nvram_get_x("","tailscale_exitip"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">指定流量出口的节点</span>
	</td>
	</tr><tr id="tailscale_exitip_td"><td colspan="3"></td></tr>
	<tr id="tailscale_server_tr">
	<th width="30%" style="border-top: 0 none;">控制服务器地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="256" class="input" size="15" placeholder="https://controlplane.tailscale.com" id="tailscale_server" name="tailscale_server" value="<% nvram_get_x("","tailscale_server"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">控制服务器的地址，如果您将 Headscale 用于控制服务器，请使用 Headscale 实例的 URL</span>
	</td>
	</tr><tr id="tailscale_server_td"><td colspan="3"></td></tr>
	<tr id="tailscale_ssh_tr" >
	<th style="border-top: 0 none;">启用ssh服务器</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_ssh_on_of">
	<input type="checkbox" id="tailscale_ssh_fake" <% nvram_match_x("", "tailscale_ssh", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_ssh", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">运行 Tailscale SSH 服务器</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_ssh" id="tailscale_ssh_1" class="input" value="1" <% nvram_match_x("", "tailscale_ssh", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_ssh" id="tailscale_ssh_0" class="input" value="0" <% nvram_match_x("", "tailscale_ssh", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_ssh_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_shields_tr" >
	<th style="border-top: 0 none;">仅传出连接</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_shields_on_of">
		<input type="checkbox" id="tailscale_shields_fake" <% nvram_match_x("", "tailscale_shields", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_shields", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">启用后将阻止来自 Tailscale 网络上其他设备的传入连接。对于仅建立传出连接的个人设备很有用。</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_shields" id="tailscale_shields_1" class="input" value="1" <% nvram_match_x("", "tailscale_shields", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_shields" id="tailscale_shields_0" class="input" value="0" <% nvram_match_x("", "tailscale_shields", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_shields_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_host_tr">
	<th width="30%" style="border-top: 0 none;">设备名称</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="50" class="input" size="15" placeholder="<% nvram_get_x("","computer_name"); %>" id="tailscale_host" name="tailscale_host" value="<% nvram_get_x("","tailscale_host"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">指定本机设备名称，方便区分设备</span>
	</td>
	</tr><tr id="tailscale_host_td"><td colspan="3"></td></tr>
	<tr id="tailscale_key_tr">
	<th width="30%" style="border-top: 0 none;">身份验证密钥</th>
	<td style="border-top: 0 none;">
		<textarea maxlength="1024" class="input" name="tailscale_key" id="tailscale_key" placeholder="" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_key"); %></textarea>
	<br>&nbsp;<span style="color:#888;">填写身份验证密钥以自动将节点验证为您的用户账户</span>
	</td>
	</tr><tr id="tailscale_key_td"><td colspan="3"></td></tr>
	<tr id="tailscale_reset_tr" >
	<th style="border-top: 0 none;">重置默认值</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_reset_on_of">
	<input type="checkbox" id="tailscale_reset_fake" <% nvram_match_x("", "tailscale_reset", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_reset", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">将未使用的参数重置为默认值</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_reset" id="tailscale_reset_1" class="input" value="1" <% nvram_match_x("", "tailscale_reset", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_reset" id="tailscale_reset_0" class="input" value="0" <% nvram_match_x("", "tailscale_reset", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_reset_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_cmd2_tr">
	<th width="30%" style="border-top: 0 none;">额外参数
	</th>
	<td colspan="4" style="border-top: 0 none;">
	<textarea maxlength="1024" class="input" name="tailscale_cmd2" id="tailscale_cmd2" placeholder="--netfilter-mode --exit-node-allow-lan-access" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_cmd2"); %></textarea>
	<br>&nbsp;<span style="color:#888;">上述选项缺少的参数，额外补充参数命令</span>
	</td>
	</tr><tr id="tailscale_cmd2_td" ><td colspan="3"></td></tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
		<textarea maxlength="1024"class="input" name="tailscale_bin" id="tailscale_bin" placeholder="/etc/storage/bin/tailscaled" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_bin"); %></textarea>
	</td><br><span style="color:#888;">自定义主程序的存放路径，填写完整的路径和主程序名称</span>
	</tr><td colspan="3"></td>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td>
	</tr>
	
	</table>
	</div>
	</div>
	<div id="wnd_tailscale_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
		<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("tailscale.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="reloadTab();" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog_TAILSCALE();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	</table>
								</div>
								</div>

								<!-- ============ VNT 客户端 ============ -->
								<div id="wnd_net_vntcli" style="display:none">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a class="subtab" id="tab_vntcli_cfg" href="#vntcli-cfg">基本设置</a></li>
	<li><a class="subtab" id="tab_vntcli_pri" href="#vntcli-pri">高级设置</a></li>
	<li><a class="subtab" id="tab_vntcli_sta" href="#vntcli-sta">运行状态</a></li>
	<li><a class="subtab" id="tab_vntcli_log" href="#vntcli-log">运行日志</a></li>
	<li><a class="subtab" id="tab_vntcli_help" href="#vntcli-help">帮助说明</a></li>

	</ul>
	</div>
	<div class="row-fluid">
	<div id="wnd_vntcli_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	vnt是一个简便高效的异地组网、内网穿透工具。&nbsp;&nbsp;&nbsp;&nbsp;安卓、Windows客户端：<a href="https://github.com/vnt-dev/VntApp" target="blank">VntApp</a><br>
	<div>项目地址：<a href="https://github.com/vnt-dev/vnt" target="blank">github.com/vnt-dev/vnt</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://rustvnt.com" target="blank">rustvnt.com</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群1：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=9aa1l03sqBPU-rMIzJ52gcmjq9HsO0tA&authKey=FFA0UdK6Dg1wAvL4e9FvyEu3DxekIlYp9W4NaQ54DO2dzQM%2BKS3rShUSwt9BN0bL&noverify=0&group_code=1034868233" target="blank">1034868233</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群2：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=H4czBrp-IUxgTJ9wem0eXFHPdADkKTVW&authKey=JXU4v4ZQSXupcHOYUCOVgU0rDUdEe1ZfGVWzRVqRecxXY4cg%2BgfHl7n%2F%2F6nGSDH2&noverify=0&group_code=950473757" target="blank">950473757</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "vntcli_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "vntcli_ver_n"); %></span>】 </div>
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="vntcli_status"></td><td></td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用vnt-cli</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_enable" class="input" onChange="change_vntcli_enable();" style="width: 218px;">
	<option value="0" <% nvram_match_x("","vntcli_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","vntcli_enable", "1","selected"); %>>【开启】</option>
	<option value="2" <% nvram_match_x("","vntcli_enable", "2","selected"); %>>【开启】配置文件</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartvntcli" value="更新" onclick="button_restartvntcli()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基础设置</th>
	</tr>
	<tr id="vntcli_file_tr" style="display:none">
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.vnt')"><span>点此修改 /etc/storage/vnt.conf 配置文件</span></a>&nbsp;&nbsp;&nbsp;&nbsp;配置文件模板：<a href="https://github.com/vnt-dev/vnt/blob/main/vnt-cli/README.md#-f-conf" target="blank">点此查看</a>
	<div id="scripts.vnt">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="2097152" class="span12" name="scripts.vnt.conf" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.vnt.conf",""); %></textarea>
	</div>
	</td>
	</tr>
	<tr id="vntcli_token_tr">
	<th width="30%" style="border-top: 0 none;">Token</th>
	<td style="border-top: 0 none;">
	<input type="password" maxlength="63" class="input" size="15" id="vntcli_token" name="vntcli_token" style="width: 180px;" value="<% nvram_get_x("","vntcli_token"); %>" onKeyPress="return is_string(this,event);" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vntcli_token')"><i class="icon-eye-close"></i></button>&nbsp;<span style="color:#888;">必填项</span>
	</td>
	</tr><tr id="vntcli_token_td"><td colspan="3"></td></tr>
	<tr id="vntcli_ip_tr">
	<th width="30%" style="border-top: 0 none;">接口IP</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="10.26.0.2" id="vntcli_ip" name="vntcli_ip" value="<% nvram_get_x("","vntcli_ip"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><tr id="vntcli_ip_td"><td colspan="3"></td></tr>
	<tr id="vntcli_localadd_tr">
	<th width="30%" style="border-top: 0 none;">本地网段</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="256" class="input" name="vntcli_localadd" id="vntcli_localadd" placeholder="192.168.2.0/24" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_localadd"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个网段使用换行分隔</span>
	</td>
	</tr><tr id="vntcli_localadd_td"><td colspan="3"></td></tr>
	<tr id="vntcli_serip_tr">
	<th width="30%" style="border-top: 0 none;">服务器地址</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="tcp://vnt.wherewego.top:29872" id="vntcli_serip" name="vntcli_serip" value="<% nvram_get_x("","vntcli_serip"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><tr id="vntcli_serip_td"><td colspan="3"></td></tr>
	<tr id="vntcli_model_tr">
	<th width="30%" style="border-top: 0 none;">加密方式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_model" class="input" onChange="change_vntcli_model();" style="width: 218px;">
	<option value="0" <% nvram_match_x("","vntcli_model", "0","selected"); %>>不加密</option>
	<option value="1" <% nvram_match_x("","vntcli_model", "1","selected"); %>>xor</option>
	<option value="2" <% nvram_match_x("","vntcli_model", "2","selected"); %>>aes_ecb</option>
	<option value="3" <% nvram_match_x("","vntcli_model", "3","selected"); %>>chacha20</option>
	<option value="4" <% nvram_match_x("","vntcli_model", "4","selected"); %>>chacha20_poly1305</option>
	<option value="5" <% nvram_match_x("","vntcli_model", "5","selected"); %>>sm4_cbc</option>
	<option value="6" <% nvram_match_x("","vntcli_model", "6","selected"); %>>aes_cbc</option>
	<option value="7" <% nvram_match_x("","vntcli_model", "7","selected"); %>>aes_gcm</option>
	</select>
	</td>
	</tr>
	<tr id="vntcli_key_tr">
	<th width="30%" style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;密码</th>
	<td style="border-top: 0 none;">
	<input type="password" maxlength="256" class="input" size="15" id="vntcli_key" name="vntcli_key" style="width: 180px;" value="<% nvram_get_x("","vntcli_key"); %>" onKeyPress="return is_string(this,event);" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vntcli_key')"><i class="icon-eye-close"></i></button><br>&nbsp;<span style="color:#888;">不要使用 <span style="color: yellow;">;</span> 符号</span>
	</td>
	</tr><tr id="vntcli_log_td"><td colspan="3"></td></tr>
	<tr id="vntcli_log_tr">
	<th style="border-top: 0 none;">启用日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_log_on_of">
	<input type="checkbox" id="vntcli_log_fake" <% nvram_match_x("", "vntcli_log", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_log", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_log" id="vntcli_log_1" class="input" value="1" <% nvram_match_x("", "vntcli_log", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_log" id="vntcli_log_0" class="input" value="0" <% nvram_match_x("", "vntcli_log", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="vntcli_log_td"><td colspan="3"></td></tr>
	<table id="vntcli_subnet_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th colspan="4" style="background-color: #756c78;">子网配置 (访问对端内网设备，还需对端配置本地网段)</th></tr>
	<tr id="row_rules_caption">
	<th width="10%"> 备注名称 </th>
	<th width="20%">对端目标网段 </th>
	<th width="20%">对端接口IP </th>
	<th width="5%"><center><i class="icon-th-list"></i></center></th>
	</tr>
	<tr>
	<th><input type="text" placeholder="可留空" maxlength="128" class="span12" style="width: 100px" size="200" name="vntcli_name_x_0" value="<% nvram_get_x("", "vntcli_name_x_0"); %>"/></th>
	<th><input type="text" placeholder="192.168.2.0/24" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_route_x_0" value="<% nvram_get_x("", "vntcli_route_x_0"); %>"/></th>
	<th><input type="text" placeholder="10.26.0.2" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_ip_x_0" value="<% nvram_get_x("", "vntcli_ip_x_0"); %>" /></th>
	<th><button class="btn" style="max-width: 219px" type="submit" onclick="return markrouteRULES(this, 64, ' Add ');" name="markrouteRULES2" value="<#CTL_add#>" size="12"><i class="icon icon-plus"></i></button></th>
	</tr>
	<tr id="row_rules_body" >
	<td colspan="4" style="border-top: 0 none; padding: 0px;">
	<div id="MrouteRULESList_Block"></div>
	</td>
	</tr>
	</table>
	<tr>
	<td colspan="4" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr><br>																
	</table>
	</div>
	</div>
	<!-- 高级设置 -->
	<div id="wnd_vntcli_pri" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<table id="vntcli_pri_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">进阶设置</th>
	</tr>
	<tr id="vntcli_proxy_tr">
	<th style="border-top: 0 none;">启用IP转发</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_proxy_on_of">
	<input type="checkbox" id="vntcli_proxy_fake" <% nvram_match_x("", "vntcli_proxy", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_proxy", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_proxy" id="vntcli_proxy_1" class="input" value="1" <% nvram_match_x("", "vntcli_proxy", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_proxy" id="vntcli_proxy_0" class="input" value="0" <% nvram_match_x("", "vntcli_proxy", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td id="vntcli_proxy_td" colspan="2"></td>
	<tr id="vntcli_first_tr">
	<th style="border-top: 0 none;">启用优化传输</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_first_on_of">
	<input type="checkbox" id="vntcli_first_fake" <% nvram_match_x("", "vntcli_first", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_first", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_first" id="vntcli_first_1" class="input" value="1" <% nvram_match_x("", "vntcli_first", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_first" id="vntcli_first_0" class="input" value="0" <% nvram_match_x("", "vntcli_first", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2" id="vntcli_first_td"></td>
	<tr id="vntcli_wg_tr">
	<th style="border-top: 0 none;">允许WireGuard访问</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_wg_on_of">
	<input type="checkbox" id="vntcli_wg_fake" <% nvram_match_x("", "vntcli_wg", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_wg", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_wg" id="vntcli_wg_1" class="input" value="1" <% nvram_match_x("", "vntcli_wg", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_wg" id="vntcli_wg_0" class="input" value="0" <% nvram_match_x("", "vntcli_wg", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2" id="vntcli_wg_td"></td>
	<tr id="vntcli_finger_tr">
	<th style="border-top: 0 none;">启用数据指纹校验</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_finger_on_of">
	<input type="checkbox" id="vntcli_finger_fake" <% nvram_match_x("", "vntcli_finger", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_finger", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_finger" id="vntcli_finger_1" class="input" value="1" <% nvram_match_x("", "vntcli_finger", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_finger" id="vntcli_finger_0" class="input" value="0" <% nvram_match_x("", "vntcli_finger", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2" id="vntcli_finger_td"></td>
	<tr id="vntcli_serverw_tr">
	<th style="border-top: 0 none;">启用服务端客户端加密</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_serverw_on_of">
	<input type="checkbox" id="vntcli_serverw_fake" <% nvram_match_x("", "vntcli_serverw", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_serverw", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_serverw" id="vntcli_serverw_1" class="input" value="1" <% nvram_match_x("", "vntcli_serverw", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_serverw" id="vntcli_serverw_0" class="input" value="0" <% nvram_match_x("", "vntcli_serverw", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2" id="vntcli_serverw_td"></td>
	<tr id="vntcli_desname_tr">
	<th width="30%" style="border-top: 0 none;">设备名称</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_desname" type="text" class="input" id="vntcli_desname" placeholder="<% nvram_get_x("","computer_name"); %>" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_desname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3" id="vntcli_desname_td"></td>
	<tr id="vntcli_id_tr">
	<th width="30%" style="border-top: 0 none;">设备ID</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="建议与接口IP一致" id="vntcli_id" name="vntcli_id" value="<% nvram_get_x("","vntcli_id"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><td colspan="3" id="vntcli_id_td"></td>
	<tr id="vntcli_tunname_tr">
	<th width="30%" style="border-top: 0 none;">TUN网卡名</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_tunname" type="text" class="input" id="vntcli_tunname" placeholder="vnt-tun" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_tunname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3" id="vntcli_tunname_td"></td>
	<tr id="vntcli_mtu_tr">
          <th width="30%" style="border-top: 0 none;">MTU</th>
          <td style="border-top: 0 none;">
          <input type="text" name="vntcli_mtu" maxlength="4" class="input" placeholder="1450" size="5" value="<% nvram_get_x("","vntcli_mtu"); %>" onkeypress="return is_number(this,event);"/> 
          </td>
          </tr><td colspan="3" id="vntcli_mtu_td"></td>
	<tr id="vntcli_dns_tr">
	<th width="30%" style="border-top: 0 none;">自定义DNS</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="128" class="input" name="vntcli_dns" id="vntcli_dns" placeholder="223.5.5.5" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_dns"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个DNS使用换行分隔</span>
	</td>
	</tr><td colspan="3" id="vntcli_dns_td"></td>
	<tr id="vntcli_stun_tr">
	<th width="30%" style="border-top: 0 none;">STUN服务地址</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="128" class="input" name="vntcli_stun" id="vntcli_stun" placeholder="stun.qq.com:3478" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_stun"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个STUN地址使用换行分隔</span>
	</td>
	</tr><td colspan="3" id="vntcli_stun_td"></td>
	<tr id="vntcli_port_tr">
	<th width="30%" style="border-top: 0 none;">监听端口</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_port" type="text" class="input" id="vntcli_port" placeholder="0,0" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_port"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3" id="vntcli_port_td"></td>
	<tr id="vntcli_wan_tr">
	<th width="30%" style="border-top: 0 none;">出口网卡名</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_wan" type="text" class="input" id="vntcli_wan" placeholder="eth2.2" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_wan"); %>" size="32" maxlength="12" />
	<br>⚠️&nbsp;<span style="color:#888;">错误网卡名将导致无法上网</span>
	</td>
	</tr><td colspan="3" id="vntcli_wan_td"></td>
	<tr id="vntcli_punch_tr">
	<th width="30%" style="border-top: 0 none;">打洞模式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_punch" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","vntcli_punch", "0","selected"); %>>自动选择</option>
	<option value="ipv4" <% nvram_match_x("","vntcli_punch", "ipv4","selected"); %>>仅IPV4-TCP/UDP</option>
	<option value="ipv4-tcp" <% nvram_match_x("","vntcli_punch", "ipv4-tcp","selected"); %>>仅IPV4-TCP</option>
	<option value="ipv4-udp" <% nvram_match_x("","vntcli_punch", "ipv4-udp","selected"); %>>仅IPV4-UDP</option>
	<option value="ipv6" <% nvram_match_x("","vntcli_punch", "ipv6","selected"); %>>仅IPV6-TCP/UDP</option>
	<option value="ipv6-tcp" <% nvram_match_x("","vntcli_punch", "ipv6-tcp","selected"); %>>仅IPV6-TCP</option>
	<option value="ipv6-udp" <% nvram_match_x("","vntcli_punch", "ipv6-udp","selected"); %>>仅IPV6-UDP</option>
	</select>
	</td>
	</tr><td colspan="3" id="vntcli_punch_td"></td>
	<tr id="vntcli_comp_tr">
	<th width="30%" style="border-top: 0 none;">启用压缩</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_comp" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","vntcli_comp", "0","selected"); %>>不使用</option>
	<option value="lz4" <% nvram_match_x("","vntcli_comp", "lz4","selected"); %>>启用lz4压缩</option>
	<option value="zstd" <% nvram_match_x("","vntcli_comp", "zstd","selected"); %>>启用zstd压缩</option>
	</select><br>⚠️&nbsp;<span style="color:#888;">启用zstd压缩请自行编译程序</span>
	</td>
	</tr><td colspan="3" id="vntcli_comp_td"></td>
	<tr id="vntcli_relay_tr">
	<th width="30%" style="border-top: 0 none;">传输模式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_relay" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","vntcli_relay", "0","selected"); %>>自动选择</option>
	<option value="relay" <% nvram_match_x("","vntcli_relay", "relay","selected"); %>>仅中继转发</option>
	<option value="p2p" <% nvram_match_x("","vntcli_relay", "p2p","selected"); %>>仅P2P直连</option>
	</select><br>⚠️&nbsp;<span style="color:#888;">无法P2P的网络下选择仅P2P直连将会无法连接对端</span>
	</td>
	</tr><td colspan="3" id="vntcli_relay_td"></td>
	<tr id="vntcli_disable_relay_tr">
	<th style="border-top: 0 none;">禁止为客户端中继</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_disable_relay_on_of">
	<input type="checkbox" id="vntcli_disable_relay_fake" <% nvram_match_x("", "vntcli_disable_relay", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_disable_relay", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_disable_relay" id="vntcli_disable_relay_1" class="input" value="1" <% nvram_match_x("", "vntcli_disable_relay", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_disable_relay" id="vntcli_disable_relay_0" class="input" value="0" <% nvram_match_x("", "vntcli_disable_relay", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2" id="vntcli_disable_relay_td"></td>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="vntcli_bin" id="vntcli_bin" placeholder="/etc/storage/bin/vnt-cli" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr>
	</table>
	<table id="vntcli_mapping_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th colspan="5" style="background-color: #756c78;">端口映射 (将本地服务的端口映射到对端进行访问)</th></tr>
	<tr id="row_rules_caption">
	<th width="10%">服务协议 </th>
	<th width="20%">本地服务端口 </th>
	<th width="20%">对端接口IP地址 </th>
	<th width="25%">对端访问端口 </th>
          <th width="5%"><center><i class="icon-th-list"></i></center></th>
          </tr>
          <tr>
          <th>
          <select name="vntcli_mappnet_x_0" class="input" style="width: 60px"> 
	<option value="0" <% nvram_match_x("","vntcli_mappnet_x_0", "0","selected"); %>>TCP</option>
	<option value="1" <% nvram_match_x("","vntcli_mappnet_x_0", "0","selected"); %>>UDP</option>
	</select>
	</th>
	<th>
          <input maxlength="5" class="input" style="width: 80px" size="15" name="vntcli_mappport_x_0" id="vntcli_mappport_x_0" placeholder="80" value="<% nvram_get_x("","vntcli_mappport_x_0"); %>" onKeyPress="return is_number(this,event);"/>
	</th>
	<th><input type="text" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_mappip_x_0" placeholder="10.26.0.22" value="<% nvram_get_x("", "vntcli_mappip_x_0"); %>"/>
	</th>
	<th>
	<input maxlength="5" class="input" style="width: 80px" size="15" name="vntcli_mapeerport_x_0" id="vntcli_mapeerport_x_0" placeholder="8080" value="<% nvram_get_x("","vntcli_mapeerport_x_0"); %>" onKeyPress="return is_number(this,event);"/>
	</th>
	<th>
	<button class="btn" style="max-width: 219px" type="submit" onclick="return markmappRULES(this, 64, ' Add ');" name="markmappRULES2" value="<#CTL_add#>" size="12"><i class="icon icon-plus"></i></button>
	</th>
	</td>
	</tr>
	<tr id="row_rules_body" >
	<td colspan="5" style="border-top: 0 none; padding: 0px;">
	<div id="MmappRULESList_Block"></div>
	</td>
	</tr>
	<tr>
	<td colspan="5" style="border-top: 0 none; padding-bottom: 20px;">
	
	</table>
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr><br />
	</div>
	<!-- 状态 -->
	<div id="wnd_vntcli_sta" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
		<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
			<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnt-cli_cmd.log",""); %></textarea>
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center;">
			<!-- 按钮并排显示 -->
			<input class="btn btn-success" id="btn_info" style="width:100px; margin-right: 10px;" type="button" name="vntcli_info" value="本机设备信息" onclick="button_vntcli_info()" />
			<input class="btn btn-success" id="btn_all" style="width:100px; margin-right: 10px;" type="button" name="vntcli_all" value="所有设备信息" onclick="button_vntcli_all()" />
			<input class="btn btn-success" id="btn_list" style="width:100px; margin-right: 10px;" type="button" name="vntcli_list" value="所有设备列表" onclick="button_vntcli_list()" />
			<input class="btn btn-success" id="btn_vc_route" style="width:100px; margin-right: 10px;" type="button" name="vntcli_route" value="路由转发信息" onclick="button_vntcli_route()" />
			<input class="btn btn-success" id="btn_vc_status" style="width:100px; margin-right: 10px;" type="button" name="vntcli_status" value="运行状态信息" onclick="button_vntcli_status()" />
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 5px;">
			<span style="color:#888;">🔄 点击上方按钮刷新查看</span>
		</td>
	</tr>
	</table>
	</div>

	<!-- 日志 -->
	<div id="wnd_vntcli_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnt-cli.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="reloadTab();" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='vnt-cli.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog_VNTCLI();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志包含 token 和 密码 等隐私信息，切勿随意分享！</span>
	</td>
	</table>
	</div>
	<!-- 帮助说明 -->
	<div id="wnd_vntcli_help" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<table width="100%" align="center" cellpadding="4" cellspacing="0" style="background-color: transparent;">
	<tr>
	<th colspan="2" style="background-color: rgba ( 171 , 168 , 167 , 0.2 ); color: white;">对应参数功能介绍</th>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78; text-align: left;">基础设置</th>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	Token
        </td>
        <td style="color: white; width: 85%; text-align: left;">
	【-k】连接相同的服务器时，相同token的设备才会组建一个虚拟局域网。这是必须填写的，否则无法启动
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	接口IP
        </td>
        <td style="color: white; width: 85%; text-align: left;">
	【--ip】指定本机的虚拟IP地址，每个客户端的IP不能相同，为空不指定则由服务器自动分配IP（不指定IP每次重启后IP地址将随机变化）
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	本地网段
	</td>
	<td style="color: white; width: 85%; text-align: left;">
	【-o】使本机局域网内的其他设备也能被对端访问，例如本机局域网IP为192.168.1.1则填 192.168.1.0/24 多个网段使用换行分隔（使本机作为出口节点还需添加 0.0.0.0/0）
	</td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	服务器地址
	</td>
	<td style="color: white; width: 85%; text-align: left;">
	【-s】填写域名或IP地址，相同的服务器，相同token的设备才会组成一个局域网，协议支持使用tcp://和ws://和wss://和txt://,不填协议默认为udp://<br>使用txt记录，只需要将 IP:端口 记录到域名的txt记录即可
	</td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	加密方式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--model】通常情况aes_gcm安全性高、aes_ecb性能更好，在低性能设备上aes_ecb和xor速度最快，xor对速度基本没有影响。
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	密码
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-w】如果加密那么每个客户端都必须使用相同的 加密方式 和 密码 ，要么都不使用加密。客户端和客户端之间的加密
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用日志
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	生成程序运行的日志，用来查找bug错误，正常使用无需开启，开启影响些许性能
        </td>
	</tr>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	子网配置
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-i】相当于路由表，设置对端的lan网段和对端的接口IP地址，方便直接使用对端的内网IP地址即可访问对方内网其他设备
        </td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78; text-align: left;">进阶设置</th>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用IP转发
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--no-proxy】内置的IP代理较为简单，而且一般来说直接使用网卡NAT转发性能会更高,所以默认开启IP转发关闭内置的ip代理 
        </td>
	</tr>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用优化传输
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--first_latency】优先使用低延迟通道，默认情况下优先使用p2p通道，某些情况下可能p2p比客户端中继延迟更高，可启用此参数进行优化传输 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	允许WireGuard访问
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--allow-wg】在VNTS服务端的管理界面添加了WireGuard客户端时，本机需要被WG客户端访问才开启，默认不允许WG访问 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用数据指纹校验
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--finger】开启数据指纹校验，可增加安全性，如果服务端开启指纹校验，则客户端也必须开启，开启会损耗一部分性能。<br>注意：默认情况下服务端不会对中转的数据做校验，如果要对中转的数据做校验，则需要客户端、服务端都开启此参数 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用服务端客户端加密
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-W】这是客户端和服务端之间的加密，开启后和服务端通信的数据就会加密，采用rsa+aes256gcm加密客户端和服务端之间通信的数据，可以避免token泄漏、中间人攻击 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	设备名称
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-n】本机设备名称，方便区分不同设备 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	设备ID
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-d】设备唯一标识符,不填写接口IP时,服务端凭此参数分配虚拟ip,注意不能和其他客户端重复，建议和接口IP保持一致<br>如果填写了接口IP 请务必填写此参数，为了防止重启后IP变化，脚本也会自动将接口IP作为设备ID 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	TUN网卡名
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--nic】指定虚拟网卡名称，默认tun模式使用vnt-tun 在多开进程的时候需要指定不同网卡名 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	MTU
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-u】设置虚拟网卡的mtu值，大多数情况下使用默认值效率会更高，也可根据实际情况微调这个值，不加密默认为1450，加密默认为1410 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	自定义DNS
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--dns】用来解析域名服务器地址，可以设置多个（换行分隔）。如果使用TXT记录的域名，则dns默认使用223.5.5.5和114.114.114.114，端口省略值为53<br>
当域名解析失败时，会依次尝试后面的dns，直到有A记录、AAAA记录(或TXT记录)的解析结果 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	STUN服务地址
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-e】使用stun服务探测客户端NAT类型，不同类型有不同的打洞策略，程序已内置多个STUN地址 ，填写最多三个！
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	监听端口
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--ports】指定本地监听的端口组，多个端口使用英文逗号分隔，多个端口可以分摊流量，增加并发、减缓流量限制，tcp会监听端口组的第一个端口，用于tcp直连，端口越多越占用性能<br>例1：‘12345,12346,12347’ 表示udp监听12345、12346、12347这三个端口，tcp监听12345端口<br>例2：‘0,0’ 表示udp监听两个未使用的端口，tcp监听一个未使用的端口
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	出口网卡名
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--local-dev】指定出口网卡，当指定对端某个节点作为流量出口时，则必须指定当前的出口网卡（控制台输入 ifconfig 查看哪个网卡是走向外网的，则填哪个网卡名）<br>填写错误的网卡名将会导致无法上网，去掉选项即可恢复<br>指定流量出口：请使用子网配置里，对端lan网段填写 0.0.0.0/0 接口IP就填写对端的接口IP即可，对端还须启用作为流量出口节点，这时本机流量将从指定的对端节点出口
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	打洞模式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--punch】选择对应的方式进行打洞，都使用自动选择合适的方式进行打洞
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用压缩
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--compressor】选择一种压缩方式进行压缩数据以提高带宽速度（低性能设备不建议开启，反而降低速度，若某个客户端开启了，则所有客户端都需要开启）<br>官方已发布的程序默认只带lz4 如需zstd请自行编译程序
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	传输模式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--use-channel】自动选择：自动判断合适的传输方式，优先P2P直连，无法直连的网络环境会采用服务器中继转发或其他客户端中继转发<br>仅中继转发：将不使用P2P直连，只使用服务器或客户端进行转发数据<br>仅P2P直连：只使用P2P直连进行传输，不使用服务器或其他客户端进行中继转发，如果网络环境无法P2P直连，将断开连接无法通讯。
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	禁止为客户端中继
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--disable-relay】启用后将禁止为其他客户端转发数据,本机将不作为中继节点。默认会为其他客户端进行中继转发流量。
        </td>
	</tr>
	<tr>
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	端口映射
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--mapping】表示将本地服务端口的数据转发到对端地址的端口进行访问，转发的对端地址可以使用域名+端口，详情请参阅官方文档。
        </td>
	</tr>
	</table>

	</table>
								</div>

								<!-- ============ VNT 服务端 ============ -->
								<div id="wnd_net_vnts" style="display:none">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a class="subtab" id="tab_vnts_cfg" href="#vnts-cfg">基本设置</a></li>
	<li><a class="subtab" id="tab_vnts_log" href="#vnts-log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="wnd_vnts_cfg">
	<div class="alert alert-info" style="margin: 10px;">这是<a href="https://github.com/vnt-dev/vnt" target="blank">vnt-cli</a>的服务端。&nbsp;&nbsp;&nbsp;&nbsp;安卓、Windows客户端：<a href="https://github.com/vnt-dev/VntApp" target="blank">VntApp</a><br>
	<div>项目地址：<a href="https://github.com/vnt-dev/vnts" target="blank">github.com/vnt-dev/vnts</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://rustvnt.com" target="blank">rustvnt.com</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群1：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=9aa1l03sqBPU-rMIzJ52gcmjq9HsO0tA&authKey=FFA0UdK6Dg1wAvL4e9FvyEu3DxekIlYp9W4NaQ54DO2dzQM%2BKS3rShUSwt9BN0bL&noverify=0&group_code=1034868233" target="blank">1034868233</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群2：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=H4czBrp-IUxgTJ9wem0eXFHPdADkKTVW&authKey=JXU4v4ZQSXupcHOYUCOVgU0rDUdEe1ZfGVWzRVqRecxXY4cg%2BgfHl7n%2F%2F6nGSDH2&noverify=0&group_code=950473757" target="blank">950473757</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "vnts_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "vnts_ver_n"); %></span>】 </div>
	
	<span style="color:#FF0000;" class=""></span></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th><#running_status#></th>
            <td id="vnts_status" colspan="2"></td>
          </tr>
	<tr id="vnts_enable_tr" >
	<th width="30%">启用vnts</th>
	<td>
	<div class="main_itoggle">
	<div id="vnts_enable_on_of">
	<input type="checkbox" id="vnts_enable_fake" <% nvram_match_x("", "vnts_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_enable" id="vnts_enable_1" class="input" value="1" onClick="change_vnts_enable(1);" <% nvram_match_x("", "vnts_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_enable" id="vnts_enable_0" class="input" value="0" onClick="change_vnts_enable(1);" <% nvram_match_x("", "vnts_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td>
	<input class="btn btn-success" style="width:150px" type="button" name="restartvnts" value="更新" onclick="button_restartvnts()" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border-top: 0 none;">服务端口</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="vnts_port" id="vnts_port" placeholder="29872" value="<% nvram_get_x("","vnts_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[29872]</span>
	</div>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border-top: 0 none;">token白名单</th>
	<td colspan="3" style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="2048" class="input" name="vnts_token" id="vnts_token" placeholder="" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vnts_token"); %></textarea>
	</div><span style="color:#888;">限制指定token的客户端才可以连接此服务器，留空则没有限制。<br>如有多个token作为白名单请使用换行来进行分隔。</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;">虚拟网关</th>
	<td style="border: 0 none;"><input name="vnts_subnet" placeholder="10.26.0.1" type="text" class="input" id="vnts_subnet" onkeypress="return is_ipaddr(this,event);" value="<% nvram_get_x("","vnts_subnet"); %>" size="32" maxlength="15"/>
	<br /><span style="color:#888;">分配给客户端的虚拟IP网段</span></td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;">子网掩码</th>
	<td style="border: 0 none;">
	<input name="vnts_netmask" type="text" class="input" id="vnts_netmask" placeholder="<% nvram_get_x("","lan_netmask"); %>" onkeypress="return is_ipaddr(this,event);" value="<% nvram_get_x("","vnts_netmask"); %>" size="32" maxlength="15"/>
	<br />
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_sfinger_tr" >
	<th style="border-top: 0 none;">启用数据指纹校验</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_sfinger_on_of">
	<input type="checkbox" id="vnts_sfinger_fake" <% nvram_match_x("", "vnts_sfinger", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_sfinger", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_sfinger" id="vnts_sfinger_1" class="input" value="1" <% nvram_match_x("", "vnts_sfinger", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_sfinger" id="vnts_sfinger_0" class="input" value="0" <% nvram_match_x("", "vnts_sfinger", "0", "checked"); %> /><#checkbox_No#>
	</div><span style="color:#888;">启用数据指纹校验后只会转发指纹正确的客户端数据包，增强安全性，但这会损失一部分性能。(启用后客户端也须开启)</span></td>
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_web_enable_tr" >
	<th style="border-top: 0 none;">启用WEB页面</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_web_enable_on_of">
	<input type="checkbox" id="vnts_web_enable_fake" <% nvram_match_x("", "vnts_web_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_web_enable", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_web_enable" id="vnts_web_enable_1" class="input" value="1" onClick="change_vnts_web_enable_bridge(1);" <% nvram_match_x("", "vnts_web_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_web_enable" id="vnts_web_enable_0" class="input" value="0" onClick="change_vnts_web_enable_bridge(1);" <% nvram_match_x("", "vnts_web_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="vnts_web_port_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;端口:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="vnts_web_port" id="vnts_port" placeholder="29870" value="<% nvram_get_x("","vnts_web_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[29870]</span>
	</div>
	</td>
	<td style="border-top: 0 none;">
	&nbsp;<input class="btn btn-success" style="" type="button" value="打开管理页面" onclick="button_vnts_web()" />
	</td>
	</tr>
	<tr id="vnts_web_user_tr" style="display:none;">
	<th style="border: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;用户名:</th>
	<td style="border: 0 none;"><input name="vnts_web_user" type="text" class="input" id="vnts_web_user" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vnts_web_user"); %>" size="32" maxlength="128" /></td>
	</tr>
	<tr id="vnts_web_pass_tr" style="display:none;">
	<th style="border: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;密码:</th>
	<td style="border: 0 none;">
	<input maxlength="512" type="password" class="input" size="32" name="vnts_web_pass" id="vnts_web_pass" value="<% nvram_get_x("","vnts_web_pass"); %>" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vnts_web_pass')"><i class="icon-eye-close"></i></button>
	</div>
	</td>
	</tr>
	<tr id="vnts_web_wan_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;启用外网访问:</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_web_wan_on_of">
	<input type="checkbox" id="vnts_web_wan_fake" <% nvram_match_x("", "vnts_web_wan", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_web_wan", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_web_wan" id="vnts_web_wan_1" class="input" value="1" <% nvram_match_x("", "vnts_web_wan", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_web_wan" id="vnts_web_wan_0" class="input" value="0" <% nvram_match_x("", "vnts_web_wan", "0", "checked"); %> /><#checkbox_No#>
	</div>&nbsp;<span style="color:#888;">注意：启用后防火墙将放行WEB端口，公网IP外网将可访问，请慎重选择，须使用强密码，并定期更换！</span>
	</td>
	</tr><td colspan="3"></td>
	</tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="vnts_bin" id="vnts_bin" placeholder="/etc/storage/bin/vnts" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vnts_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr id="vnts_disable_group_tr" >
	<th style="border-top: 0 none;">禁止web界面显示组网列表</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_disable_group_on_of">
	<input type="checkbox" id="vnts_disable_group_fake" <% nvram_match_x("", "vnts_disable_group", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_disable_group", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_disable_group" id="vnts_disable_group_1" class="input" value="1" <% nvram_match_x("", "vnts_disable_group", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_disable_group" id="vnts_disable_group_0" class="input" value="0" <% nvram_match_x("", "vnts_disable_group", "0", "checked"); %> /><#checkbox_No#>
	</div><span style="color:#888;">禁止web界面显示所有组网token列表，启用后必须手动搜索正确的token才能查看</span></td>
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_disable_relay_tr" >
	<th style="border-top: 0 none;">禁止中继转发</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_disable_relay_on_of">
	<input type="checkbox" id="vnts_disable_relay_fake" <% nvram_match_x("", "vnts_disable_relay", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_disable_relay", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_disable_relay" id="vnts_disable_relay_1" class="input" value="1" <% nvram_match_x("", "vnts_disable_relay", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_disable_relay" id="vnts_disable_relay_0" class="input" value="0" <% nvram_match_x("", "vnts_disable_relay", "0", "checked"); %> /><#checkbox_No#>
	</td><span style="color:#888;">禁止为客户端提供中继转发数据，仅交换客户端握手数据（客户端之间只能通过P2P进行连接，无法P2P时将无法通讯）</span></td>
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_log_tr" >
	<th style="border-top: 0 none;">启用程序日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_log_on_of">
	<input type="checkbox" id="vnts_log_fake" <% nvram_match_x("", "vnts_log", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_log", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_log" id="vnts_log_1" class="input" value="1" <% nvram_match_x("", "vnts_log", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_log" id="vnts_log_0" class="input" value="0" <% nvram_match_x("", "vnts_log", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td>
	</tr>
	
	</table>
	</div>
	<div id="wnd_vnts_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnts.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="reloadTab();" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='vnts.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog_VNTS();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志可能包含部分隐私信息，切勿随意分享！</span>
	</td>
	</table>
								</div>
								</div>

								<!-- ============ NPC 内网穿透 ============ -->
								<div id="wnd_net_npc" style="display:none">
								<div class="row-fluid">
									<div class="alert alert-info" style="margin: 10px;">nps 是一款轻量级、高性能、功能强大的内网穿透代理服务器。
									</div>

									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr> 
											<th>npc<#running_status#></th>
											<td id="npc_status" colspan="2"></td>
										</tr>
										<tr>
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">启用 npc 内网穿透</a></th>
											<td style="border-top: 0 none;">
													<div class="main_itoggle">
													<div id="npc_enable_on_of">
														<input type="checkbox" id="npc_enable_fake" <% nvram_match_x("", "npc_enable", "1", "value=1 checked"); %><% nvram_match_x("", "npc_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="npc_enable" id="npc_enable_1" class="input" value="1" onClick="change_npc_enable_bridge(1);" <% nvram_match_x("", "npc_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="npc_enable" id="npc_enable_0" class="input" value="0" onClick="change_npc_enable_bridge(1);" <% nvram_match_x("", "npc_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="npc_server_addr_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">服务器地址:</a></th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="50" class="input" size="50" id="npc_server_addr" name="npc_server_addr" placeholder="127.0.0.1" value="<% nvram_get_x("","npc_server_addr"); %>"  onkeypress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="npc_server_port_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">端口:</a></th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="5" class="input" size="15" id="npc_server_port" name="npc_server_port" placeholder="8024" value="<% nvram_get_x("","npc_server_port"); %>"  onkeypress="return is_number(this,event);" />
											</td>
										</tr>
										<tr id="npc_protocol_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">协议类型:</a></th>
											<td style="border-top: 0 none;">
												<select name="npc_protocol" id="npc_protocol" class="input" style="width: 200px">
													<option value="tcp" <% nvram_match_x("","npc_protocol", "tcp","selected"); %>>TCP</option>
													<option value="kcp" <% nvram_match_x("","npc_protocol", "kcp","selected"); %>>KCP</option>
												</select>
											</td>
										</tr>
										<tr id="npc_vkey_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">密钥(vkey):</a></th>
											<td style="border-top: 0 none;">
											<div class="input-append">
												<input type="password" maxlength="512" class="input" size="16" name="npc_vkey" id="npc_vkey" style="width: 175px;" value="<% nvram_get_x("","npc_vkey"); %>" onKeyPress="return is_string(this,event);"/>
												<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('npc_vkey')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="npc_compress_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">使用压缩传输:</a></th>
											<td style="border-top: 0 none;">
												<div class="main_itoggle">
													<div id="npc_compress_on_of">
														<input type="checkbox" id="npc_compress_fake" <% nvram_match_x("", "npc_compress", "1", "value=1 checked"); %><% nvram_match_x("", "npc_compress", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="npc_compress" id="npc_compress_1" class="input" value="1" <% nvram_match_x("", "npc_compress", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="npc_compress" id="npc_compress_0" class="input" value="0" <% nvram_match_x("", "npc_compress", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="npc_crypt_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">使用加密传输:</a></th>
											<td style="border-top: 0 none;">
												<div class="main_itoggle">
													<div id="npc_crypt_on_of">
														<input type="checkbox" id="npc_crypt_fake" <% nvram_match_x("", "npc_crypt", "1", "value=1 checked"); %><% nvram_match_x("", "npc_crypt", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="npc_crypt" id="npc_crypt_1" class="input" value="1" <% nvram_match_x("", "npc_crypt", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="npc_crypt" id="npc_crypt_0" class="input" value="0" <% nvram_match_x("", "npc_crypt", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="npc_log_level_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">日志级别:</a></th>
											<td style="border-top: 0 none;">
												<select name="npc_log_level" id="npc_log_level" class="input" style="width: 200px">
													<option value="0" <% nvram_match_x("","npc_log_level", "0","selected"); %>>Emergency</option>
													<option value="2" <% nvram_match_x("","npc_log_level", "2","selected"); %>>Critical</option>
													<option value="3" <% nvram_match_x("","npc_log_level", "3","selected"); %>>Error</option>
													<option value="4" <% nvram_match_x("","npc_log_level", "4","selected"); %>>Warning</option>
													<option value="7" <% nvram_match_x("","npc_log_level", "7","selected"); %>>Debug</option>
												</select>
											</td>
										</tr>
										<tr id="row_post_wan_script">
											<td colspan="2">
												<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script2')"><span>npc启动脚本-不懂请不要乱改！！！</span></a>
												<div id="script2">
													<textarea rows="18" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.npc_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.npc_script.sh",""); %></textarea>
												</div>
											</td>
										</tr>
										
										<tr>
											<td colspan="2" style="border-top: 0 none;">
												<br />
												<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
											</td>
										</tr>
									</table>
								</div>
								</div>

								<!-- ============ WireGuard ============ -->
								<div id="wnd_net_wireguard" style="display:none">
								<div class="row-fluid">
									<div class="alert alert-info" style="margin: 10px;">
										<p>WireGuard 是一个易于配置、快速且安全的开源VPN</p>
									</div>

									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr>
											<th width="30%" style="border-top: 0 none;">启用wireguard</th>
											<td style="border-top: 0 none;">
												<div class="main_itoggle">
													<div id="wireguard_enable_on_of">
														<input type="checkbox" id="wireguard_enable_fake" <% nvram_match_x("", "wireguard_enable", "1", "value=1 checked"); %><% nvram_match_x("", "wireguard_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="wireguard_enable" id="wireguard_enable_1" class="input" <% nvram_match_x("", "wireguard_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="wireguard_enable" id="wireguard_enable_0" class="input" <% nvram_match_x("", "wireguard_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
											<td style="border-top: 0 none;">
												<input class="btn btn-success" style="width:150px" type="button" name="restartwg" value="重启" onclick="button_restartwg()" />
											</td>
										</tr>
										<tr>
											<th style="border-top: 0 none;">接口IPV4</th>
											<td style="border-top: 0 none;">
												<input type="text" class="input" name="wireguard_localip" id="wireguard_localip" style="width: 200px" value="<% nvram_get_x("","wireguard_localip"); %>" />
												&nbsp;<span style="color:#888;">（格式 10.0.0.2/24）</span>
											</td>
										</tr>
										<tr>
											<th style="border-top: 0 none;">接口IPV6</th>
											<td style="border-top: 0 none;">
												<input type="text" class="input" name="wireguard_localip6" id="wireguard_localip6" style="width: 200px" value="<% nvram_get_x("","wireguard_localip6"); %>" />
												&nbsp;<span style="color:#888;">（格式 fd69::1/64）</span>
											</td>
										</tr>
										<tr>
											<th style="border-top: 0 none;">自定义接口</th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="20" class="input" name="wireguard_tun" placeholder="wg0" id="wireguard_tun" style="width: 200px" value="<% nvram_get_x("","wireguard_tun"); %>" />
											</td>
										</tr>
										<tr>
											<th style="border-top: 0 none;">自定义MTU</th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="4" class="input" name="wireguard_mtu" placeholder="1420" id="wireguard_mtu" style="width: 200px" value="<% nvram_get_x("","wireguard_mtu"); %>" />
											</td>
										</tr>
										<tr>
											<td colspan="3" style="border-top: 0 none;">
												<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.wireguard')"><span>点此编辑 /etc/storage/wg0.conf 配置文件</span></a>
												<div id="scripts.wireguard" style="display:none;">
													<textarea rows="18" wrap="off" spellcheck="false" maxlength="209715" class="span12" name="scripts.wg0.conf" style="font-family:'Courier New'; font-size:12px; height: 200px;"><% nvram_dump("scripts.wg0.conf",""); %></textarea>
													<div>⚠️&nbsp;&nbsp;<span style="color: #ff8100;">注意：</span><span style="color:#888;">配置文件里不支持Post脚本规则和指定接口IP和DNS&nbsp;&nbsp;&nbsp;&nbsp;在线生成配置文件：<a href="https://www.wireguardconfig.com/" target="blank">点此</a></span></div>
												</div>
											</td>
										</tr>
										<tr>
											<td colspan="3" style="border-top: 0 none;">
												<br />
												<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
											</td>
										</tr>
									</table>
								</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	</form>

	<div id="footer"></div>
</div>
</body>
</html>
