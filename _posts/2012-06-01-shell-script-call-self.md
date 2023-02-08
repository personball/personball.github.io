---
layout: post
title: "shell脚本调用自身"
description: "shell脚本调用自身"
category: Shell
tags: Bash
---
{% include JB/setup %}

1. 多线程使用（）创建子线程
2. 直接使用$0 即可调用自身

例子：

	personball@vostro:scan$cat testsubshell.sh
	#!/bin/bash
	sum=$1
	if [ $sum -lt 10 ] #终止条件，否则将进入死循环【递归死循环】
	then
	    let sum=$sum+1
	    echo $sum $$       #输出sum值和当前PID
	    ($0 $sum)          #sum小于10时将继续调用自身执行累加
	fi
	exit 0
	personball@vostro:scan$./testsubshell.sh 1
	2 32543
	3 32544
	4 32545
	5 32546
	6 32547
	7 32548
	8 32549
	9 32550
	10 32551
	personball@vostro:scan$
