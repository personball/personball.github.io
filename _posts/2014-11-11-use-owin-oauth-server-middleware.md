---
layout: post
title: "使用Owin中间件搭建OAuth2.0认证授权服务器"
description: "使用Owin中间件搭建OAuth2.0认证授权服务器，涉及Asp.Net Identity(Claims Based Authentication)、Owin、OAuth2.0"
category: web开发
tags: AspNetMvc Owin OAuth2.0 Asp.Net.Identity
---
{% include JB/setup %}


###前言
这里主要总结下本人最近半个月关于搭建OAuth2.0服务器工作的经验。至于为何需要OAuth2.0、为何是Owin、什么是Owin等问题，不再赘述。我假定读者是使用Asp.Net,并需要搭建OAuth2.0服务器,对于涉及的Asp.Net Identity(Claims Based Authentication)、Owin、OAuth2.0等知识点已有基本了解。若不了解，请先参考以下文章：

* [MVC5 - ASP.NET Identity登录原理 - Claims-based认证和OWIN](http://www.cnblogs.com/jesse2013/p/aspnet-identity-claims-based-authentication-and-owin.html)
* [下一代Asp.net开发规范OWIN（1）—— OWIN产生的背景以及简单介绍](http://www.cnblogs.com/JustRun1983/p/3955238.html)
* [理解OAuth 2.0](http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html)
* [rfc6749](http://tools.ietf.org/html/rfc6749)

###从何开始？
在对前言中所列的各知识点有初步了解之后，我们从何处下手呢？  
这里推荐一个demo：[OWIN OAuth 2.0 Authorization Server](https://code.msdn.microsoft.com/OWIN-OAuth-20-Authorization-ba2b8783)  
除了demo外，还推荐准备好[katanaproject的源代码](http://katanaproject.codeplex.com/)  

接下来，我们主要看这个demo

###Demo:Authorization Server
从OAuth2.0的rfc文档中，我们知道OAuth有多种授权模式，这里只关注授权码方式。  
首先来看Authorization Server项目，里面有三大块：

* Clients
* Authorization Server
* Resource Server

以[RFC6749](https://tools.ietf.org/html/rfc6749#section-1.2)图示：  
Clients分别对应各种授权方式的Client，这里我们只看对应授权码方式的AuthorizationCodeGrant项目；  
Authorization Server即提供OAuth服务的认证授权服务器；  
Resource Server即Client拿到AccessToken后携带AccessToken访问的资源服务器(这里仅简单提供一个/api/Me显示用户的Name)。  
另外需要注意Constants项目，里面设置了一些关键数据，包含接口地址以及Client的Id和Secret等。  

###Client:AuthorizationCodeGrant
AuthorizationCodeGrant项目使用了DotNetOpenAuth.OAuth2封装的一个WebServerClient类作为和Authorization Server通信的Client。  
（这里由于封装了底层的一些细节，致使不使用这个包和Authorization Server交互时可能会遇到几个坑，这个稍后再讲）  
这里主要看几个关键点：

1.运行项目后，出现页面，点击【Authorize】按钮，第一次重定向用户至 Authorization Server
    
    if (!string.IsNullOrEmpty(Request.Form.Get("submit.Authorize")))
    {
        var userAuthorization = _webServerClient.PrepareRequestUserAuthorization(new[] { "bio", "notes" });
        userAuthorization.Send(HttpContext);
        Response.End();
    }

这里 new[] { "bio", "notes" } 为需要申请的scopes，或者说是Resource Server的接口标识，或者说是接口权限。然后Send(HttpContext)即重定向。  

2.这里暂不论重定向用户至Authorization Server后的情况，假设用户在Authorization Server上完成了授权操作，那么Authorization Server会重定向用户至Client，在这里，具体的回调地址即之前点击【Authorize】按钮的页面，而url上带有一个一次性的code参数，用于Client再次从服务器端发起请求到Authorization Server以code交换AccessToken。关键代码如下：

    if (string.IsNullOrEmpty(accessToken))
    {
        var authorizationState = _webServerClient.ProcessUserAuthorization(Request);
        if (authorizationState != null)
        {
            ViewBag.AccessToken = authorizationState.AccessToken;
            ViewBag.RefreshToken = authorizationState.RefreshToken;
            ViewBag.Action = Request.Path;
        }
    }

我们发现这段代码在之前点击Authorize的时候也会触发，但是那时并没有code参数（缺少code时，可能_webServerClient.ProcessUserAuthorization(Request)并不会发起请求），所以拿不到AccessToken。  

3.拿到AccessToken后，剩下的就是调用api，CallApi，试一下，发现返回的就是刚才用户登陆Authorization Server所使用的用户名（Resource Server的具体细节稍后再讲）。  

4.至此，Client端的代码分析完毕（RefreshToken请自行尝试，自行领会）。没有复杂的内容，按RFC6749的设计，Client所需的就只有这些步骤。对于Client部分，唯一需要再次郑重提醒的是，一定不能把AccessToken泄露出去，比如不加密直接放在浏览器cookie中。  

###先易后难，接着看看Resource Server
我们先把Authorization Server放一放，接着看下Resource Server。  
Resource Server非常简单，App_Start中Startup.Auth配置中只有一句代码：  

    app.UseOAuthBearerAuthentication(new Microsoft.Owin.Security.OAuth.OAuthBearerAuthenticationOptions());

然后，唯一的控制器MeController也非常简单：  

    [Authorize]
    public class MeController : ApiController
    {
        public string Get()
        {
            return this.User.Identity.Name;
        }
    }

有效代码就这些，就实现了非用户授权下无法访问，授权了就能获取用户登陆用户名。（其实webconfig里还有一项关键配置，稍后再说）  

那么，Startup.Auth中的代码是什么意思呢？为什么Client访问api，而User.Identity.Name却是授权用户的登陆名而不是Client的登陆名呢？  

我们先看第一个问题，找 UseOAuthBearerAuthentication() 这个方法。具体怎么找就不废话了，我直接说明它的源代码位置在 Katana Project源码中的Security目录下的Microsoft.Owin.Security.OAuth项目。OAuthBearerAuthenticationExtensions.cs文件中就这么一个针对IAppBuilder的扩展方法。而这个扩展方法其实就是设置了一个OAuthBearerAuthenticationMiddleware，以针对AccessToken进行解析。解析的结果就类似于Client以授权用户的身份（即第二个问题，User.Identity.Name是授权用户的登陆名）访问了api接口，获取了属于该用户的信息数据。  

关于Resource Server，目前只需要知道这么多。  
（关于接口验证scopes、获取用户主键、AccessToken中添加自定义标记等，在看过Authorization Server后再进行说明）  


###Authorization Server
Authorization Server是本文的核心，也是最复杂的一部分。  

####Startup.Auth配置部分
首先来看Authorization Server项目的Startup.Auth.cs文件，关于OAuth2.0服务端的设置就在这里。  

    // Enable Application Sign In Cookie
    app.UseCookieAuthentication(new CookieAuthenticationOptions
    {
        AuthenticationType = "Application", //这里有个坑，先提醒下
        AuthenticationMode = AuthenticationMode.Passive,
        LoginPath = new PathString(Paths.LoginPath),
        LogoutPath = new PathString(Paths.LogoutPath),
    });

既然到这里了，先提醒下这个设置：AuthenticationType是用户登陆Authorization Server后的登陆凭证的标记名，简单理解为cookie的键名就行。为什么要先提醒下呢，因为这和OAuth/Authorize中检查用户当前是否已登陆有关系，有时候，这个值的默认设置可能是"ApplicationCookie"。  

好，正式看OAuthServer部分的设置：  

     // Setup Authorization Server
    app.UseOAuthAuthorizationServer(new OAuthAuthorizationServerOptions
    {
        AuthorizeEndpointPath = new PathString(Paths.AuthorizePath),
        TokenEndpointPath = new PathString(Paths.TokenPath),
        ApplicationCanDisplayErrors = true,
    #if DEBUG
        AllowInsecureHttp = true,  //重要！！这里的设置包含整个流程通信环境是否启用ssl
    #endif
        // Authorization server provider which controls the lifecycle of Authorization Server
        Provider = new OAuthAuthorizationServerProvider
        {
            OnValidateClientRedirectUri = ValidateClientRedirectUri,
            OnValidateClientAuthentication = ValidateClientAuthentication,
            OnGrantResourceOwnerCredentials = GrantResourceOwnerCredentials,
            OnGrantClientCredentials = GrantClientCredetails
        },

        // Authorization code provider which creates and receives authorization code
        AuthorizationCodeProvider = new AuthenticationTokenProvider
        {
            OnCreate = CreateAuthenticationCode,
            OnReceive = ReceiveAuthenticationCode,
        },

        // Refresh token provider which creates and receives referesh token
        RefreshTokenProvider = new AuthenticationTokenProvider
        {
            OnCreate = CreateRefreshToken,
            OnReceive = ReceiveRefreshToken,
        }
    });

#####我们一段段来看：

    ...
    AuthorizeEndpointPath = new PathString(Paths.AuthorizePath),
    TokenEndpointPath = new PathString(Paths.TokenPath),
    ...

设置了这两个EndpointPath，则无需重写OAuthAuthorizationServerProvider的MatchEndpoint方法（假如你继承了它，写了个自己的ServerProvider，否则也可以通过设置OnMatchEndpoint达到和重写相同的效果）。  
反过来说，如果你的EndpointPath比较复杂，比如前面可能因为国际化而携带culture信息，则可以通过override MatchEndpoint方法实现定制。  
但请记住，重写了MatchEndpoint（或设置了OnMatchEndpoint）后，我推荐注释掉这两行赋值语句。至于为什么，请看Katana Project源码中的Security目录下的Microsoft.Owin.Security.OAuth项目OAuthAuthorizationServerHandler.cs第38行至第46行代码。  
对了，如果项目使用了某些全局过滤器，请自行判断是否要避开这两个路径（AuthorizeEndpointPath是对应OAuth控制器中的Authorize方法，而TokenEndpointPath则是完全由这里配置的OAuthAuthorizationServer中间件接管的）。  

    ApplicationCanDisplayErrors = true, 
    #if DEBUG
        AllowInsecureHttp = true, //重要！！这里的设置包含整个流程通信环境是否启用ssl
    #endif

这里第一行不多说，字面意思理解下。  
**重要！！**AllowInsecureHttp设置整个通信环境是否启用ssl，**不仅是OAuth服务端，也包含Client端（当设置为false时，若登记的Client端重定向url未采用https，则不重定向，踩到这个坑的话，问题很难定位，亲身体会）**。

    // Authorization server provider which controls the lifecycle of Authorization Server
    Provider = new OAuthAuthorizationServerProvider
    {
        OnValidateClientRedirectUri = ValidateClientRedirectUri,
        OnValidateClientAuthentication = ValidateClientAuthentication,
        OnGrantResourceOwnerCredentials = GrantResourceOwnerCredentials,
        OnGrantClientCredentials = GrantClientCredetails
    }

这里是核心Provider，凡是On开头的，其实都是委托方法，中间件定义了OAuth2的一套流程，但是它把几个关键的事件以委托的方式暴露了出来。  

* OnValidateClientRedirectUri：验证Client的重定向Url，这个是为了安全,防钓鱼
* OnValidateClientAuthentication：验证Client的身份（ClientId以及ClientSecret）
* OnGrantResourceOwnerCredentials和OnGrantClientCredentials是这个demo中提供的另两种授权方式，不在本文讨论范围内。

具体的这些委托的作用，我们接着看对应的方法的代码：  

    //验证重定向url的
    private Task ValidateClientRedirectUri(OAuthValidateClientRedirectUriContext context)
    {
        if (context.ClientId == Clients.Client1.Id)
        {
            context.Validated(Clients.Client1.RedirectUrl);
        }
        else if (context.ClientId == Clients.Client2.Id)
        {
            context.Validated(Clients.Client2.RedirectUrl);
        }
        return Task.FromResult(0);
    }

这里context.ClientId是OAuth2处理流程上下文中获取的ClientId，而Clients.Client1.Id是前面说的Constants项目中预设的测试数据。如果我们有Client的注册机制，那么Clients.Client1.Id对应的Clients.Client1.RedirectUrl就可能是从数据库中读取的。而数据库中读取的RedirectUrl则可以直接作为字符串参数传给context.Validated(RedirectUrl)。这样，这部分逻辑就算结束了。  

    //验证Client身份
    private Task ValidateClientAuthentication(OAuthValidateClientAuthenticationContext context)
    {
        string clientId;
        string clientSecret;
        if (context.TryGetBasicCredentials(out clientId, out clientSecret) ||
            context.TryGetFormCredentials(out clientId, out clientSecret))
        {
            if (clientId == Clients.Client1.Id && clientSecret == Clients.Client1.Secret)
            {
                context.Validated();
            }
            else if (clientId == Clients.Client2.Id && clientSecret == Clients.Client2.Secret)
            {
                context.Validated();
            }
        }
        return Task.FromResult(0);
    }

和上面验证重定向URL类似，这里是验证Client身份的。但是特别要注意两个TryGet方法，这两个TryGet方法对应了OAuth2Server如何接收Client身份认证信息的方式（这个demo用了封装好的客户端，不会遇到这个问题，之前说的在不使用DotNetOpenAuth.OAuth2封装的一个WebServerClient类的情况下可能遇到的坑就是这个）。  

* TryGetBasicCredentials：是指Client可以按照Basic身份验证的规则提交ClientId和ClientSecret
* TryGetFormCredentials：是指Client可以把ClientId和ClientSecret放在Post请求的form表单中提交

那么什么时候需要Client提交ClientId和ClientSecret呢？是在前面说到的Client拿着一次性的code参数去OAuth服务器端交换AccessToken的时候。  
Basic身份认证，参考[RFC2617](http://tools.ietf.org/html/rfc2617#section-2)  
Basic简单说明下就是添加如下的一个Http Header：

    Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ== //这只是个例子

其中Basic后面部分是 ClientId:ClientSecret 形式的字符串进行Base64编码后的字符串，Authorization是Http Header 的键名，Basic至最后是该Header的值。  
Form这种只要注意两个键名是 client\_id 和 client\_secret 。  

     private readonly ConcurrentDictionary<string, string> _authenticationCodes =
            new ConcurrentDictionary<string, string>(StringComparer.Ordinal);

        private void CreateAuthenticationCode(AuthenticationTokenCreateContext context)
        {
            context.SetToken(Guid.NewGuid().ToString("n") + Guid.NewGuid().ToString("n"));
            _authenticationCodes[context.Token] = context.SerializeTicket();
        }

        private void ReceiveAuthenticationCode(AuthenticationTokenReceiveContext context)
        {
            string value;
            if (_authenticationCodes.TryRemove(context.Token, out value))
            {
                context.DeserializeTicket(value);
            }
        }

这里是对应之前说的用来交换AccessToken的code参数的生成和验证的，用ConcurrentDictionary是为了线程安全；_authenticationCodes.TryRemove就是之前一直重点强调的code是*一次性的*，验证一次后即删除了。  

    private void CreateRefreshToken(AuthenticationTokenCreateContext context)
    {
        context.SetToken(context.SerializeTicket());
    }

    private void ReceiveRefreshToken(AuthenticationTokenReceiveContext context)
    {
        context.DeserializeTicket(context.Token);
    }

这里处理RefreshToken的生成和接收，只是简单的调用Token的加密设置和解密的方法。

至此，Startup.Auth部分的基本结束，我们接下来看OAuth控制器部分。

####OAuth控制器
OAuthController中只有一个Action，即Authorize。  
Authorize方法并没有区分HttpGet或者HttpPost，主要原因可能是方法签名引起的(Action同名，除非参数不同，否则即使设置了HttpGet和HttpPost，编译器也会认为你定义了两个相同的Action，我们若是硬要拆开，可能会稍微麻烦点)。  

#####还是一段段来看

    if (Response.StatusCode != 200)
    {
        return View("AuthorizeError");
    }

这段说实话，到现在我还没搞懂为啥要判断下200，可能是考虑到owin中间件会提前处理点什么？去掉了也没见有什么异常，或者是我没注意。。。这段可有可无。。

    var authentication = HttpContext.GetOwinContext().Authentication;
    var ticket = authentication.AuthenticateAsync("Application").Result;
    var identity = ticket != null ? ticket.Identity : null;
    if (identity == null)
    {
        authentication.Challenge("Application");
        return new HttpUnauthorizedResult();
    }

这里就是判断授权用户是否已经登陆，这是很简单的逻辑，登陆部分可以和AspNet.Identity那套一起使用，而关键就是authentication.AuthenticateAsync("Application")中的“Application”，还记得么，就是之前说的那个cookie名：  

    ...
    AuthenticationType = "Application", //这里有个坑，先提醒下
    ...

这个里要匹配，否则用户登陆后，到OAuth控制器这里可能依然会认为是未登陆的。  
如果用户登陆，则这里的identity就会有值。  

     var scopes = (Request.QueryString.Get("scope") ?? "").Split(' ');

这句只是获取Client申请的scopes，或者说是权限（用空格分隔感觉有点奇怪，不知道是不是OAuth2.0里的标准）。  

    if (Request.HttpMethod == "POST")
    {
        if (!string.IsNullOrEmpty(Request.Form.Get("submit.Grant")))
        {
            identity = new ClaimsIdentity(identity.Claims, "Bearer", identity.NameClaimType, identity.RoleClaimType);
            foreach (var scope in scopes)
            {
                identity.AddClaim(new Claim("urn:oauth:scope", scope));
            }
            authentication.SignIn(identity);
        }
        if (!string.IsNullOrEmpty(Request.Form.Get("submit.Login")))
        {
            authentication.SignOut("Application");
            authentication.Challenge("Application");
            return new HttpUnauthorizedResult();
        }
    }

这里，submit.Grant分支就是处理授权的逻辑，其实就是很直观的向identity中添加Claims。那么Claims都去哪了？有什么用呢？  
这需要再回过头去看ResourceServer，以下是重点内容：

    其实Client访问ResourceServer的api接口的时候，除了AccessToken，不需要其他任何凭据。那么ResourceServer是怎么识别出用户登陆名的呢？关键就是claims-based identity 这套东西。其实所有的claims都加密存进了AccessToken中，而ResourceServer中的OAuthBearer中间件就是解密了AccessToken，获取了这些claims。这也是为什么之前强调AccessToken绝对不能泄露，对于ResourceServer来说，访问者拥有AccessToken，那么就是受信任的，颁发AccessToken的机构也是受信任的，所以对于AccessToken中加密的内容也是绝对相信的，所以，ResourceServer这边甚至不需要再去数据库验证访问者Client的身份。

这里提到，颁发AccessToken的机构也是受信任的，这是什么意思呢？我们看到AccessToken是加密过的，那么如何解密？关键在于AuthorizationServer项目和ResourceServer项目的web.config中配置了一致的*machineKey*。  
（题外话，有个在线machineKey生成器：[machineKey generator](http://aspnetresources.com/tools/machineKey)，这里也提一下，如果不喜欢配置machineKey，可以研究下如何重写AccessToken和RefreshToken的加密解密过程，这里不多说了，提示：OAuthAuthorizationServerOptions中有好几个以Format后缀的属性）  
上面说的machineKey即是系统默认的AccessToken和RefreshToken的加密解密的密钥。  

submit.Login分支就不多说了，意思就是用户换个账号登陆。

###写了这么多，基本分析已经结束，我们来看看还需要什么

首先，你需要一个自定义的Authorize属性，用于在ResourceServer中验证Scopes，这里要注意两点：

1. webapi的Authorize和mvc的Authorize不一样（起码截至MVC5，这还是两个东西，vnext到时再细究；
2. 如何从ResourceServer的User.Identity中挖出自定义的claims。

第一点，需要重写的方法不是AuthorizeCore（具体方法名忘了，不知道有没有写错），而是OnAuthorize（同上，有空VS里验证下再来改），且需要调用 base.OnAuthorize 。  
第二点，如下：  

    var claimsIdentity = User.Identity as ClaimsIdentity;
    claimsIdentity.Claims.Where (c => c.Type == "urn:oauth:scope").ToList();

然后，还有个ResourceServer常用的东西，就是用户信息的主键，一般可以从User.Identity.GetUserId()获取，不过这个方法是个扩展方法，需要using Microsoft.AspNet.Identity。至于为什么这里可以用呢？就是Claims里包含了用户信息的主键，不信可以调试下看看（注意观察添加claims那段代码，将登陆后原有的claims也累加进去了，这里就包含了用户登陆名Name和用户主键UserId）。

###实践才会真的进步
这次写的真不少，基本自己踩过的坑应该都写了吧，有空再回顾看下有没有遗漏的。今天就先到这里，over。

###追加
后续实践发现，由于使用了owin的中间件，ResourceServer依赖Microsoft.Owin.Host.SystemWeb，发布部署的时候不要遗漏该dll。





