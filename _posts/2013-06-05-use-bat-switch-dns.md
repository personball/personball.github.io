---
layout: post
title: "bat脚本设置DNS"
description: "bat脚本设置DNS"
category: Windows
tags: [bat]
---
{% include JB/setup %}

有时候需要切换本机dns，将网络环境转至测试环境

	@echo off
	netsh interface ip set dns name="本地连接" source=static addr=192.168.1.1 primary
	ipconfig /flushdns
	pause
	exit
	