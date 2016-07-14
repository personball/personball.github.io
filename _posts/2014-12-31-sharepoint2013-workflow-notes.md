---
layout: post
title: "SharePoint2013学习笔记之启用工作流"
description: "SharePoint2013学习笔记之工作流，SharePoint2013工作流准备工作，SharePoint2013工作流基础，Windows Workflow Foundation。"
category: sharepoint
tags: SharePoint2013 Workflow WWF
---
{% include JB/setup %}

### 场景及前言
最近工作上开始使用SharePoint2013，遇到新建场无法启用工作流的情况，故把解决方法及部分知识点总结下。  

__注:__ SharePoint2013的工作流和SharePoint2010的工作流有一定差异，前后不兼容，不仅是开发方面，架构上也不一样。SharePoint2010的工作流是集成在SharePoint内部的，而SharePoint2013的工作流是独立出来的，这也是为什么下文指出需要再安装一个Workflow Manager1.0的原因所在。  
另外，对于和我一样没有任何工作流基础的人来说，需要学习工作流的基础和开发操作还是得从WWF（Windows Workflow Foundation）入手，WWF4.0和之前的版本不兼容，是重新设计的，所以我们只需关注WWF4.0，以及WWF4.5。_WWF4.5对WWF4.0的增强在于WWF4.0内没有状态机工作流_  

入门学习资料请参考本博客[Good Books](http://personball.com/books.html)

### SharePoint2013工作流前提准备

* 开发机安装visio2013专业版（SharePoint Designer 2013也是必备的）
* 服务器端[安装Workflow Manager 1.0](http://msdn.microsoft.com/zh-cn/library/jj193525.aspx)，[配置Workflow Manager 1.0](http://msdn.microsoft.com/zh-cn/library/jj193510.aspx)
* [安装和配置 SharePoint Server 2013 的工作流](http://technet.microsoft.com/zh-cn/library/jj658588(office.15).aspx)

经过以上步骤，使用SPD添加工作流的时候就可以选择SharePoint2013工作流平台类型了。

### SharePoint2013工作流流程控制模板

* 流程图工作流
* 顺序工作流
* 状态机工作流

建议先根据《Beginning WF: Windows Workflow in .NET 4.0》学习入门WWF。可以使用VS2012或VS2013进行演练。书中涉及VB表达式的情况可以直接用相应的C#表达式，部分计算公式有问题，稍微注意下就可以修正。有问题请留言或发Email给我，欢迎交流。