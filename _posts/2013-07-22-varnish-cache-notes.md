---
layout: post
title: "varnish-cache 安装配置及体验笔记"
description: "varnish-cache 安装配置及体验笔记"
category: Web开发
tags: [varnish]
---
{% include JB/setup %}

### varnish安装
* [ubuntu12安装参考](https://www.varnish-cache.org/installation/ubuntu)  
* [其他系统参考](https://www.varnish-cache.org/docs)

如果选择了直接从源安装的方式的话，就不要自己去编译了，以免出现意外（悲剧的我，varnishlog 有点问题，之前先编译安装了，再从源安装，出问题了）。

### 基本入门
参考：[在线版varnish-book](https://www.varnish-software.com/static/book/index.html)

需要理解下vcl几个状态，主要是 vcl-recv 和 vcl-fetch 基本就够用了：

	vcl-recv  一般可以指定 使用哪个backend 可以设定 pass 规则
	vcl-fetch  主要处理 缓存规则，设置缓存时间 beresp.ttl

### Notes

* 手动清理缓存的命令（3.0版和以前有出入来着）：

    sudo varnishadm -T localhost:1234 ban.url .*$ -S /etc/varnish/secret

* acl 只针对ip使用
* 如果提示 nothing to repeat error code 106 一般就意味着正则写错了
* 如果提示 unkown request error code 101 一般就意味着命令搞错了（ban代替了原先的purge）
* req.url 不包含域名部分，域名部分是req.http.host
* 根据host清除指定页面缓存

	varnishadm -T 127.0.0.1:2000 ban "req.http.host ~ www.domain.com$ && req.url ~ /1.html"

* url大小写敏感问题，参考[varnish的标准库](https://www.varnish-cache.org/docs/trunk/reference/vmod_std.html)

	import std;//vcl文件顶部添加 
	...
	set req.url=std.tolower(req.url);//vcl_recv中第一行处理url 

### 参考资料：
[http://blog.51yip.com/cache/618.html](http://blog.51yip.com/cache/618.html)  
[http://anykoro.sinaapp.com/?p=261#1](http://anykoro.sinaapp.com/?p=261#1)