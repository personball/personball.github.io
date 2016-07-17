---
layout: post
title: "nuget包管理器控制台下的powershell脚本介绍"
description: "nuget包管理器控制台下的powershell脚本介绍"
category: PowerShell
tags: PowerShell Nuget
---
{% include JB/setup %}

博客有阵子没打理了，今天刚恢复样式，但是标题还是不太正常，总算能凑合看看。

回到正题，最近为了能在VS的程序包管理器控制台上能方便的自定义ps脚本去调整project的package，就开始看powershell的教程，做些笔记。

## 在nuget控制台场景下的powershell

### 自定义脚本放哪？
在nuget包管理器控制台中，变量$profile代表一个特定ps脚本文件的路径，这个文件中的
powershell脚本会在每次nuget包管理器控制台启动的时候自动加载。

如果要直接编辑这个脚本，可以使用如下命令：

    code $profile //code命令是vscode编辑器
    notepad $profile //notepad是用记事本打开这个文件
    mkdir -force (split-path $profile) //假如遇到这个文件所在的目录未创建，可用此命令创建目录

参考：[Setting up a NuGet Powershell Profile](https://docs.nuget.org/consume/Setting-up-NuGet-PowerShell-Profile.md)

### nuget控制台提供的特殊命令

    Find-Package #nuget3.0以上版本可用，搜索在线包源
    Get-Package #获取当前解决方案本地可用的包源，特定选项也可查询在线包源
    Install-Package #这个最常用，安装nuget包
    Sync-Package #这个刚发现貌似挺好用，nuget3.0以上可用，获取当前选中项目已安装的指定nuget包版本，并同步其他项目的包版本
    Uninstall-Package #卸载nuget包
    Update-Package #更新nuget包
    Open-PackagePage #打开nuget包相关网页
    Get-Project #获取当前项目的引用，平时没啥用，nuget console场景下自定义powershell时威力强大

**powershell的注释符号为#**  
**具体命令可用选项，请点击下方参考链接**  
参考：[Package Manager Console Powershell Reference](https://docs.nuget.org/consume/package-manager-console-powershell-reference)

## 定制自己的powershell，减少重复工作

### 安装一系列自己的常用nuget包
项目做多了，有时候发现自己新建项目时，总是要花费半天或者几十分钟去新建一个新项目，一个一个地安装完所有常用的包。
对于码农，这重复劳动不可忍！

打开nuget包管理控制台，输入`code $profile`，在打开的文件中，输入如下脚本

    function Install-PackageForAbpUnitTest{
        Install-Package Abp.TestBase -Version 0.9.1.0
        Install-Package Abp.EntityFramework  -Version 0.9.1.0
        Install-Package NSubstitute
        Install-Package Shouldly
        Install-Package xunit.runner.visualstudio
        Install-Package xunit
        Install-Package Effort.EF6
    } #可能需要重启下nuget包管理器控制台，或者重启vs

这个脚本的作用很明显（可以忽略我在用的Abp框架），怎么使用呢？

    1. 打开sln，在当前解决方案新建一个类库项目（xunit只要是个类库项目就可以）
    2. 打开nuget包管理器控制台，选中刚新建的类库项目
    3. 在nuget包管理器控制台输入install安Tab，选中`Install-PackageForAbpUnitTest`
    4. 然后就等着所有包安装完毕，大功告成。


### 自动设置项目的环境配置
有些公司对于代码部署有严格的流程规范，一般都有多套环境用于开发、测试、验收、部署生产。
所以项目一般会遇到要使用配置转换的情况，但是每个新建项目都要手动去打开VS的配置管理器，手工添加一个个环境，很麻烦。

    function Init-ProjectConfigurationManager{
        $PROJ=Get-Project #这个$PROJ还有很多潜力可以挖掘
        $PROJ.ConfigurationManager.AddConfigurationRow("DEV","Debug",1)
        $PROJ.ConfigurationManager.AddConfigurationRow("GQC","Debug",1)
        $PROJ.ConfigurationManager.AddConfigurationRow("PRE","Release",1)
        $PROJ.ConfigurationManager.AddConfigurationRow("PRD","Release",1)   
        #TODO 怎么才能用powershell脚本触发“右键web.config的添加配置转换”?
    }

效果，可以自己试试，$PROJ还有很多属性和方法，留给你自己探索哈。