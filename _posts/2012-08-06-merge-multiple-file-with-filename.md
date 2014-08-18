---
layout: post
title: "awk多文件合并并按文件名分段"
description: "Shell awk多文件合并，按文件名分段"
category: Shell
tags: Awk Bash
---
{% include JB/setup %}

以下代码满足这样的需求：

1. 多个文件内容合并到一个文件A中（如果没有下面这条，使用cat就能解决）
2. 文件A中每段内容之前保留原先的文件名

	awk 'tmp!=FILENAME{tmp=FILENAME;print tmp":"} {print "\t"$0}' * >Ex.report

得到的文件内容如下

	personball@vostro:Ex$ cat Ex.report 
	app_log.2012-7-31.Ex:
	  NullReferenceException 17
	  Exception 47
	  HttpRequestValidationException 2
	  IndexOutOfRangeException 7
	  InvalidOperationException 114
	  SqlException 95
	  HttpException 93
	  FormatException 2
	  ApplicationException 13
	  IOException 50
	  ArgumentException 14
	  SmtpException 1
	 异常类型事件总计：454/455
	app_log.2012-8-1.Ex:
	  NullReferenceException 20
	  Exception 65
	  HttpRequestValidationException 2
	  IndexOutOfRangeException 16
	  InvalidOperationException 112
	  SqlException 112
	  HttpException 168
	  FormatException 7
	  ApplicationException 11
	  IOException 62
	  ArgumentException 17
	 异常类型事件总计：592/593