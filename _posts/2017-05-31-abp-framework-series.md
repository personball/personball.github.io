---
layout: post
title: "abp framework series"
description: "Abp介绍和经验分享系列文章"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

很久没动博客了，人比较懒。  
最近想写点啥，主要就介绍下ABP框架和我这两年的使用经验。  
文档翻译之类的工作就算了，需要的请参考：  
[官方文档](https://www.aspnetboilerplate.com/Pages/Documents)  
*PS:官方文档末尾有中文文档的链接，这里就不贴了*

先列个提纲，有想到的不定期补充，思路略混乱。

## What Is Abp
1. QuickStart:概述、思想、入门和HelloWorld
1. QuickStart:正确理解Abp解决方案的代码组织方式、分层和命名空间

### Abp框架已实现的功能介绍
1. 模块化，执行流程介绍
1. 动态映射webapi，优劣介绍和推荐使用

### Module-Zero模块已实现的功能介绍
1. RBAC:用户、角色和功能权限 
1. 组织单元:组织机构及数据权限
1. 身份认证:Asp.net Identity
1. Notification:通知，订阅分发和实时通知 
1. 其他Abp框架级机制的默认实现

### 常用配置示例
1. Swagger API文档自动化

## How To Use Abp
1. 业务场景分析:EventData、Handler、UnitOfWork和观察者模式
1. 业务场景分析:实体，值对象，充血，private set
1. 领域层代码设计:聚合根的目的
1. 领域层代码设计:装饰模式的目的
1. 领域层代码设计:防止对象泛滥，领域服务轻量化
1. 领域层代码设计:业务异常与错误码设计及异常提示语的本地化

## How To Extend Abp
1. 模块化，什么时候需要写一个模块?
1. 如何修复Signalr问题?
1. 如何引入消息机制?基于Rebus.Rabbitmq

## 其他主题
1. T4应用:权限树定义（需puyuwang授权）
1. T4应用:MqMessages Auto Generate
1. T4应用:EventDataPublishHandler Auto Generate
1. AbpTestBase:单元测试项目，推荐实践

## Abplus扩展库介绍，解决的问题
1. webapi接口版本化
1. 发布队列消息的泛型版默认handler实现