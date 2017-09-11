---
layout: post
title: "Abp系列——Abp后台作业系统介绍与经验分享"
description: "Abp系列——Abp后台作业系统介绍与经验分享"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

## 什么是后台作业系统

后台作业系统即`BackgroundJob`，从需求上讲，是一套基础设施，允许我们定义一个作业，在未来指定的某个时间去执行。  
后台作业的一般场景：  

1. 如果某个业务逻辑很复杂，但又不是立即需要反馈结果给用户；  
1. 如果有个任务需要定时循环执行；  
1. 如果有个批量任务；  
1. 如果有个任务需要延后一段时间（在未来某个指定的时间）执行；

举几个典型例子：  

1. 订单在创建后30分钟未支付则自动取消并释放库存；  
1. 一个有几万甚至几十万粉丝的公众号需要同步粉丝信息到数据库；  
1. 某个活动开始前15分钟通知感兴趣的用户进行预热；  
1. 某个与友商合作的项目涉及结算，需要在每月指定日子出账单；  
1. 每天空闲时间段全量刷新缓存或者重建索引；  

## Abp的后台作业系统

Abp的后台作业系统有两个抽象概念：  

1. BackgroundWorker；  
1. BackgroundJob；  

*如果是第一次用Abp的后台作业系统，可以点击下面这个链接到官方文档看具体使用方法，这里主要介绍下这两个的特点和联系。*

[Background Jobs and Workers](https://aspnetboilerplate.com/Pages/Documents/Background-Jobs-And-Workers)  

### BackgroundWorker

先说`BackgroundWorker`，BackgroundWorker其实就是基于一个`Timer`（`AbpTimer`）设置时间间隔，在进程中定时执行。  

在Abp核心模块`AbpKernelModule`的`PostInitialize`方法的最后：

    if (Configuration.BackgroundJobs.IsJobExecutionEnabled)
    {
        var workerManager = IocManager.Resolve<IBackgroundWorkerManager>();
        workerManager.Start();
        workerManager.Add(IocManager.Resolve<IBackgroundJobManager>());
    }

我们看到可以通过`Configuration.BackgroundJobs.IsJobExecutionEnabled`控制是否启用workerManager，同时`IBackgroundJobManager`其实是个Worker（这里说的是JobManager，不是Job）。  

### BackgroundJob

`IBackgroundJobManager`继承了`IBackgroundWorker`，并且Abp默认实现的`BackgroundJobManager`也是基于Worker的机制，其基类是`PeriodicBackgroundWorkerBase`，静态构造方法中指定了每5秒拉取一次作业信息。  

在`Abp.dll`程序集中，`Configuration.BackgroundJobs.IsJobExecutionEnabled`启用时，默认用`InMemoryBackgroundJobStore`来存储作业信息。  

在Abp核心模块`AbpKernelModule`的`PostInitialize`方法的最开始`RegisterMissingComponents`(假如没有注册其他实现)：

    if (Configuration.BackgroundJobs.IsJobExecutionEnabled)
    {
        IocManager.RegisterIfNot<IBackgroundJobStore, InMemoryBackgroundJobStore>(DependencyLifeStyle.Singleton);
    }
    else
    {
        IocManager.RegisterIfNot<IBackgroundJobStore, NullBackgroundJobStore>(DependencyLifeStyle.Singleton);
    }

如果`Configuration.BackgroundJobs.IsJobExecutionEnabled`未启用，则用`NullBackgroundJobStore`，如果启用，默认用的是`InMemoryBackgroundJobStore`，除非仅作演示用，否则`InMemoryBackgroundJobStore`没什么用，因为这些默认实现都没处理集群场景下Job的分布式执行和防止重复执行。  

为便于我们在生产环境使用，看下面两个：  

* [Hangfire-Integration](https://aspnetboilerplate.com/Pages/Documents/Hangfire-Integration)  
* [Quartz-Integration](https://aspnetboilerplate.com/Pages/Documents/Quartz-Integration)

Abp框架提供了`Abp.Hangfire`和`Abp.Quartz`模块用于集成可用于集群化场景下的作业实现（防止重复执行等问题，Abp默认实现的`IBackgroundWorkerManager`和`IBackgroundJobManager`并未处理相关问题）；

## 总结下

上面有点缺乏条理，总结下：  

1. `Configuration.BackgroundJobs.IsJobExecutionEnabled`不仅影响BackgroundJob的执行，同时也影响BackgroundWorker的执行；  
1. Abp默认实现的`IBackgroundJobStore`不支持集群环境下、分布式环境下的Job执行；
1. Abp框架提供了`Abp.Hangfire`和`Abp.Quartz`模块支持集群环境下、分布式环境下的Job执行；

然后，还有个关于module-zero的小坑，提一下：

当我们项目中使用了module-zero模块，这个模块在业务数据库中实现了一个简单版本的`IBackgroundJobStore`。  

对，还是没处理重复执行的问题，而且你不用配置，只要用了module-zero，但没配置用Hangfire或者Quartz，这个机制就悄无声息的在跑！  

这时候，job可能会重复执行，job可能去不同项目执行。  
*好多朋友都被这个坑过，引起的现象能让你怀疑人生！*  
*module-zero的这个实现，个人认为是abp演示Notification机制的需要，其中有个分发机制是超出5人订阅，则转为Job进行分发。*

明确一下不同Job配置实际上用的是哪个`IBackgroundJobStore`：  

1. 什么都不配置，而且没依赖module-zero模块：`IsJobExecutionEnabled`默认是启用的，用的是基于内存的`InMemoryBackgroundJobStore`；  

1. 什么都不配置，而且依赖了module-zero模块：用的是基于业务数据库的`BackgroundJobStore`，实体是`BackgroundJobInfo`，并且注册在`AbpZeroDbContext`中；  

1. 明确关闭`IsJobExecutionEnabled`：如果没依赖module-zero则用的是空实现`NullBackgroundJobStore`，不进行存储，否则作业信息可以入队，能在其他开启job执行的宿主项目上执行（假如共享了job代码所在的程序集）；  

1. 明确配置依赖了`Abp.Hangfire`或`Abp.Quartz`：`IsJobExecutionEnabled`启用的项目会执行，`IsJobExecutionEnabled`关闭的项目只入队不执行。  

我们推荐的做法是（前提是核心的几个程序集共享，Abp框架并不是只能用于Web开发，也可以寄宿在控制台或win服务中，甚至桌面应用程序），所有iis站点关闭Job的执行，专门提供一个Windows服务启用`IsJobExecutionEnabled`。  

所有宿主程序都必须明确配置集成`Abp.Hangfire`或`Abp.Quartz`，哪怕你觉得这个项目和作业系统八竿子打不着！  
所有宿主程序都必须明确配置集成`Abp.Hangfire`或`Abp.Quartz`，哪怕你觉得这个项目和作业系统八竿子打不着！  
所有宿主程序都必须明确配置集成`Abp.Hangfire`或`Abp.Quartz`，哪怕你觉得这个项目和作业系统八竿子打不着！  

*我中招的那次，有怀疑过是不是AppDomain串了，甚至怀疑代码去不同进程串门了，怀疑人生。*  

最后差点忘说了，如果集成且启用了Hangfire，一定记得单独给他配个数据库，作业信息的扫描频率实在太高，据说Hangfire收费版支持存Redis，估计会好一点。  

