---
layout: post
title: "远程安装、更新windows服务bat脚本分享"
description: "远程安装、更新windows服务bat脚本分享,可用于windows上安装的jenkins"
category: ci
tags: Bat WinServiceDeploy
---
{% include JB/setup %}

话不多说，有兴趣的自己可以仔细研究下涉及的命令：net use、sc、robocopy

## 脚本

    set BuildConfig=【ENV】
    set BuildExeName=【your_exe_name】.exe
    set BuildProjectBinPath=【path\to\bin】\%BuildConfig%

    set DeployServiceName=【your_service_name】
    set DeployServer=\\【your_server_name】
    set DeployServerUserName=【userName】
    set DeployServerPassword=【password】
    set DeployRootPath=d$\Services
    set InstallRootPath=D:\Services

    set SLEEP=ping 127.0.0.1 /n

    echo "Config Transform..."
    copy %BuildProjectBinPath%\App.%BuildConfig%.config %BuildProjectBinPath%\%BuildExeName%.config /Y
    echo "create net use link"
    net use %DeployServer%\%DeployRootPath% %DeployServerPassword% /user:%DeployServerUserName% 

    echo "query service exists or not..."
    sc %DeployServer% query %DeployServiceName%
    if errorlevel 1060 goto :createNewService
    goto :updateExistService

    :createNewService
    echo "start create New Service..."
    echo "robocopy files..."
    robocopy %BuildProjectBinPath%\ %DeployServer%\%DeployRootPath%\%DeployServiceName%\ /E
    echo "sc create ..."
    sc %DeployServer% create %DeployServiceName% displayName= %DeployServiceName% binPath= %InstallRootPath%\%DeployServiceName%\%BuildExeName% start= auto
    echo "sc start ..."
    sc %DeployServer% start %DeployServiceName%
    goto :exit

    :updateExistService
    echo "start update Exist Service..."
    echo "stop service..."
    sc %DeployServer% query %DeployServiceName% | find /I "STATE" | find "STOPPED"
    if errorlevel 1 goto :stop
    goto :start

    :stop
    echo "try to stop service..."
    sc %DeployServer% stop %DeployServiceName%
    %SLEEP% 4 > nul
    sc %DeployServer% query %DeployServiceName% | find /I "STATE" | find "STOPPED"
    if errorlevel 1 goto :stop
    echo "stop service Success!"
    goto :start

    :start
    echo "robocopy files..."
    robocopy %BuildProjectBinPath%\ %DeployServer%\%DeployRootPath%\%DeployServiceName%\ /E
    echo "start service..."
    sc %DeployServer% start %DeployServiceName%
    goto :exit

    :exit




## 参考资料

[net use and sc](http://www.cnblogs.com/yumianhu/p/3710737.html)
[robocopy](http://www.cnblogs.com/pegasus923/archive/2011/01/12/1912481.html)