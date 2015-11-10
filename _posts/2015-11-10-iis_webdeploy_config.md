---
layout: post
title: "iis远程发布配置"
description: "iis远程发布配置"
category: iis
tags: IIS Webdeploy
---
{% include JB/setup %}


近期工作总结备忘，下次重新部署时再总结更新。

###基本流程

1. 一台初始化的win2012；
2. 安装服务器角色，启用IIS，启用IIS管理服务，启用.Net相关框架等；
3. 安装webdeploy工具；
4. 打开iis，添加iis管理用户；
5. 配置管理服务，允许远程管理；
6. 右击网站，选“部署”，“启用远程发布”，选择iis用户，点击设置；

###发布方法
1. 直接vs发布，选择远程发布；
2. vs发布打包后，执行批处理使用发布包远程发布；
