---
layout: post
title: "IdentityServer4(OAuth2.0服务)折腾笔记"
description: "使用IdentityServer4部署基于OAuth2.0的OIDC(OpenID Connect)服务和Api认证授权服务"
category: OAuth2
tags: [OAuth2 IdentityServer4]
---
{% include JB/setup %}
  

_以下，称这个使用了IdentityServer4的OAuth2.0服务的项目称为Passport项目。_

# 组件说明（Nuget）

> Passport项目所需组件
>
>* 项目以Asp.net Core Identity项目模板初始化，集成IdentityServer4中间件；
>* 集成IdentityServer4.AspNetIdentity用于管理User体系；
>* 集成IdentityServer4.EntityFramework用于持久化OAuth2.0相关角色数据；
>* 集成[NLog.Web.AspNetCore](https://github.com/NLog/NLog.Web/wiki/Getting-started-with-ASP.NET-Core-(csproj---vs2017))用于输出日志；
>* 集成System.Security.Cryptography.Csp使用RSA进行Token签名；
>
> ApiResource（提供Api服务，注册到Passport中）所需组件
>
>* 如果是Asp.Net Core WebApi项目：集成IdentityServer4.AccessTokenValidation(使用Authorize Policy机制即可)；
>* 如果是Asp.Net WebApi项目：集成IdentityServer3.AccessTokenValidation（中间件）+Thinktecture.IdentityModel.WebApi.ScopeAuthorization（提供ScopeAuthorize）
>
> Client所需组件
>IdentityModel（提供TokenClient）
>
> *注意事项*：
>
>* 其一，ApiResource 无需配置ApiSecret（中间件会请求http://{passport-project-domain}/.well-known/openid-configuration/jwks获取RSA公钥验签）;  
>* 其二，Client端（调用方）必须设置密码（clientId,clientSecret,请求所需scopes）
>* 其三，*配置RSA的时候，千万不能忘记设置KeyId*，否则IdentityServer3.AccessTokenValidation获取jwks时kid为null将抛异常。建议KeyId和Rsa的Base64字符串一起存配置文件。[参考issue](https://github.com/IdentityServer/CrossVersionIntegrationTests/issues/1)
> 

# 搭建路线

1. [IdentityServer4官方文档:using-asp-net-core-identity](https://identityserver4.readthedocs.io/en/release/quickstarts/6_aspnet_identity.html#using-asp-net-core-identity)
1. [IdentityServer4官方文档:using-entityframework-core-for-configuration-data](https://identityserver4.readthedocs.io/en/release/quickstarts/8_entity_framework.html#using-entityframework-core-for-configuration-data)
1. （可选）UI方面可临时用[quickstart-ui](https://identityserver4.readthedocs.io/en/release/intro/packaging.html#quickstart-ui)
1. （可选）如果是IdentityServer3，还有[IdentityServer3.Admin](https://github.com/IdentityServer/IdentityServer3.Admin)和[IdentityServer3.Admin.EntityFramework](https://github.com/IdentityServer/IdentityServer3.Admin.EntityFramework)
1. Token签名及验签机制选择:RSA。[配置方法参考](http://www.cnblogs.com/skig/p/6079457.html)，再强调一遍[*千万不能忘记设置KeyId*](https://github.com/IdentityServer/CrossVersionIntegrationTests/issues/1)
1. ApiResource及Client的配置参考[IdentityServer3和4各组件兼容性测试项目](https://github.com/IdentityServer/CrossVersionIntegrationTests.git)
1. Asp.Net WebApi(非.Net Core项目)对Scope进行细粒度验证（落实到一个具体Api），使用*ScopeAuthorize*,安装Nuget组件[*源码参考*](https://github.com/IdentityModel/Thinktecture.IdentityModel/blob/master/source/WebApi.ScopeAuthorization/ScopeAuthorizeAttribute.cs)  
    `Install-Package Thinktecture.IdentityModel.WebApi.ScopeAuthorization` 

# Asp.Net Core项目部署笔记

1. 服务器安装[DotNetCore.1.0.4_1.1.1-WindowsHosting.exe](http://download.microsoft.com/download/3/8/1/381CBBF3-36DA-4983-BFF3-5881548A70BE/DotNetCore.1.0.4_1.1.1-WindowsHosting.exe)
1. 服务器管理员cmd执行 net stop was /y && net start w3svc
1. 新建站点
1. 站点应用程序池设为无托管代码（IIS仅作为反向代理和方便站点发布）
1. 启用web部署
1. 手动vs发布，选iis，webdeploy，执行连接字符串，指定迁移连接字符串
1. 如果遇到IIS Aspnet Core Module启动dotnet进程失败，web.config启用stdoutLogEnabled，并创建logs目录，查看错误信息

# 参考资源

* [理解OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)
* [IdentityServer4官方文档](https://identityserver4.readthedocs.io/en/release/)
* [IdentityServer3和4各组件兼容性测试项目](https://github.com/IdentityServer/CrossVersionIntegrationTests.git)
* [IdentityServer4.Samples](https://github.com/IdentityServer/IdentityServer4.Samples.git)
* [validating-scopes-in-asp-net-4-and-5](https://leastprivilege.com/2015/12/28/validating-scopes-in-asp-net-4-and-5/)
* [ASP.NET Core实现OAuth2.0的ResourceOwnerPassword和ClientCredentials模式](http://www.cnblogs.com/skig/p/6079457.html)
* [NLog.Web/wiki/Getting-started-with-ASP.NET-Core-(csproj---vs2017)](https://github.com/NLog/NLog.Web/wiki/Getting-started-with-ASP.NET-Core-(csproj---vs2017))
* [Host on Windows with IIS](https://docs.microsoft.com/en-us/aspnet/core/publishing/iis)
