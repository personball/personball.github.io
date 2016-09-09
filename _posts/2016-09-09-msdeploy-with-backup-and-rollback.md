---
layout: post
title: "IIS站点发布和备份工具MSdeploy介绍"
description: "IIS站点发布和备份工具MSdeploy介绍"
category: IIS
tags: Bat IIS WebDeploy
---
{% include JB/setup %}


前提准备：完整安装webdeploy 3.0版

## msdeploy 同步站点
命令所在目录`C:\Program Files\IIS\Microsoft Web Deploy V3>`

    msdeploy.exe -verb:sync -source:iisapp=<siteName> -dest:auto,computername=<remoteComputerName>

## msdeploy 启用backup

1. 以管理员身份打开powershell，进入路径%programfiles%\IIS\Microsoft Web Deploy V3\scripts\
2. 加载BackupScripts.ps1（加载ps脚本，使用`. .\BackupScripts.ps1`）
3. 根据需要执行以下命令

>       # Turns on all backup functionality
>       TurnOn-Backups -On $true                  #启用必须执行这条
>       # Turns off all backup functionality
>       TurnOn-Backups -On $false
>       # Changes default global backup behavior to enabled
>       Configure-Backups -Enabled $true          #启用必须执行这条
>       # Changes default backup behavior for site "foo" to enabled
>       Configure-Backups -SiteName "foo" -Enabled $true
>       # Changes the path of where backups are stored to a sibling directory named "siteName_snapshots".  
>       # For more information about path variables, see the "backupPath" attribute in the section 
>       # "Configuring  Backup Settings on the Server for Global usage manually in IIS Config"
>       Configure-Backups -BackupPath "{SitePathParent}\{siteName}_snapshots"
>       # Configures default backup limit to 5 backups
>       Configure-Backups -NumberOfBackups 5
>       # Configures sync behavior to fail if a sync fails for any reason
>       Configure-Backups -ContinueSyncOnBackupFailure $false  #如果备份失败则不继续同步
>       # Adds providers to skip when performing a backup
>       Configure-Backups -AddExcludedProviders @("dbmysql","dbfullsql")

4. 默认备份目录为`{sitePathParent}\{siteName}_snapshots`
5. msdeploy 查看备份设置

        #查看本地backup配置，cmd命令
        msdeploy.exe -verb:dump -source:backupSettings=com.test.msdeploy -xml
        #查看指定服务器的backup配置
        msdeploy.exe -verb:dump -source:backupSettings=com.test.msdeploy,computername=sh-test -xml
        <output>
        <traceEvent eventLevel="Info" type="Microsoft.Web.Deployment.DeploymentAgentTraceEvent" message="正在将 ID“73c5bf3e-9ffe-4c9d-bdfa-8d2bb402c6bf”用于到远程服务器的连接。" />
        <MSDeploy.backupSettings>
            <backupSettings path="com.test.msdeploy">
            <backupSetting turnedOn="True" ReadWrite="False" />
            <backupSetting enabled="True" ReadWrite="False" />
            <backupSetting numberOfBackups="4" ReadWrite="False" />
            <backupSetting continueSyncOnBackupFailure="False" ReadWrite="False" />
            <backupSetting excludedProviders="appPoolEnable32Bit; appHostAuthOverride;appPoolNetFx; appPoolPipeline; setAcl; createApp" ReadWrite="False" />
            </backupSettings>
        </MSDeploy.backupSettings>
        </output>
        

*msdeploy的source选项和dest选项可以通过指定computername进行远程服务器之间操作*
*msdeploy的备份配置远程同步需要设置iis服务委派和授权等，略过不表*

## msdeploy 手动backup

    msdeploy.exe -verb:sync -source:backupManager -dest:backupManager=siteName
    msdeploy.exe -verb:sync -source:backupManager -dest:backupManager=siteName,computername=<yourComputerName>

## msdeploy rollback

    #查看所有的备份
    msdeploy.exe -verb:dump -source:backupManager=<siteName>
    #用最近的一份备份还原
    msdeploy.exe -verb:sync -source:backupManager -dest:backupManager=<siteName>,useLatest=true

## msdeploy公共设置

    公共设置(可用于所有提供程序):

>    computerName=<名称>             远程计算机的名称或代理 URL
>    wmsvc=<名称>                    用于 Web 管理服务(WMSvc)的远程计算机的名称或代
>    理 URL。假设服务正在侦听端口
>                                    8172。
>    authtype=<名称>                 要使用的身份验证方案。默认设置为“NTLM”。如果
>    指定了 wmsvc
>                                    选项，则默认设置为“基本”。
>    userName=<名称>                 远程连接时用于身份验证的用户名(如果使用“基本
>    ”身份验证，则为必填项)。
>    password=<密码>                 用于远程连接的用户密码(如果使用“基本”身份验
>    证，则为必填项)。
>    storeCredentials=<目标>         用户名和密码将存储在 Windows 凭据管理器中的目
>    标标识符下。
>    getCredentials=<目标>           目标标识在连接到远程计算机时要使用的 Windows
>    凭据管理器中的凭据(用户名和密码)。
>    encryptPassword=<密码>          用于加密/解密任何安全数据的密码。
>    includeAcls=<布尔值>             如果为 True，则在操作中包括 ACL (适用于文件系
>    统、注册表和元数据库)。
>    tempAgent=<布尔值>               在远程操作期间，暂时安装远程代理。
>    publishSettings=<文件路径>        包含远程连接信息的发布设置文件的文件路径。


[参考文章](http://www.iis.net/learn/publish/using-web-deploy/web-deploy-automatic-backups)