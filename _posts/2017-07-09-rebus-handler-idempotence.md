---
layout: post
title: "Rebus Handler的重试机制和幂等处理"
description: "简单介绍Rebus消费端Handler的重试机制和如何引入幂等处理机制。"
category: PubSub
tags: Rebus Amqp
---
{% include JB/setup %}

## 1.场景
当一个消费端（win服务）中包含多个Handler订阅了同一个MqMessage。

## 2.执行顺序
假设有四个Handler: Ha,Hb,Hc,Hd。
### 2.1执行顺序可配置

    Configure.With(...)
    .Option(o => {
        o.SpecifyOrderOfHandlers(c =>  c.First<ThisHandler>()
                                        .Then<AnotherHandler>()
                                        .Then<YetAnotherHandler>())
    })

## 3.重试机制
假设执行顺序是Ha->Hb->Hc->Hd，其中Ha,Hb执行成功，Hc异常，默认重试5次，仅重试Hc，重试5次后依然失败，则消息将被转发到错误队列。

## 4.重新入队
在进入错误队列后，错误队列的消费端将错误消息消费并记录数据库（需要自己实现）。在错误队列的管理界面，查询错误消息并重新入队，直接发布到之前丢出这个消息的队列中。
再次接受到这个消息后，又将执行Ha->Hb->Hc->Hd。注意，此时Ha，Hb被重复执行了。

## 5.幂等
当重新入队后，原先执行成功的Handler将再次执行。对于具体业务场景，此时，Ha，Hb：

1. 可能抛异常：因为之前代码执行成功后，实体状态已变更，本次操作在验证状态时，发现状态非法（比如已支付订单不可再次支付）；
1. 可能不受影响：因为某些操作允许多次重复执行，或者在实体的实例方法上，验证状态后默认不抛异常（比如已删除的对象，再次删除，默认不抛异常）；
1. 最严重的：由于执行的代码逻辑是纯粹的新增记录，这样必然重复执行，向数据库表中新增了重复的记录（比如重复结算或重复存储了同一个订单）；

场景有非常多，不可能一一举例和防范，故必须实现多个handler订阅同一个消息时，各个handler自己必须实现幂等性。

*幂等性* 指的是（个人理解）：

    某一个请求（拥有标识本次请求的唯一id），经过处理后，同一个请求（唯一id不变）再次过来时，处理程序能识别这是之前处理过的，能采取忽略或者直接返回上次处理结果的措施。

针对[Rebus的消息幂等处理](https://github.com/rebus-org/Rebus/wiki/Idempotence)

    private readonly IMessageContext _messageContext;
    private readonly IMessageTracker _messageTracker;
    public SomeMessageHandler(IMessageContext messageContext, IMessageTracker messageTracker)
    {
        _messageContext = messageContext;
        _messageTracker = messageTracker;
    }
    public async Task Handle(SomeMessage message)
    {
        var messageId = _messageContext.Headers[Headers.MessageId];
        if (await _messageTracker.HasProcessed(messageId))
        {
            // REMEMBER TO SEND/PUBLISH ANY OUTGOING MESSAGES AGAIN
            // IN HERE!
            return;
        }
        // do the work here
        // ...
        // remember that this message has been processed
        await _messageTracker.MarkAsProcessed(messageId);
    }

其中，IMessageContext 是Rebus已有的，IMessageTracker必须自己实现。  
在[Abplus 0.1.6.1](https://github.com/personball/abplus)中已实现默认在内存中保存处理结果的MessageTracker。使用范例：

    private readonly IMessageContext MessageContext;
    ...
    [UnitOfWork]
    public async Task Handle(OrderPaidMqMessage message)
    {
        //幂等处理
        var msgId = MessageContext.Headers[Headers.MessageId];
        //processId标记哪个handler处理哪个消息，以区分各个handler自己是否已处理
        var processId = $"{GetType().FullName}.Handle<{message.GetType().FullName}>:{msgId}";
        if (await MessageTracker.HasProcessed(processId))//MessageTracker 由AbpMqHandlerBase提供
        {
            return;
        }

        //业务处理逻辑
        await HandleInternal(message);
        
        //幂等处理
        if (CurrentUnitOfWork != null)
        {
            //当前工作单元提交成功才算处理成功
            CurrentUnitOfWork.Completed += (s, e) => AsyncHelper.RunSync(() => MessageTracker.MarkAsProcessed(processId));
        }
        else
        {
            await MessageTracker.MarkAsProcessed(processId);
        }
    }


