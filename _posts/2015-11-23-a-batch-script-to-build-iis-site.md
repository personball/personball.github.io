---
layout: post
title: "分享一个批处理脚本，创建iis站点及程序池"
description: ""
category: iis
tags: bat IIS
---
{% include JB/setup %}

## 建站批处理

batch_createSites.bat

    @echo off
    rem 以管理员身份执行本脚本，可添加多条call 以建立多个站点
    call path\to\createSites.bat www com.yourdomain yourdomain.com d:\Sites
    pause

createSites.bat

    @echo off
    rem 以管理员身份执行本脚本

    set domain_id=%1
    set site_name_prefix=%2
    set domain_postfix=%3
    set root_path=%4

    set site_name=%site_name_prefix%.%domain_id%
    echo %site_name%
    set domain_name=%domain_id%.%domain_postfix%
    echo %domain_name%
    set physical_Path=%root_path%\%site_name%
    echo %physical_Path%
    mkdir %physical_Path%

     inetsrv\appcmd add site /name:%site_name% /physicalPath:%physical_Path% /bindings:http/*:80:%domain_name%
     inetsrv\appcmd add apppool /name:%site_name% /managedRuntimeVersion:v4.0 /managedPipelineMode:Integrated
     inetsrv\appcmd set site /site.name:%site_name% /[path='/'].applicationPool:%site_name%

    rem 以下两行用于删除站点和应用程序池
    rem inetsrv\appcmd delete site /site.name:%site_name%
    rem inetsrv\appcmd delete apppool /apppool.name:%site_name%

    pause

## 常用appcmd命令

解锁config文件

    inetsrv\appcmd unlock config -section:system.webServer/modules
    inetsrv\appcmd unlock config -section:system.webServer/handlers

列出所有iis站点
    
    inetsrv\appcmd list site

启用预加载和AlwaysRunning

    inetsrv\appcmd set apppool %apppool_name% /startMode:AlwaysRunning
    inetsrv\appcmd set site %site_name% /applicationDefaults.preloadEnabled:True

