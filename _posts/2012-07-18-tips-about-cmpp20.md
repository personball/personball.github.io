---
layout: post
title: "移动短信网关接入的注意事项"
description: "移动短信网关接入的注意事项"
category: SMS
tags: [SMS]
---
{% include JB/setup %}

1. 网关地址（端口）未提供端口的一般是默认端口7890
2. 网关接入使用的账号密码
3. 长号码：显示在接收方手机上的号码，比如1065 XXXX XXXXX
4. 提交短信时的字段

    Msg_src		6	
	Octet String	信息内容来源(SP_Id)

长度为6的一串东西，一般模拟器上会直接填入账号作为该字段的值，实际接入时，需问清楚网关方此项该填入什么。。

最后，开发cmpp2.0方面的东西，要是遇到文档中没定义的返回值什么的，不用问谷歌或者度娘了，打电话找移动技术支持吧，囧。网上的过期文档伤不起，不完备文档伤不起。。