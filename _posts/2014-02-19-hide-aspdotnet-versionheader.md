---
layout: post
title: "如何移除响应头中的.net framework 版本信息 以及mvc版本信息？"
description: "移除响应头中的.net framework 版本信息 以及mvc版本信息"
category: Web开发
tags: [AspNetMvc]
---
{% include JB/setup %}

####先来看一个简单mvc3网站的响应头

![响应头版本信息示意图](/assets/img/version_header_before.png "响应头版本信息示意图")

####修改Global.asax文件
在Application_Start方法中添加如下代码

	MvcHandler.DisableMvcResponseHeader = true;

####修改Web.config
在system.web配置节中增加如下配置
	
	<httpRuntime enableVersionHeader="false"/>

####再次查看响应头
![修改后示意图](/assets/img/version_header_after.png "修改后")

