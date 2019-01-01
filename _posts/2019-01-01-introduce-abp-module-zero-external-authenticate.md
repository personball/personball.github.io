---
layout: post
title: "ABP中module-zero快速集成微信用户认证"
description: "ABP中module-zero项目模板ExternalAuthenticate介绍，集成微信用户认证"
category: ABP
tags: ABP Wechat
---
{% include JB/setup %}

## 前言

当我们刚开始尝试ABP开发框架的时候，我们一般会下载它的项目模板，启动起来试试。  

当我们选择集成了module-zero（勾选包含用户登陆注册功能时）的单页应用项目模板的时候——这里有两个方法获取启动模板：  

1. 到[aspnetboilerplate.com](https://aspnetboilerplate.com/Templates)下载;  
1. 如果官网打开比较慢，也可以使用命令行工具`abplus init`在本地执行从github上拉取项目模板。具体使用方法参考前一篇[ABP中的AsyncCrudAppService介绍](/abp/2018/12/18/async-crud-app-service-in-abp)或者[Github.com/personball/Abp-CLI](https://github.com/personball/Abp-CLI)

以vue单页应用为例。  

安装dotnet core 全局工具`ABPTools`：  

     dotnet tool install -g AbpTools
    
初始化项目：  

    abplus init -t vue

*默认项目名AbpDemo*  

打开解决方案`aspnet-core/AbpDemo.sln`，按以下路径找到目标代码：  

    AbpDemo.Web.Core项目>Authentication文件夹>External文件夹

在这个目录里，ABP项目模板放置了`ExternalAuthenticate`机制相关的所有代码。  

而启动项目后，Swagger界面上`TokenAuth/ExternalAuthenticate`接口则是在同一个项目里的Controllers文件夹下的`TokenAuthController`。  

## 首先分析一下External文件夹里的代码的作用

External文件夹下有以下几个代码文件：  

* `ExternalAuthConfiguration`是一个配置类，我们自己拓展的Provider要注册到这里;  
* `ExternalAuthManager`统一对外提供服务；  
* `ExternalAuthProviderApiBase`一个Provider基类，方便扩展自己的ExternalAuthenticate；  
* `ExternalAuthUserInfo`封装用户的认证信息；
* `ExternalLoginProviderInfo`封装Provider要用到的认证信息，按Wechat来说，这里封装AppId和AppSecret；  
* `IExternalAuthConfiguration`配置类的接口；  
* `IExternalAuthManager`接口；  
* `IExternalAuthProviderApi`接口；  

除去后面的三个接口，我们集成微信用户认证只要用到`ExternalAuthProviderApiBase`和`ExternalAuthUserInfo`。  

只要定义一个自己的Provider并注册到`ExternalAuthConfiguration`就可以重用`ExternalAuthenticate`接口统一的流程。  

## 开始集成微信用户认证

1. 我们在`AbpDemo.Web.Core项目>Authentication文件夹>External文件夹`下新增`Wechat`文件夹；  
1. 在`Wechat`文件夹下新建`WechatAuthProviderApi`类（该类代码随后附上）；  
1. 在`Wechat`文件夹下新建`WechatAuthUserInfo`类用于对应微信返回的用户信息（该类代码随后附上）；
1. 在`AbpDemoWebCoreModule`中注册及配置（`AbpDemo.Web.Host`的appsettings.json要新增配置，下附）；    

只要上面四个步骤，就可以完成微信认证集成（调用微信认证接口，拿code换sessionKey和openID的代码不再赘述）。  

下面是提到的各部分代码：  

`WechatAuthProviderApi`继承`ExternalAuthProviderApiBase`：  

```csharp
public class WechatAuthProviderApi : ExternalAuthProviderApiBase
{
    public ILogger Logger { get; set; }

    public WechatAuthProviderApi()
    {
        Logger = NullLogger.Instance;
    }

    public override async Task<ExternalAuthUserInfo> GetUserInfo(string accessCode)
    {
        var client = HttpApiClient.Create<IWeChatApi>();

        var authResult = await client.AuthCodeAsync(ProviderInfo.ClientId, ProviderInfo.ClientSecret, accessCode);

        if (authResult.errcode == 0)
        {
            return new WechatAuthUserInfo
            {
                EmailAddress = $"{authResult.openid}@AbpDemo.com",
                Name = $"{authResult.openid}",
                Provider = ProviderInfo.Name,
                ProviderKey = authResult.openid,
                Surname = authResult.openid,
                SessionKey = authResult.session_key,
                OpenId = authResult.openid
            };
        }
        else
        {
            Logger.Error($"{GetType().FullName}:{authResult.errcode},{authResult.errmsg}");
            throw new AbpProjectNameBusinessException(ErrorCode.WechatAuthByCodeFailed);
        }
    }
}
```

`WechatAuthUserInfo`定义：  

```csharp
public class WechatAuthUserInfo : ExternalAuthUserInfo
{
    public string SessionKey { get; set; }
    
    public string OpenId { get; set; }
}
```

`AbpDemoWebCoreModule`中注册：  

```csharp
private void ConfigureTokenAuth()
{
    ...原有代码略

    //wechat login config
    if (_appConfiguration["Authentication:Wechat:IsEnabled"].ToLower() == bool.TrueString.ToLower())
    {
        IocManager.Register<IExternalAuthConfiguration, ExternalAuthConfiguration>();
        var externalAuthConfig = IocManager.Resolve<IExternalAuthConfiguration>();
        externalAuthConfig.Providers.Add(new ExternalLoginProviderInfo(
            "Wechat",
            _appConfiguration["Authentication:Wechat:AppId"],
            _appConfiguration["Authentication:Wechat:AppSecret"],
            typeof(WechatAuthProviderApi)));
    }
}
```

**其中Wechat这个ProviderName要和调用`TokenAuth/ExternalAuthenticate`接口时传递的值保持一致。**

appsettings.json 中新增相应配置：  

    "Authentication": {
        "JwtBearer": {
            ...原有JwtBearer配置略
        },
        "Wechat": {
        "IsEnabled": "false",//启用时改成true
        "AppId": "",
        "AppSecret": ""
        }
    }

这样，就实现了微信用户认证机制的集成。

## 基本完成，还有一点点

首先，上面展示的代码`var client = HttpApiClient.Create<IWeChatApi>();`没有包含IWeChatApi的实现（用了WebApiClient.JIT包）以及接口返回结果的定义。  

然后，我们集成微信用户认证的话，一般也需要同步用户的微信信息，会需要保存和更新sessionKey等。  
这就需要对`TokenAuth/ExternalAuthenticate`的流程稍微做一些处理。  

最后，在真正调用`TokenAuth/ExternalAuthenticate`的时候：  

* authProvider :填"Wechat"  
* providerKey :对应微信openId  
* providerAccessCode": 对应微信code  

这里如果providerKey不想填（比如我们想记录unionId，不想记录openId作为唯一标识，unionId一开始前端是拿不到明文的）。  
可以去掉传入Dto中的Required，然后去掉`TokenAuthController.GetExternalUserInfo`方法中对ProviderKey的验证逻辑。  

综上，完整参考代码可以通过以下命令拉取：  

    abplus init Abplus.ZeroDemo -T personball/abplus-zero-template -t vue

今天就到这里，谢谢阅读，新年快乐。
