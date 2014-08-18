---
layout: post
title: "awk记录分割符RS"
description: "awk记录分割符RS"
category: Shell
tags: Awk Bash
---
{% include JB/setup %}

	$awk -v RS= '{print $1}' test

RS 默认值为\n 换行符。  
此处设置`RS=` 等效于 `RS=“”` 代表一个空行 （若理解有误请指正，在以下例子中符合）

	$cat test
	1.aaaaaaaa
	bbbbbbb
	cccccc

	2.ddddddd
	fffffff
	eeeeeee

	3.zzzzz
	cccccccc
	fd
	$awk -v RS= '{print $1}' test
	1.aaaaaaaa
	2.ddddddd
	3.zzzzz

	$cat test
	1.aaaaaaaa
	bbbbbbb
	cccccc
	2.ddddddd
	fffffff
	eeeeeee

	3.zzzzz
	cccccccc
	fd
	$awk -v RS= '{print $1}' test
	1.aaaaaaaa
	3.zzzzz

注意空行所处位置以及输出的$1的值。