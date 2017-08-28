---
layout: post
title: "Abp系列——业务异常与错误码设计及提示语的本地化"
description: "Abp系列——领域层代码设计:业务异常与错误码设计及异常提示语的本地化。"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

## 前言
ABP中有个异常`UserFriendlyException`经常被使用，但是它所在的命名空间是`Abp.UI`，总觉得和展现层联系过于紧密，在AppService中用也就罢了，在领域层中用它总觉得有点不合适。  
那么怎么定义业务异常？既要用起来舒服又能体现业务意义？

## 几点目标

1. 无需每个业务领域都定义各自的异常类，但使用时要有一定的可读性，能区分不同业务；
1. 要有错误码；
1. 每个错误码对应的提示语不能硬编码，最好能使用已有的本地化语言机制；
1. 要有日志级别，不同的业务异常应该可以设置不同的日志级别，无特殊要求，应默认Warn级别；

*以下代码从[本系列QuickStartA](/abp/2017/08/07/abp-quick-start-hello-world)中的Personball.Demo解决方案开始*

## 先从错误码入手

从上面的要求来看，错误码定义成枚举最合适不过：  

1. 每个枚举值，既可以表达成字符串，又可以表达成数字；
1. 枚举值字符串，在使用时可读性好，也可以直接作为本地化语言键值对中的键名；
1. 枚举值数字，直接对应AjaxResponse中Error部分的Code(int类型)；

我们打开Personball.Demo的解决方案，在`Personball.Demo.Core`项目的根目录中添加枚举定义`ErrorCode` ：  

    public enum ErrorCode : int
    {
        //用region提前分配错误编码给各个业务领域
        //防止团队成员开发时发生冲突
        #region 库存相关 100-110
        /// <summary>
        /// 库存不足
        /// </summary>
        InventoryNotEnough = 100,
        #endregion

        #region 购物车相关 200-299
        /// <summary>
        /// 购物车项不存在
        /// </summary>
        ShoppingCartItemNotExists = 200,

        /// <summary>
        /// 商品已下架
        /// </summary>
        ShoppingCartItemIsShelve = 201,

        /// <summary>
        /// 数量超出范围
        /// </summary>
        ShoppingCartItemQtyMoreThanRange = 202,
        #endregion

        #region 订单中心 600-649
        /// <summary>
        /// 订单项重复
        /// </summary>
        OrderItemDuplicate = 601,

        /// <summary>
        /// 订单优惠（折扣）项重复
        /// </summary>
        OrderDiscountDuplicate = 602,
        #endregion
    }

*针对错误码的定义，强烈建议使用英文单词描述该错误发生的原因，而不是仅仅表达一个结果或者现象。*  
*比如，【订单项重复】和【订单优惠项重复】比一个笼统的【订单创建失败】要好。*  
*英文单词可以尽可能长，如果觉得看不清楚，也可以采用下划线分隔。*  
*如果英文能力不足，就尽量在注释上描述清楚，注释在最后可以统一录入语言文件作为本地化提示语。*  

给几个例子：  

    /// <summary>
    /// 团队申请人或挑选的成员已创建过团队，不能重复创建
    /// </summary>
    PspOrganizationLeaderOrMembersAlreadyHasOrgs = 412,

    /// <summary>
    /// 非消费者等级的账号只能属于自己的团队！
    /// </summary>
    PspAccountCannotChangeOrganizationWhenLevelGreaterThanLevelOne = 414,

    /// <summary>
    /// 创建新团队时，只能包含Leader直接推荐的同级成员
    /// </summary>
    PspOrganizationCreateNewCanOnlyIncludeLeaderChildrenWhichInSameLevel = 417,

## 定义业务异常

现在我们已经有了ErrorCode，而且ErrorCode很好的表达了业务到底发生了什么，接着我们看看异常怎么定义。  
我们一开始定的几个目标，其实大部分已经被枚举化的ErrorCode结合本地化语言机制满足了，所以我们的业务异常肯定包含这个`ErrorCode`枚举：  

    public class DemoBusinessException : AbpException, IHasErrorCode, IHasLogSeverity
    {
        public DemoBusinessException(ErrorCode errorCode)
            : base(errorCode.ToString())
        {
            Code = (int)errorCode;
        }

        public DemoBusinessException(ErrorCode errorCode, string message)
            : base(message)
        {
            Code = (int)errorCode;
        }

        public DemoBusinessException(ErrorCode errorCode, Exception innerException)
            : base(errorCode.ToString(), innerException)
        {
            Code = (int)errorCode;
        }

        public DemoBusinessException(
            ErrorCode errorCode, string message, Exception innerException)
            : base(message, innerException)
        {
            Code = (int)errorCode;
        }

        public int Code { get; set; }
        public LogSeverity Severity { get; set; } = LogSeverity.Warn;
    }

1. 继承`AbpException`，其中`base(errorCode.ToString())`构造方法中的参数对应的是`AbpException`的`string message`，我们用枚举值ToString是为了之后方便处理提示语本地化。当然从重载提供的多个构造方法来看，也是支持覆盖这套机制的，可以直接写message。  
1. 继承`IHasErrorCode`，是为了告诉异常Handle代码，这个异常携带了错误码。  
1. 继承`IHasLogSeverity`，是为了告诉异常Handle代码，这个异常应该以哪个日志级别进行记录。  

这个业务异常的使用范例：

    //典型用法
    throw new DemoBusinessException(ErrorCode.InventoryNotEnough);
    //直接硬编码提示语
    throw new DemoBusinessException(ErrorCode.InventoryNotEnough, 
        $"{item.Name}库存不足！");
    //设置日志等级
    throw new DemoBusinessException(ErrorCode.InventoryNotEnough)
    {
        Severity = Abp.Logging.LogSeverity.Error
    };

## 最后，异常Handle代码

刚才提到的异常Handle代码，其实Abp提供了很好的扩展，就是`IExceptionToErrorInfoConverter`，先看看如何注册自定义实现：  
在`Personball.Demo.Web`项目，`App_Start`目录下的`DemoWebModule`中

    public override void PostInitialize()
    {
        var errorInfoBuilder = IocManager.Resolve<IErrorInfoBuilder>();
        errorInfoBuilder.AddExceptionConverter(
            IocManager.Resolve<CustomExceptionErrorInfoConverter>());
    }

其中`CustomExceptionErrorInfoConverter`，就是我们要自定义的类：  

    public class CustomExceptionErrorInfoConverter
        : IExceptionToErrorInfoConverter, ITransientDependency
    {
        private readonly ILocalizationManager _localizationManager;

        public IExceptionToErrorInfoConverter Next { set; private get; }

        public CustomExceptionErrorInfoConverter(ILocalizationManager localizationManager)
        {
            _localizationManager = localizationManager;
        }

        public ErrorInfo Convert(Exception exception)
        {
            while (exception is AggregateException && exception.InnerException != null)
            {
                exception = exception.InnerException;
            }

            if (exception is DemoBusinessException)
            {
                var ex = exception as DemoBusinessException;
                return new ErrorInfo(ex.Code, L(ex.Message));
            }

            if (exception is EntityNotFoundException)
            {
                return new ErrorInfo((int)ErrorCode.ItemNotExists, L(ErrorCode.ItemNotExists.ToString()));
            }

            if (exception is ArgumentException)
            {
                var argEx = exception as ArgumentException;
                var argMsg = exception.Message ?? L(ErrorCode.RequestParametersError.ToString());
                return new ErrorInfo((int)ErrorCode.RequestParametersError, argMsg, $"ParamName:{argEx.ParamName}");
            }

            return Next.Convert(exception);
        }

        private string L(string name)
        {
            try
            {
                return _localizationManager.GetString(DemoConsts.LocalizationSourceName, name);
            }
            catch (Exception)
            {
                return name;
            }
        }
    }



## 可以启动看看效果了

我们在登录处理逻辑上抛个业务异常看看效果。  
找到`Personball.Demo.Web`下的`AccountController`，添加一行如下：

    [HttpPost]
    [DisableAuditing]
    public async Task<JsonResult> Login(
        LoginViewModel loginModel, string returnUrl = "", string returnUrlHash = "")
    {
        //在此抛出业务异常
        throw new DemoBusinessException(ErrorCode.InventoryNotEnough);

        CheckModelState();

        //...略
    }

运行后，点击登陆，如图：  

<img src="/assets/images/abp/abp_errorcode.png" alt="abp_errorcode" width="600px"/>

看响应中的错误码，是100，提示语是`[Inventory not enough]`，因为忘了配置语言文件，所以这里没本地化。

打开`Personball.Demo.Core`下的目录`Localization\Source`，编辑`Demo-zh-CN.xml`，追加一行：  

    <text name="InventoryNotEnough" value="库存不足"/>

再运行之前的登陆看看，是不是变成中文了？

## 本文源码下载

[Personball.Demo.ErrorCode.7z](/assets/Personball.Demo.ErrorCode.7z)
