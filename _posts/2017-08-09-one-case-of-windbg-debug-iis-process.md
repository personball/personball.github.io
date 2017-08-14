---
layout: post
title: "一则使用WinDbg工具调试iis进程调查内存占用过高的案例"
description: "一则使用WinDbg工具调试iis进程调查内存占用过高的案例"
category: WinDbg
tags: [WinDbg]
---
{% include JB/setup %}

最近遇到一个奇葩内存问题，跟了三四天，把Windbg玩熟了，所以打算分享下。

## 症状简介



## Windbg搞起来

1. 安装
1. 配置环境变量，符号路径
1. 启动，附加进程（提示调试器只能有一个？），管理员权限，进程号
1. .loadby sos clr  mscorwks
1. 调试结束时，关闭windbg前应该debug-> detach debugee,否则进程会崩溃，dump文件无妨

## Windbg命令笔记



## CLR知识点



## 总结



## 其他优化点


## 参考

《CLR via C#》
《微软iis最佳实践，李争》


## 追记莱特大神提醒

numa跨越问题

>
