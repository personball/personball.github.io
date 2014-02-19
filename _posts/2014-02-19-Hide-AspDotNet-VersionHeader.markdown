---
layout: post
title: "如何移除响应头中的.net framework 版本信息 以及mvc版本信息？"
categories: Mvc网站开发 web安全
tags: AspNet Mvc X-AspNet-Version X-AspNetMvc-Version
---

##1.先来看一个简单mvc3网站的响应头
![响应头版本信息示意图](/files/img/version_header_before.png "响应头版本信息示意图")

##2.修改Global.asax文件
在Application_Start方法中添加如下代码

{% highlight C# %}
MvcHandler.DisableMvcResponseHeader = true;
{% endhighlight %}
  
##3.修改Web.config
在system.web配置节中增加如下配置

{% highlight xml %}
<httpRuntime enableVersionHeader="false"/>
{% endhighlight %}

##4.再次查看响应头
![修改后示意图](/files/img/version_header_after.png "修改后")

