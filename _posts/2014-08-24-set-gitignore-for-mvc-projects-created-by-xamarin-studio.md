---
layout: post
title: "为 Xamarin Studio 创建的 Asp.Net Mvc 项目配置 gitignore"
description: "为 Xamarin Studio 创建的 Asp.Net Mvc 项目配置 gitignore"
category: Mono
tags: git mac AspNetMvc
---
{% include JB/setup %}

今天在尝试 Mac 下使用 Xamarin Studio （以下简称XS） 开发 Asp.Net Mvc 项目，发现XS没启用版本控制，故自己去命令行下使用 git init，想到需要一个.gitignore文件。于是在github上翻到一个不错的库：

[A collection of useful .gitignore templates](https://github.com/github/gitignore)

里面都是各种类型的项目使用git时所需要的gitignore文件，可以直接拿来用哦～

但是很可惜，没发现适用于XS的！

于是拿了VisualStudio.gitignore作为原始模板，在后面加上了Mac系统下一些需要忽略的情况：

	#将VisualStudio.gitignore的内容复制下来，放到项目目录下作为.gitignore
	#在.gitignore最后添加如下内容

	#Mac OSX .DS_Store 
	.DS_Store

	#Xamarin Studio User prefers
	*.userprefs


.userprefs一看就知道是用户偏好设置，是XS项目的设置。  
.DS_Store

>.DS_Store (英文全称 Desktop Services Store)[1] 
>是一种由苹果公司的Mac OS X操作系统所创造的隐藏文件，目的在于存贮文件夹的自定义属性。