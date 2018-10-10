---
layout: post
title: "记录一下Vue的一个问题"
description: "vue Failed to mount component: template or render function not defined. 也可能是文件编码异常"
category: vue
tags: [vue]
---
{% include JB/setup %}


最近用vue typescript SPA 做管理后台（ABP官网导出的vue项目模板），遇到一个错误，找了好久，虽然有相关资料，但发现都没解决，这里自己记录一下。


    Failed to mount component: template or render function not defined.

除了网上能找到的其他关于这个错误的资料外，文件编码不对也可能遇到这个错误。所以，如果你是搜索这个问题看到本文的，试试改下文件编码，改成UTF8就好了。
