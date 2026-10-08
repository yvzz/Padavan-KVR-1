<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - DNSPod 域名解析</title>
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

	init_itoggle('ddnspod_enable',change_ddnspod_enable_bridge);

});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(7, 20, 2);
	show_footer();
	showmenu();

	change_ddnspod_enable_bridge(1);

	if (!login_safe())
		textarea_scripts_enabled(0);
}

function showmenu(){
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.ddns_script.sh'], v);
}

function applyRule(){
	showLoading();

	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_ddnspod.asp";
	document.form.next_page.value = "";

	document.form.submit();
}


function done_validating(action){
	refreshpage();
}

function change_ddnspod_enable_bridge(mflag){
	var m = document.form.ddnspod_enable[0].checked;
	showhide_div("ddnspod_token_tr", m);
	showhide_div("ddnspod_interval_tr", m);
	showhide_div("ddnspod_domain_tr", m);
	showhide_div("ddnspod_domain2_tr", m);
	showhide_div("ddnspod_domain6_tr", m);
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

	<input type="hidden" name="current_page" value="Advanced_ddnspod.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="LANHostConfig;General;">
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
							<h2 class="box_head round_top"><#menu5_23_2#></h2>
							<div class="round_bottom">
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
