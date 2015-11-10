---
layout: post
title: "分享一个调用msbuild生成解决方案并打包发布的批处理脚本"
description: "分享一个调用msbuild命令生成解决方案并打包发布的批处理脚本。"
category: bat
tags: bat msbuild
---
{% include JB/setup %}

最近工作成果之一，特此记录。


###用于打包的批处理脚本
注意设置 path/to/your/solutionfile.sln 指向vs的解决方案文件。

    setlocal enabledelayedexpansion
    set "filepath=%cd%"
    cd /d  c:\
    if not exist localzips ( mkdir localzips )
    cd localzips
    set RootPath=%1
    if "%RootPath%"=="" (
    set h=%Time:~0,2%
    set h=!h: =0!
    set RootPath=%date:~0,4%%date:~5,2%%date:~8,2%!h!%Time:~3,2%
    )
    mkdir %RootPath% 
    cd %RootPath%
    copy %filepath%\DeployTestGroup01.bat DeployTestGroup01.bat
    copy %filepath%\DeployGroup01.bat DeployGroup01.bat
    touch create_by_click_to_zip_deploy_bat.txt
     msbuild /p:DeployOnBuild=True /p:VisualStudioVersion=12.0 /p:PublishProfile=PRD /P:Configuration=PRD  /p:DeployPackageLocation="c:\localzips\%RootPath%"  path/to/your/solutionfile.sln
    pause
    start .


###项目的发布配置文件PRD.pubxml
注意设置DeployIisAppPath节，和IIS中的站点名称一致。

    <?xml version="1.0" encoding="utf-8"?>
    <Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
      <PropertyGroup>
        <WebPublishMethod>Package</WebPublishMethod>
        <LastUsedBuildConfiguration>PRD</LastUsedBuildConfiguration>
        <LastUsedPlatform>Any CPU</LastUsedPlatform>
        <SiteUrlToLaunchAfterPublish />
        <LaunchSiteAfterPublish>True</LaunchSiteAfterPublish>
        <ExcludeApp_Data>False</ExcludeApp_Data>
        <DesktopBuildPackageLocation>$(DeployPackageLocation)\$(AssemblyName)\$(AssemblyName).zip</DesktopBuildPackageLocation>
        <PackageAsSingleFile>true</PackageAsSingleFile>
        <DeployIisAppPath>Site Name In IIS</DeployIisAppPath>
      </PropertyGroup>
    </Project>

###调用发布包自带脚本的批处理脚本DeployTestGroup01.bat和DeployGroup01.bat 
DeployTestGroup01.bat，使用/T 选项，并非真正执行发布，只是测试预览。
注意设置各项参数。
    
    call path_to_the_cmd_file /T /M:MachineNameOrIp /U:UserName /P:Password
    pause

DeployGroup01.bat，使用/Y 选项，实际执行发布。

    call path_to_the_cmd_file /Y /M:MachineNameOrIp /U:UserName /P:Password
    pause

cmd_file的使用说明，可以在 xxxx.deploy-readme.txt 文件中查看。UserName和Password可以用有权限的域账号，也可以设置IIS管理器用户，参考webdeploy的设置。










