---
layout: post
title: "Abp系列——集成消息队列功能(基于Rebus.Rabbitmq)"
description: "Abp系列——集成消息队列功能(基于Rebus.Rabbitmq)"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

## 前言

由于[提交给ABP作者的集成消息队列机制的PR](https://github.com/aspnetboilerplate/aspnetboilerplate/pull/2264)还未Review完成，本篇以[Abplus](https://github.com/personball/abplus)中的代码为基准来介绍ABP集成消息队列机制的方案。

## Why

为什么需要消息队列机制？  

1. 发布-订阅模式，解耦业务
1. 非必须强一致性的业务场景，借助消息队列剥离到离线处理
1. 各种通知，站内通知、邮件通知、手机短信、微信推送

以上几点，并非互相独立，是几个互相联系的特点。  
开发框架拥有消息队列机制的好处，可以通过以下几个典型场景举例来说明：  


#### 订单支付成功
    
>当第三方支付平台回调通知订单支付成功时，如果没有消息队列，那么：
>
>* 我们必须把后续的业务逻辑和修改订单支付状态的代码都写在一起，根据业务的复杂程度，这个响应时间可能会非常长，容易造成超时
>* 或者第三方支付平台短时间重试多次，造成业务逻辑重复执行
>* 也可能业务逻辑比较复杂，后续其他逻辑（通知推送之类）处理异常，导致整个支付成功逻辑全部回滚
>
>而当我们有消息队列机制支持时：
>
>* 我们一接收到第三方支付平台回调，立马仅处理订单状态和核心的业务逻辑（比如支付后扣库存），其他业务逻辑通过订阅消息去处理
>* 甚至可以一接收到第三方支付平台回调，立即构建订单支付成功消息放入消息队列，这样对于第三方支付平台可以立即收到处理成功的响应
>* 后续其他类似通知推送的非关键需求，其成败不影响关键逻辑，而且可以一直重试直到成功

#### 物流信息同步

>做电商网站时，如果订单比较多，每个订单都需要订阅第三方物流信息，类似上面支付，当物流信息（一个订单多条运送路径记录）推送过来时，可能会比较密集（短时间内几千上万个请求），直接写入数据库（需要先比对，只写入增量部分）可能不是一个好方案。  
>这个时候，放到消息队列里，由消费端按自己的节奏一条条处理最为保险。  
>
>类似的数据同步方案，对实时性要求不太高，单个处理逻辑比较复杂，短时间内数量较大，都可以考虑排队处理。

#### 批量业务处理

>复杂业务的批量处理一直是比较头疼的事情（查询条件、事务等），如果有消息队列，只要查询得到所有可能需要处理的对象，放队列排队，转变成单个业务处理，可以避免很多麻烦，并且可以控制处理进度，也不必担心其中可能发生几个异常影响了其他正常处理。而且，转成单个业务处理，可以继续发布事件和消息，进行后续流程和业务的触发，比如邮件通知或短信通知等供应商限制了调用频率的服务。  

#### 高负载时，削峰填谷

>如题，这一点是指将请求进行排队的能力，可以临时增加处理端以提高请求处理能力，此类方案大多涉及UI交互的变更，具体场景不展开。
>
>这一块，如果UI交互采用异步模式（比如用户提交订单，但不立马告诉用户订单是否创建成功，只反馈创建订单的请求提交成功，订单真正创建成功以其他方式通知用户，再让用户去支付），则属于上面提到过的离线处理，本文介绍的集成方式可以直接支持；  
>
>如果采用同步模式（提交请求，经过较长时间后响应，需要用户等待，处理依然可以通过消息队列排队），则可能需要具体挖掘下RabbitMQ或您采用的其他消息中间件的Request-Response 模式用法，当然也需要注意一下Http请求处理超时的问题。  

#### 其他好处

总的来说：  

业务逻辑编码方面，思维方式逐渐脱离*面向数据* ，可以更加*关注事件*、*关注消息*，更加*面向领域*、*面向对象* ，核心业务逻辑可维护性增强、可扩展性增强。  

系统架构风格方面，支持*事件驱动*、*消息驱动*、*可监控性*、*可扩展性*，更利于系统演化，后期任何时候可通过订阅消息无侵入式的采集数据，拓展功能。

*Tips:*   
消息队列的可靠性，比如RabbitMQ，是经过电信行业检验的，集群、持久化、自动故障转移等特性都支持，而且集群配置和集群升级方案都比较简单方便且成熟。  

RabbitMQ安装请参考[RabbitMQ Notes](/mq/2016/03/15/rabbitmq-notes)

## How
前面啰嗦了一大堆，下面进入正文，ABP如何集成消息队列机制。  

如果嫌本文排版不好，也可以直接看[提交给ABP作者的集成消息队列机制的PR](https://github.com/aspnetboilerplate/aspnetboilerplate/pull/2264)，PR中的说明和用法示例基本和abplus扩展库中的一致。

#### 1.增加命名空间
这里强调一下概念区别，消息(Messages)和事件(Events)是不同的。  

1. 在ABP中，有个EventBus体系，Events和各种Handlers，重点是进程内的业务逻辑解耦，Handlers的代码是可以共享工作单元(UnitOfWork)的，对于允许延后验证的逻辑，是可以随时添加一个单独的Handler去校验并抛出异常，即可以回滚工作单元（事务）；
1. 而Messages体系，在Abp框架内，目前并未集成。Messages的重点是向进程外的系统（外部系统）进行通知，所以有工作单元和事务的时候，一定是事务提交成功后才对外通知消息，否则一旦对外通知了，又发生了事务回滚，再追回消息或者撤销消息就会比较麻烦（消息关联事务或者分布式事务是另一种情况，这里不做介绍）。

所以，我们首先在`Abplus程序集`中引入消息发布器的抽象概念：  

[IMqMessagePublisher](https://github.com/personball/abplus/blob/master/src/Abplus/MqMessages/IMqMessagePublisher.cs)  

    namespace Abp.MqMessages
    {
        /// <summary>
        /// 消息发布接口
        /// </summary>
        public interface IMqMessagePublisher : ITransientDependency
        {
            /// <summary>
            /// 发布
            /// </summary>
            /// <param name="mqMessages"></param>
            void Publish(object mqMessages);

            /// <summary>
            /// 发布
            /// </summary>
            /// <param name="mqMessages"></param>
            /// <returns></returns>
            Task PublishAsync(object mqMessages);
        }
    }

并且提供空实现：  

[NullMqMessagePublisher](https://github.com/personball/abplus/blob/master/src/Abplus/MqMessages/NullMqMessagePublisher.cs)  


*限于篇幅，除简单示意和关键代码外，本文只给github源码链接，不再贴出详细代码。*

#### 2.提供IMqMessagePublisher的RebusRabbitMQ实现

我们集成RabbitMQ，借用了Rebus框架的实现，Rebus在对接RabbitMQ上做了比较好的抽象和封装，[Rebus Wiki](https://github.com/rebus-org/Rebus/wiki)。

程序集`Abplus.MqMessages.RebusCore`，核心实现：  

[RebusRabbitMqPublisher](https://github.com/personball/abplus/blob/master/src/Abplus.MqMessages.RebusCore/MqMessages/Publishers/RebusRabbitMqPublisher.cs)  

其中，以反射方式，抓取了一些Session信息：  

    private void TryFillSessionInfo(object mqMessages)
    {
        if (AbpSession.UserId.HasValue)
        {
            var operatorUserIdProperty = mqMessages.GetType().GetProperty("OperatorUserId");
            if (operatorUserIdProperty != null && (operatorUserIdProperty.PropertyType == typeof(long?)))
            {
                operatorUserIdProperty.SetValue(mqMessages, AbpSession.UserId);
            }
        }

        if (AbpSession.TenantId.HasValue)
        {
            var tenantIdProperty = mqMessages.GetType().GetProperty("TenantId");
            if (tenantIdProperty != null && (tenantIdProperty.PropertyType == typeof(int?)))
            {
                tenantIdProperty.SetValue(mqMessages, AbpSession.TenantId);
            }
        }
    }

*程序集`Abplus.MqMessages.RebusCore`是同时被`Abplus.MqMessages.RebusPublisher`和`Abplus.MqMessages.RebusRabbitMqConsumer`依赖的，以便消费端依然具有发布消息的能力。*

#### 3.封装发布模块，便于项目使用

程序集`Abplus.MqMessages.RebusPublisher`，发布模块：  

[RebusRabbitMqPublisherModule](https://github.com/personball/abplus/blob/master/src/Abplus.MqMessages.RebusPublisher/MqMessages/Publishers/RebusRabbitMqPublisherModule.cs)  

这个模块，是封装消息队列的配置和启动连接，使用时，在项目启动模块上配好`[DependsOn(typeof(RebusRabbitMqPublisherModule))]`，并引入命名空间`Abp.Configuration.Startup`，即可配置相关参数，示例如下：  

    namespace Sample
    {
        [DependsOn(typeof(RebusRabbitMqPublisherModule))]
        public class SampleRebusRabbitMqPublisherModule : AbpModule
        {
            public override void PreInitialize()
            {
                Configuration.Modules.UseRebusRabbitMqPublisher()
                    .UseLogging(c => c.NLog())
                    .ConnectionTo("amqp://dev:dev@rabbitmq.local.cn/dev_host");

                Configuration.BackgroundJobs.IsJobExecutionEnabled = true;
            }

            public override void Initialize()
            {
                IocManager.RegisterAssemblyByConvention(Assembly.GetExecutingAssembly());
            }

            public override void PostInitialize()
            {
                Abp.Dependency.IocManager.Instance.IocContainer.AddFacility<LoggingFacility>(f => f.UseNLog().WithConfig("nlog.config"));

                var workManager = IocManager.Resolve<IBackgroundWorkerManager>();
                workManager.Add(IocManager.Resolve<TestWorker>());// to send TestMqMessage every 3 seconds
            }
        }
    }

只要项目配置好模块依赖，即可在代码中通过构造函数注入或者属性注入使用`IMqMessagePublisher`接口进行消息发布。

#### 4.封装消费端模块

同消息发布模块，消费模块在程序集`Abplus.MqMessages.RebusConsumer`中，代码见：  

[RebusRabbitMqConsumerModule](https://github.com/personball/abplus/blob/master/src/Abplus.MqMessages.RebusConsumer/MqMessages/Consumers/RebusRabbitMqConsumerModule.cs)。  

使用方式：  

    namespace Sample
    {
        [DependsOn(typeof(RebusRabbitMqConsumerModule))]
        public class SampleRebusRabbitMqConsumerModule : AbpModule
        {
            public override void PreInitialize()
            {
                Configuration.Modules.UseRebusRabbitMqConsumer()
                    .UseLogging(c => c.NLog())
                    .ConnectTo("amqp://dev:dev@rabbitmq.local.cn/dev_host")
                    //以当前项目名作为队列名
                    .UseQueue(Assembly.GetExecutingAssembly().GetName().Name)
                    //register assembly whitch has rebus handlers
                    .RegisterHandlerInAssemblys(Assembly.GetExecutingAssembly());
            }

            public override void Initialize()
            {
                base.Initialize();
            }

            public override void PostInitialize()
            {
                Abp.Dependency.IocManager.Instance.IocContainer.AddFacility<LoggingFacility>(f => f.UseNLog().WithConfig("nlog.config"));
            }
        }
    }

只要项目配置好模块依赖，消费端亦可在代码中通过构造函数注入或者属性注入使用`IMqMessagePublisher`接口进行消息发布。

消费端的RebusHanlder示例：  

    namespace Sample.Handlers
    {
        public class TestHandler : IHandleMessages<TestMqMessage>
        {
            public ILogger Logger { get; set; }
            public IMqMessagePublisher Publisher { get; set; }
            public TestHandler()
            {
                Publisher = NullMqMessagePublisher.Instance;
            }

            public async Task Handle(TestMqMessage message)
            {
                var msg = $"{Logger.GetType()}:{message.Name},{message.Value},{message.Time}";
                Logger.Debug(msg);
                await Publisher.PublishAsync(msg);//send it again!
            }
        }
    }

#### 5.忘了说，消息格式的定义

消息的定义，不依赖任何框架，也不依赖Abp或者Abplus，因为前面发布接口`IMqMessagePublisher`定义时采用的类型是object

    void Publish(object mqMessages);

例如：

    namespace Sample.MqMessages
    {
        /// <summary>
        /// Custom MqMessage Definition. No depends on any framework,this class library can be shared as nuget pkg.
        /// </summary>
        public class TestMqMessage
        {
            public string Name { get; set; }
            public string Value { get; set; }
            public DateTime Time { get; set; }
        }
    }

这个*消息定义可以单独作为一个程序集，发布到私有nuget服务器中，以便团队共享*。

## Tips & Extended

Abplus中还提供了几个消息队列相关的常用实现：  

1. Abplus `IMessageTracker` 定义消费端处理幂等机制的接口  
1. Abplus.MqMessages `EventDataPublishHandlerBase<TEventData, TMqMessage>` EventData和MqMessage一对一的泛型版抽象发布Handler，这是`EventDataHandler`  
1. Abplus.MqMessages `AbpMqHandlerBase`是包含`IMessageTracker`属性的消费端MqHandler抽象基类  
1. Abplus.MqMessages.AuditingStore 审计日志发布到消息队列  
1. Abplus.MqMessages.RedisStoreMessageTracker 消费端消费行为的幂等支持，基于Redis存储，[Rebus Handler的重试机制和幂等处理](/pubsub/2017/07/09/rebus-handler-idempotence)  

上述具体实现请参考[Abplus代码库](https://github.com/personball/abplus)。

