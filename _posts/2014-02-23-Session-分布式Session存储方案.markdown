---
layout: post
title: "Asp.net Mvc分布式Session存储方案"
categories: Mvc网站开发 可扩展性
---

##要玩集群的时候，怎么处理会话状态Session？
InProc模式的sessionState是不能用了，因为这是在web服务器本机进程里的，会造成各节点数据不一致。除非在分流的时候用ip hash策略，不是长久之计。  

1. 用StateServer模式，可能单点故障
2. 用SQLServer模式，需要另配一个数据库实例，SQLServer不方便做读写分离等集群化架构
3. 用Custom模式，自定义

前两种不说了，有兴趣可以自己去看看，我们来看第三种，怎么自定义实现Session存储。

##SessionStateStoreProviderBase

要自定义Session Provider，需要继承SessionStateStoreProviderBase，并override一系列方法，具体不列了，有点多。
这里提供一个源码参考：[github](https://github.com/enyim/memcached-providers/blob/master/MemcachedProviders/MembaseSessionStateProvider.cs)

如果懒得自己实现，就直接用这个库。  

###项目名：
memcached-providers
###Github地址：
https://github.com/enyim/memcached-providers [Click]
[Click]:https://github.com/enyim/memcached-providers
###命名空间：
Enyim.Caching.Web
###获取方法：
直接git clone源代码 或 VS使用 Nuget 找到Memcached SessionState Provider
##配置方法：
需要配置membase，[参考](https://github.com/enyim/memcached-providers/blob/master/TestSite/Web.config)  

__注意__，虽然该项目在Memecache下，但是它的SessionStateStoreProvider是由__Membase__提供存储的，__Membase兼容Memcache的api__，但是__未验证__是否可以直接由Memcache实例替代Membase。