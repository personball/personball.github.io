---
layout: post
title: "分享一个批处理脚本，创建iis站点及程序池"
description: ""
category: iis
tags: bat IIS
---
{% include JB/setup %}

    @echo off
    rem 以管理员身份执行本脚本

    set domain_id=msite
    set site_name_prefix=com.ymc.platform.feature
    set domain_postfix=feature.platform.ymc.com
    set root_path=d:\WebSites

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

