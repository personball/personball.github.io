---
layout: post
title: "利用find找特定时段内建立（修改过）的文件"
description: "使用touch命令和find命令寻找特定时间段内建立或修改过的文件。"
category: BashShell
tags: [find]
---
{% include JB/setup %}

touch -t 以指定的时间戳建立空文件  
find  -newer file 比较文件时间戳  要区分访问时间，状态修改时间可以用anewer   cnewer

	touch -t "201207130800" AM800 && touch -t "201207131800" PM800 \
	&& find . -newer AM800 -not -newer PM800 && rm [AP]M800