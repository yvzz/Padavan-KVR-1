<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - DDNS 服务</title>
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
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {

	init_itoggle('aliddns_enable',change_aliddns_enable_bridge);
	init_itoggle('ddnspod_enable',change_ddnspod_enable_bridge);
	init_itoggle('cloudflare_enable',change_cloudflare_enable_bridge);

	$j("#tab_ddns_aliddns, #tab_ddns_ddnspod, #tab_ddns_cf").click(
	function () {
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});

	/* 未编译进本固件的服务, 隐藏对应页签 */
	if (!found_app_aliddns())
		$j('#tab_ddns_aliddns').parents('li').hide();
	if (!found_app_ddnspod())
		$j('#tab_ddns_ddnspod').parents('li').hide();
	if (!found_app_cloudflare())
		$j('#tab_ddns_cf').parents('li').hide();

	/* 进入页面时按 URL hash 定位到对应页签(如 #ddnspod) */
	showTab(window.location.hash);

});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,17,0);
	show_footer();

	change_aliddns_enable_bridge(1);
	change_ddnspod_enable_bridge(1);
	change_cloudflare_enable_bridge(1);

	if (!login_safe())
		textarea_scripts_enabled(0);
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.ddns_script.sh'], v);
}

var arrHashes = ["aliddns","ddnspod","cf"];

/* 第一个未被隐藏(即已编译进固件)的页签, 作为默认/回退页签 */
function firstVisibleTab(){
	for (var i = 0; i < arrHashes.length; i++) {
		if ($j('#tab_ddns_' + arrHashes[i]).parents('li').css('display') != 'none')
			return '#' + arrHashes[i];
	}
	return '#aliddns';
}

function showTab(curHash) {
	var obj = $('tab_ddns_' + curHash.slice(1));
	if (obj == null || $j(obj).parents('li').css('display') == 'none')
		curHash = firstVisibleTab();
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_ddns_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_ddns_' + arrHashes[i]).show();
		} else {
			$j('#wnd_ddns_' + arrHashes[i]).hide();
			$j('#tab_ddns_' + arrHashes[i]).parents('li').removeClass('active');
		}
	}
	window.location.hash = curHash;
}

/* 重新加载页面并保持当前页签(hash), 避免刷新后跳回默认页签 */
function reloadTab(hash){
	if (window.location.hash != hash)
		window.location.hash = hash;
	window.location.reload();
}

function applyRule(){
	showLoading();

	document.form.action_mode.value = " Apply ";
	/* current_page 和 next_page 都带 hash: start_apply.htm 在 page_modified==1 时
	   用 current_page 重定向, 不带 hash 会跳回默认页签(阿里DDNS) */
	document.form.current_page.value = "/Advanced_ddns.asp" + window.location.hash;
	document.form.next_page.value = "/Advanced_ddns.asp" + window.location.hash;

	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function change_aliddns_enable_bridge(mflag){
	var m = document.form.aliddns_enable[0].checked;
	showhide_div("aliddns_interval_tr", m);
	showhide_div("aliddns_ttl_tr", m);
	showhide_div("aliddns_ak_tr", m);
	showhide_div("aliddns_sk_tr", m);
	showhide_div("aliddns_domain_tr", m);
	showhide_div("aliddns_domain2_tr", m);
	showhide_div("aliddns_domain6_tr", m);
}

function change_ddnspod_enable_bridge(mflag){
	var m = document.form.ddnspod_enable[0].checked;
	showhide_div("ddnspod_token_tr", m);
	showhide_div("ddnspod_interval_tr", m);
	showhide_div("ddnspod_domain_tr", m);
	showhide_div("ddnspod_domain2_tr", m);
	showhide_div("ddnspod_domain6_tr", m);
}

function change_cloudflare_enable_bridge(mflag){
	var m = document.form.cloudflare_enable[0].checked;
	showhide_div("cloudflare_interval_tr", m);
	showhide_div("cloudflare_token_tr", m);
	showhide_div("cloudflare_Email_tr", m);
	showhide_div("cloudflare_Key_tr", m);
	showhide_div("cloudflare_domian_tr", m);
	showhide_div("cloudflare_domian2_tr", m);
	showhide_div("cloudflare_domian6_tr", m);
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

	<input type="hidden" name="current_page" value="Advanced_ddns.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="CLOUDFLARE;LANHostConfig;General;">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="wan_ipaddr" value="<% nvram_get_x("", "wan0_ipaddr"); %>" readonly="1">
	<input type="hidden" name="wan_netmask" value="<% nvram_get_x("", "wan0_netmask"); %>" readonly="1">
	<input type="hidden" name="dhcp_start" value="<% nvram_get_x("", "dhcp_start"); %>">
	<input type="hidden" name="dhcp_end" value="<% nvram_get_x("", "dhcp_end"); %>">

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
							<h2 class="box_head round_top">DDNS 服务</h2>
							<div class="round_bottom">
							<div>
							    <ul class="nav nav-tabs" style="margin-bottom: 10px;">
								<li class="active">
								    <a href="#aliddns" id="tab_ddns_aliddns">阿里DDNS</a>
								</li>
								<li>
								    <a href="#ddnspod" id="tab_ddns_ddnspod">DNSPod</a>
								</li>
								<li>
								    <a href="#cf" id="tab_ddns_cf">Cloudflare</a>
								</li>
							    </ul>
							</div>

								<!-- ============ 阿里DDNS ============ -->
								<div id="wnd_ddns_aliddns">
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">使用 Aliddns 实现顶级个人域名的 ddns 服务。 <a href="https://www.aliyun.com" target="blank"><i><u>Aliddns 主页</u></i></a>
												<ul style="padding-top:5px;margin-top:10px;float: left;">
												<li><a href="https://github.com/kyriosli/koolshare-aliddns" target="blank"><i><u>Aliddns 项目地址：https://github.com/kyriosli/koolshare-aliddns</u></i></a></li>
												<li>使用前需要将域名添加到 aliyun 中，并添加一条A记录，使用之后将自动更新ip</li>
												<li>点 <a href="https://help.aliyun.com/knowledge_detail/38738.html" target="blank"><i><u>这里</u></i></a> 查看如何获取 Aliddns 的 Access Key ID 和 Access Key Secret。</li>
												</ul>
									</div>

									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr >
											<th width="30%" style="border-top: 0 none;">上次运行:</th>
											<td  colspan="3"style="border-top: 0 none;">
											   <div >【<% nvram_get_x("","aliddns_last_act"); %>】</div>
											</td>
										</tr>
										<tr>
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">启用 Aliddns 域名解析</a></th>
											<td style="border-top: 0 none;">
													<div class="main_itoggle">
													<div id="aliddns_enable_on_of">
														<input type="checkbox" id="aliddns_enable_fake" <% nvram_match_x("", "aliddns_enable", "1", "value=1 checked"); %><% nvram_match_x("", "aliddns_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="aliddns_enable" id="aliddns_enable_1" class="input" value="1" onClick="change_aliddns_enable_bridge(1);" <% nvram_match_x("", "aliddns_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="aliddns_enable" id="aliddns_enable_0" class="input" value="0" onClick="change_aliddns_enable_bridge(1);" <% nvram_match_x("", "aliddns_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="aliddns_interval_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">检查周期(秒) :</a></th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="5" class="input" size="15" id="aliddns_interval" name="aliddns_interval" placeholder="600" value="<% nvram_get_x("","aliddns_interval"); %>"  onkeypress="return is_number(this,event);" />
											</td>
										</tr>
										<tr id="aliddns_ttl_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">解析TTL(秒) :</a></th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="5" class="input" size="15" id="aliddns_ttl" name="aliddns_ttl" placeholder="600" value="<% nvram_get_x("","aliddns_ttl"); %>"  onkeypress="return is_number(this,event);" />
												<div>&nbsp;<span style="color:#888;">[1-86400]默认10分钟，免费版的范围是600-86400</span></div>
											</td>
										</tr>
										<tr id="aliddns_ak_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">Access Key ID :</a></th>
											<td style="border-top: 0 none;">
											<div class="input-append">
												<input type="password" maxlength="512" class="input" size="15" name="aliddns_ak" id="aliddns_ak" style="width: 175px;" value="<% nvram_get_x("","aliddns_ak"); %>" onKeyPress="return is_string(this,event);"/>
												<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('aliddns_ak')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="aliddns_sk_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">Access Key Secret :</a></th>
											<td style="border-top: 0 none;">
											<div class="input-append">
												<input type="password" maxlength="512" class="input" size="15" name="aliddns_sk" id="aliddns_sk" style="width: 175px;" value="<% nvram_get_x("","aliddns_sk"); %>" onKeyPress="return is_string(this,event);"/>
												<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('aliddns_sk')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="aliddns_domain_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">顶级域名1</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="aliddns_name" name="aliddns_name" placeholder="www" value="<% nvram_get_x("","aliddns_name"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="aliddns_domain" name="aliddns_domain" placeholder="google.com" value="<% nvram_get_x("","aliddns_domain"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="aliddns_domain2_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">顶级域名2</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="aliddns_name2" name="aliddns_name2" placeholder="www" value="<% nvram_get_x("","aliddns_name2"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="aliddns_domain2" name="aliddns_domain2" placeholder="google.com" value="<% nvram_get_x("","aliddns_domain2"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="aliddns_domain6_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">顶级域名3[IPv6]</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="aliddns_name6" name="aliddns_name6" placeholder="www" value="<% nvram_get_x("","aliddns_name6"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="aliddns_domain6" name="aliddns_domain6" placeholder="google.com" value="<% nvram_get_x("","aliddns_domain6"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
									</table>
								</div>
								</div>

								<!-- ============ DNSPod ============ -->
								<div id="wnd_ddns_ddnspod" style="display:none;">
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">使用 DNSPod 实现顶级个人域名的 DDNS 服务，基于 ArDNSPod 纯 Shell 动态域名客户端。
												<ul style="padding-top:5px;margin-top:10px;float: left;">
												<li>项目地址：<a href="https://github.com/anrip/ArDNSPod" target="blank"><i><u>https://github.com/anrip/ArDNSPod</u></i></a></li>
												<li>使用前需要将域名添加到 DNSPod 中，并添加一条 A 记录，使用之后将自动更新 IP。</li>
												<li>Token 获取：DNSPod 控制台 → 密钥管理 → 创建 API Token，格式为 <b>ID,Token</b>（如 12345,7676f344eaeaea9074c123451234512d）。</li>
												<li>记录不存在时脚本会自动创建（A 记录），默认解析线路为「默认」。</li>
												</ul>
									</div>

									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr >
											<th width="30%" style="border-top: 0 none;">上次运行:</th>
											<td  colspan="3"style="border-top: 0 none;">
											   <div >【<% nvram_get_x("","ddnspod_last_act"); %>】</div>
											</td>
										</tr>
										<tr>
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">启用 DNSPod 域名解析</a></th>
											<td style="border-top: 0 none;">
													<div class="main_itoggle">
													<div id="ddnspod_enable_on_of">
														<input type="checkbox" id="ddnspod_enable_fake" <% nvram_match_x("", "ddnspod_enable", "1", "value=1 checked"); %><% nvram_match_x("", "ddnspod_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="ddnspod_enable" id="ddnspod_enable_1" class="input" value="1" onClick="change_ddnspod_enable_bridge(1);" <% nvram_match_x("", "ddnspod_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="ddnspod_enable" id="ddnspod_enable_0" class="input" value="0" onClick="change_ddnspod_enable_bridge(1);" <% nvram_match_x("", "ddnspod_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="ddnspod_token_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">API Token :</a></th>
											<td style="border-top: 0 none;">
											<div class="input-append">
												<input type="password" maxlength="128" class="input" size="15" name="ddnspod_token" id="ddnspod_token" style="width: 220px;" value="<% nvram_get_x("","ddnspod_token"); %>" onKeyPress="return is_string(this,event);"/>
												<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('ddnspod_token')"><i class="icon-eye-close"></i></button>
											</div>
											<div>&nbsp;<span style="color:#888;">格式：ID,Token（逗号分隔）</span></div>
											</td>
										</tr>
										<tr id="ddnspod_interval_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">检查周期(秒) :</a></th>
											<td style="border-top: 0 none;">
												<input type="text" maxlength="5" class="input" size="15" id="ddnspod_interval" name="ddnspod_interval" placeholder="600" value="<% nvram_get_x("","ddnspod_interval"); %>"  onkeypress="return is_number(this,event);" />
											</td>
										</tr>
										<tr id="ddnspod_domain_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">域名1 [IPv4]</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_name" name="ddnspod_name" placeholder="www" value="<% nvram_get_x("","ddnspod_name"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_domain" name="ddnspod_domain" placeholder="example.com" value="<% nvram_get_x("","ddnspod_domain"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="ddnspod_domain2_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">域名2 [IPv4]</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_name2" name="ddnspod_name2" placeholder="www" value="<% nvram_get_x("","ddnspod_name2"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_domain2" name="ddnspod_domain2" placeholder="example.com" value="<% nvram_get_x("","ddnspod_domain2"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="ddnspod_domain6_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;"><a class="help_tooltip" href="javascript: void(0)" onmouseover="openTooltip(this, 26, 9);">域名3 [IPv6]</a></th>
											<td style="border-top: 0 none;">
												<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_name6" name="ddnspod_name6" placeholder="www" value="<% nvram_get_x("","ddnspod_name6"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="ddnspod_domain6" name="ddnspod_domain6" placeholder="example.com" value="<% nvram_get_x("","ddnspod_domain6"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
									</table>
								</div>
								</div>

								<!-- ============ Cloudflare ============ -->
								<div id="wnd_ddns_cf" style="display:none;">
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">使用 Cloudflare 实现顶级个人域名的 ddns 服务。 <a href="https://www.cloudflare.com" target="blank"><i><u>https://www.cloudflare.com</u></i></a>
												<ul style="padding-top:5px;margin-top:10px;float: left;">
												<li>使用前需要将域名添加到 Cloudflare 中，并添加一条A记录，使用之后将自动更新ip</li>
												<li>点 <a href="https://dash.cloudflare.com/profile/api-tokens" target="blank"><i><u>【Get your API key】</u></i></a> 查看如何获取 Cloudflare 的 API 令牌和 Global API Key。</li>
												<li>万能的 Email·Global API Key 和各自权限的 API 令牌 选填一组，推荐用 API 令牌，可以保护账户安全</li>
												</ul>
									</div>

									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr>
											<th width="30%" style="border-top: 0 none;">启用 Cloudflare 域名解析</th>
											<td style="border-top: 0 none;">
											<div class="main_itoggle">
											<div id="cloudflare_enable_on_of">
											<input type="checkbox" id="cloudflare_enable_fake" <% nvram_match_x("", "cloudflare_enable", "1", "value=1 checked"); %><% nvram_match_x("", "cloudflare_enable", "0", "value=0"); %>  />
											</div>
											</div>
											<div style="position: absolute; margin-left: -10000px;">
											<input type="radio" value="1" name="cloudflare_enable" id="cloudflare_enable_1" class="input" value="1" onClick="change_cloudflare_enable_bridge(1);" <% nvram_match_x("", "cloudflare_enable", "1", "checked"); %> /><#checkbox_Yes#>
											<input type="radio" value="0" name="cloudflare_enable" id="cloudflare_enable_0" class="input" value="0" onClick="change_cloudflare_enable_bridge(1);" <% nvram_match_x("", "cloudflare_enable", "0", "checked"); %> /><#checkbox_No#>
											</div>
											</td>
										</tr>
										<tr id="cloudflare_interval_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">检查周期(秒) :</th>
											<td style="border-top: 0 none;">
											<input type="text" maxlength="5" class="input" size="15" id="cloudflare_interval" name="cloudflare_interval" placeholder="600" value="<% nvram_get_x("","cloudflare_interval"); %>"  onkeypress="return is_number(this,event);" />
											</td>
										</tr>
										<tr id="cloudflare_token_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">用户 API 令牌 (Token) :</th>
											<td style="border-top: 0 none;">
											<div class="input-append">
											<input type="password" maxlength="512" class="input" size="15" name="cloudflare_token" id="cloudflare_token" style="width: 175px;" placeholder="API Token" value="<% nvram_get_x("","cloudflare_token"); %>" onKeyPress="return is_string(this,event);"/>
											<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_token')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="cloudflare_Email_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">用户 Email Address :</th>
											<td style="border-top: 0 none;">
											<input type="text" maxlength="255" class="input" size="15" id="cloudflare_Email" name="cloudflare_Email" value="<% nvram_get_x("","cloudflare_Email"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="cloudflare_Key_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">用户 Global API Key :</th>
											<td style="border-top: 0 none;">
											<div class="input-append">
											<input type="password" maxlength="512" class="input" size="15" name="cloudflare_Key" id="cloudflare_Key" style="width: 175px;" placeholder="Global API Key" value="<% nvram_get_x("","cloudflare_Key"); %>" onKeyPress="return is_string(this,event);"/>
											<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_Key')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="cloudflare_CA_Key_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">用户 Origin CA Key:</th>
											<td style="border-top: 0 none;">
											<div class="input-append">
											<input type="password" maxlength="512" class="input" size="15" name="cloudflare_CA_Key" id="cloudflare_CA_Key" style="width: 175px;" value="<% nvram_get_x("","cloudflare_CA_Key"); %>" onKeyPress="return is_string(this,event);"/>
											<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_CA_Key')"><i class="icon-eye-close"></i></button>
											</div>
											</td>
										</tr>
										<tr id="cloudflare_domian_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">顶级域名1</th>
											<td style="border-top: 0 none;">
											<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host" name="cloudflare_host" placeholder="www" value="<% nvram_get_x("","cloudflare_host"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian" name="cloudflare_domian" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="cloudflare_domian2_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">顶级域名2</th>
											<td style="border-top: 0 none;">
											<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host2" name="cloudflare_host2" placeholder="www" value="<% nvram_get_x("","cloudflare_host2"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian2" name="cloudflare_domian2" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian2"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
										<tr id="cloudflare_domian6_tr" style="display:none;">
											<th width="30%" style="border-top: 0 none;">顶级域名3[IPv6]</th>
											<td style="border-top: 0 none;">
											<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host6" name="cloudflare_host6" placeholder="www" value="<% nvram_get_x("","cloudflare_host6"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian6" name="cloudflare_domian6" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian6"); %>" onKeyPress="return is_string(this,event);" />
											</td>
										</tr>
									</table>
								</div>
								</div>

								<!-- ============ 共用: DDNS 脚本 + 应用按钮 ============ -->
								<div class="row-fluid">
									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr id="row_post_wan_script">
											<td colspan="2" style="border-top: 0 none;">
												<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script2')"><span>DDNS 脚本 - 阿里DDNS / Cloudflare 共用的纯 Shell 动态域名客户端</span></a>
												<div id="script2" style="display:none;">
													<textarea rows="18" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.ddns_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.ddns_script.sh",""); %></textarea>
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
