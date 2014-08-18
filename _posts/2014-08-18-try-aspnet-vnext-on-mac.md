---
layout: post
title: "初尝 AspNet vNext On Mac"
description: "在Mac上尝试AspNet vNext"
category: Web开发
tags: [AspNetvNext]
---
{% include JB/setup %}

`网上关于AspNet vNext的介绍已经非常多，本文不再赘述，仅记录下Mac环境的几点注意事项。`

###环境
* OSX 10.9.4
* Mono 3.6.1
* Kvm 1.0.0-alpha4-10285

mono官网提供了mac使用的安装包，安装比较顺利，不详细说了。  
这里比较麻烦的就是kvm，kvm的安装文件获取需要访问亚马逊的服务，网速不给力。  
用HomeBrew安装的时候，为了下载这个包，命令重试了二十多次。  
不过文件支持断点续传，所以需要多一些耐心。

###尝试Console程序
这里直接获取github上Aspnet/Home 版本库以尝试运行。

	git clone git://github.com/aspnet/Home.git

然后直接进入Home下的samples/ConsoleApp，运行kpm获取依赖的库：

	kpm restore

完成后，用` k run `运行，命令行会输出：

	[wbc@mbp:ConsoleApp]$k run
	Hello World
	[wbc@mbp:ConsoleApp]$

到此为止，你已经成功在mac系统上以vnext的方式成功运行了.net程序。  
`程序文件名并不强制要求为Program.cs只要代码中有main方法就行。`

###但ConsoleApp目录下并没有依赖的库，那么库在哪？
找找看

	[wbc@mbp:ConsoleApp]$cd
	[wbc@mbp:~]$ls -al

发现～目录下出现了` .kvm/ ` 和` .kpm/ `两个目录

	[wbc@mbp:~]$cd .k    //按两下Tab
	.kpm/ .kre/ 
	[wbc@mbp:~]$cd .kpm/
	[wbc@mbp:.kpm]$ls
	packages
	[wbc@mbp:.kpm]$ls -p packages/
	System.Console/		//Hello World依赖的库

.kpm下有所有restore下载的库，而.kvm目录下其实是多个KVM环境，不多说了。

###尝试运行HelloWeb
可能看多了各种AspNet vNext的尝试文章，会看花了眼，老想着用k web命令运行web程序。其实目前在mac系统下，还不支持self-host。所以我们要使用一个server。  
先回到samples目录下，进入HelloWeb，`kpm restore`后：
	
	[wbc@mbp:HelloWeb]$k kestrel
	Started

这时就可以访问[localhost:5004](http://localhost:5004)了，出现一个welcome页面。  
`k 后面跟随的参数应该是和project.json中配置的commands节一致。`  
然后如何停止kestrel？使用常用的CTRL+C并不能中止kestrel，也尝试了CTRL+D，也不行。最后发现`CTRL+Z`可以，但也不完全，再次运行k kestrel的时候会提示地址已占用。所以，最终还是要去用ps命令找到进程号，用`kill -9 [pid]` 解决。

###尝试HelloMvc
restore有点问题，尝试失败。可能是示例程序依赖的库，在mac下还没有准备好，不仔细排查了，等正式版。

###总结
虽然目前正式版还没出来，各项目还有不完善的地方，但前途还是光明的。
如果vNext正式版发布后，能出现一个类似ROR中的rails脚手架等功能，那肯定能在非windows社区中获得更大的人气。
将.Net从VS中解放出来，会更有生命力。

参考：

* [ASP.NET vNext 概述](http://www.cnblogs.com/shanyou/p/3764070.html)
* [在Linux上运行ASP.NET vNext](http://www.cnblogs.com/sjyforg/p/3807038.html)
* [开发 ASP.NET vNext 初步总结（使用Visual Studio 2014 CTP1）](http://www.cnblogs.com/kvspas/p/asp-net-mvc6-vnext.html)
* [#107:An exception was thrown by the type initializer for HttpApi](https://github.com/aspnet/Home/issues/107)


