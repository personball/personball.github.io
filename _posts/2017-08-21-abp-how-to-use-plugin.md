---
layout: post
title: "Abp系列——如何使用Abp插件机制(注册权限、菜单、路由)"
description: "Abp系列——如何使用插件机制(注册权限、菜单、路由)，BuildManager，ControllerFactory。"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series) 

欢迎加入QQ群讨论：

1. ABP架构设计交流群(134710707，已满)
1. ABP架构设计交流群2(579765441，已满)
1. ABP架构设计交流群3(291304962)

Abp的模块系统支持插件机制，可以在指定目录中放置模块程序集，然后应用程序启动时会搜索该目录，加载其中所有程序集中的模块。  

## 如何使用这套机制进行功能插件化开发？

首先，插件程序集和应用程序是毫无关系的，应用程序不依赖这个程序集，所以我们要解决几个常见问题：

1. 插件中提供的功能需要权限认证，如何自动注册权限到使用了该插件的应用程序？
1. 插件中提供的功能在展现层中需要菜单导航，如何自动注册菜单项目？
1. 插件中提供的功能需要配置，如何让插件自已能进行简单的配置管理，而不用去改宿主的配置文件？
1. 插件中提供了新的Mvc Controller，当然也需要注册路由。

*以下代码从[本系列QuickStartA](/abp/2017/08/07/abp-quick-start-hello-world)中的Personball.Demo解决方案开始*

## 开始我们的第一个插件程序集的开发

### 首先启动QuickStartA中一切就绪的HelloWorld，并且登陆进去看看首页

<img src="/assets/images/abp/abp_demohome.png" alt="abp_demohome" width="800px"/>

一切正常！

### Step1 新建插件程序集

<img src="/assets/images/abp/abp_plugin_start.png" alt="abp_plugin_start" width="800px"/>

1. 在解决方案中新建目录`PlugIns`，新建程序集项目`Personball.PlugIns.PlugInZero`；
1. 修改默认命名空间，由于这是一个插件，我选择默认命名空间为`Personball.PlugIns`，将`PlugInZero`作为这个示例插件的名称；
1. 在程序包管理其控制台，选择默认项目`PlugIns\Personball.PlugIns.PlugInZero`，执行`Install-Package Abp.Web.Mvc -Version 2.3`(保证和宿主使用的Abp框架版本一致，可以减少很多不必要的麻烦，这里安装Abp.Web.Mvc是因为我们将在插件中实现一个MvcController)；
1. 在插件程序集中添加一个目录`PlugInZero`，移除默认的Class1.cs。

### Step2 注册权限

Abp中权限构建基本都是通过继承`AuthorizationProvider`，实现`SetPermissions`方法，并添加到`IAuthorizationConfiguration.Providers`。  
插件本身也是一个模块，只要实现自己的AuthorizationProvider，并注册进Providers即可。  
在`PlugInZero`目录中定义我们的插件模块`PlugInZeroModule`，代码如下:  
*因本博客样式原因，源代码排版容易乱，下文大段代码全部贴图，文末附最终代码压缩包供下载。*  

<img src="/assets/images/abp/abp_plugin_module.png" alt="abp_plugin_module" width="600px"/>

在`PlugInZero`目录下新建常量定义文件`PlugInZeroConsts`，代码如下:  

    namespace Personball.PlugIns.PlugInZero
    {
        public static class PlugInZeroConsts
        {
            public static class PermissionNames
            {
                public const string PlugIns = "Personball.PlugIns";
                public const string PlugInZero = "Personball.PlugIns.PlugInZero";
            }
        }
    }

在`PlugInZero`目录下新建目录`Authorization`，新建类`PlugInZeroAuthorizationProvider`，代码如下:  

<img src="/assets/images/abp/abp_plugin_auth_provider.png" alt="abp_plugin_auth_provider" width="600px"/>

再到插件模块`PlugInZeroModule`中注册上述权限：  

    public override void PreInitialize()
    {
        Configuration.Authorization.Providers
            .Add<PlugInZeroAuthorizationProvider>();
        //TODO 等会要用
    }

### Step3 等不及要先看看效果了，让我们启用Personball.Demo.Web的插件加载！

让我们打开`Personball.Demo.Web`项目的`Global.asax`文件，添加代码后如下：  

<img src="/assets/images/abp/abp_plugin_web_global.png" alt="abp_plugin_web_global" width="600px"/>

1. 为`Personball.Demo.Web`项目添加一个目录`PlugIns`;
1. 生成插件程序集，将插件项目bin\debug目录中的`Personball.PlugIns.PlugInZero.dll`和`Personball.PlugIns.PlugInZero.pdb`复制到`Personball.Demo.Web`的`PlugIns`目录下，启动`Personball.Demo.Web`!  
1. 启动后，登陆，点开`Roles`菜单，点开角色Admin的编辑弹窗，看权限的选项，确实增加了我们刚才在插件中定义的新权限！  

<img src="/assets/images/abp/abp_plugin_permission.png" alt="abp_plugin_permission" width="800px"/>

*如果你有Asp.Net Zero的代码（收费的），那么权限编辑功能是可以直接使用的，这里官网免费生成的项目仅包含了module-zero基础功能，UI部分并未实现权限编辑功能。*

### Step4 注册菜单

和权限类似，菜单通过继承`NavigationProvider`，实现`SetNavigation`方法，并添加到`INavigationConfiguration.Providers`。  
同上，插件可以实现自己的NavigationProvider，并注册。  

在`PlugInZero`目录下新建目录`Navigation`，新建类`PlugInZeroNavigationProvider`，代码如下:  

<img src="/assets/images/abp/abp_plugin_menu_code.png" alt="abp_plugin_menu_code" width="600px"/>

再到插件模块`PlugInZeroModule`中注册菜单：  

    public override void PreInitialize()
    {
        //注册权限
        Configuration.Authorization.Providers
            .Add<PlugInZeroAuthorizationProvider>();
        //注册菜单
        Configuration.Navigation.Providers
            .Add<Navigation.PlugInZeroNavigationProvider>();
    }

来看看效果（生成插件程序集，并复制替换到Web项目的PlugIns目录下）：  

<img src="/assets/images/abp/abp_plugin_menu.png" alt="abp_plugin_menu" width="200px"/>


*权限和菜单相对简单，接下来是重点。*  

### Step5 注册路由和寻找Controller

首先我们提供一个`PlugInZeroController`，简单起见，仅有一个返回字符串的Action。  
在`PlugInZero`目录下新建目录`Controller`，新建类`PlugInZeroController`，代码如下:  

    public class PlugInZeroController : AbpController
    {
        public PlugInZeroController()
        {
            LocalizationSourceName = "Abp";
        }

        public Task<string> Hello()
        {
            return Task.FromResult($"hello at {DateTime.Now}");
        }
    }

接着，我们注册下路由（在`PlugInZeroModule的PreInitialize`方法中）：  

    //注册权限
    Configuration.Authorization.Providers
        .Add<PlugInZeroAuthorizationProvider>();
    //注册菜单
    Configuration.Navigation.Providers
        .Add<Navigation.PlugInZeroNavigationProvider>();
    //注册路由
    RouteTable.Routes.MapRoute(
        "Plugins",
        url: "PlugIns/{controller}/{action}",
        defaults: new { controller = "Home", action = "Index" });

修改一下菜单项上的url，并指定链接的target(在`PlugInZeroNavigationProvider`中):  

    plugInRoot.AddItem(
            new MenuItemDefinition(
                "PlugInZero",
                new FixedLocalizableString("PlugInZero(插件)"),
                //指定Controller的url
                url: "PlugIns/PlugInZero/Hello",
                icon: "",
                target: "_blank"//新开一个窗口
                ));

更新插件程序集，启动，点击之前的插件菜单（如果遇到404，请参考下方*Tip01*）：  

<img src="/assets/images/abp/abp_plugin_mvc.png" alt="abp_plugin_mvc" width="400px"/>

### Step6 插件配置

OK，Last Question：如何提供插件单独的配置？  
思路是，从程序集的`App.config`入手！  
如果插件自身使用数据库，有个DbContext，怎么读取配置并让IoC构建DbContext时使用这个配置？  

右键插件项目，新增项目，选择应用程序配置文件，文件名自动就是App.config，添加！  
编辑App.config，如下：

    <?xml version="1.0" encoding="utf-8" ?>
    <configuration>
    <connectionStrings>
        <add name="PlugInZeroDB" connectionString="localhost" providerName="System.Data.SqlClient"/>
    </connectionStrings>
    <appSettings>
        <add key="PlugInZeroSettingKey" value="Wahoo, wahoo"/>
    </appSettings>
    </configuration>

改下`PlugInZeroController`的代码尝试读取`PlugInZeroSettingKey`并输出：

    public Task<string> Hello()
    {
        var config = ConfigurationManager.OpenExeConfiguration(
            Assembly.GetExecutingAssembly().Location);
        var value = config.AppSettings
            .Settings["PlugInZeroSettingKey"].Value;
        return Task.FromResult($"hello at {DateTime.Now}  {value}");
    }

重新生成插件程序集，并复制`三个文件（含Personball.PlugIns.PlugInZero.dll.config）`到PlugIns目录中，启动：  

<img src="/assets/images/abp/abp_plugin_config.png" alt="abp_plugin_config" width="400px"/>

读取数据库连接字符串，并让指定的DbContext(插件自己的)使用该配置，这里仅给出示例代码，并不实际运行演示。

    //插件配置(直接从当前执行的程序集的config文件读取数据库连接串)
    var config = ConfigurationManager.OpenExeConfiguration(
        Assembly.GetExecutingAssembly().Location);
    string connectStr = config.ConnectionStrings.ConnectionStrings["PlugInZeroDB"].ConnectionString;
    //注册DbContext,构建时使用指定参数
    IocManager.IocContainer.Register(
        Component.For<PlugInZeroDbContext>()
        .DependsOn(
            Dependency.OnValue(
                "connectionString", connectStr)));

### Tip01

*注意！注意！注意！*  
*BuildManager对于ControllerType有缓存，在服务器上仅仅加载插件，注册路由，可能还是会遇到404（找不到Controller）。*  
*这种时候必须改动对于iis敏感的几个路径（bin目录）或Web.config文件，BuildManager才会更新ControllerType的缓存（这是个文件缓存！），将插件内的Controller类型也算进去。*  
这里虽然只有寥寥数语，却是各种心酸血泪之后的总结，期间甚至自己扩展过一个ControllerFactory，那也是一套可行的方案，不赘述了。

搜了一个`MVC-ControllerTypeCache.xml`，内容如下（这里并未包含插件中的PlugInZeroController）：

    <?xml version="1.0" encoding="utf-8"?>
    <!--This file is automatically generated. Please do not modify the contents of this file.-->
    <typeCache lastModified="8/22/2017 12:00:44 AM" mvcVersionId="cc73190b-ab9d-435c-8315-10ff295c572a">
    <assembly name="Personball.Demo.Web, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null">
        <module versionId="9c27c37d-a073-42aa-b339-b5887549b123">
        <type>Personball.Demo.Web.Controllers.AboutController</type>
        <type>Personball.Demo.Web.Controllers.AccountController</type>
        <type>Personball.Demo.Web.Controllers.HomeController</type>
        <type>Personball.Demo.Web.Controllers.RolesController</type>
        <type>Personball.Demo.Web.Controllers.TenantsController</type>
        <type>Personball.Demo.Web.Controllers.UsersController</type>
        <type>Personball.Demo.Web.Controllers.LayoutController</type>
        </module>
    </assembly>
    <assembly name="Abp.Web.Mvc, Version=2.3.0.0, Culture=neutral, PublicKeyToken=null">
        <module versionId="6bcf306f-dc82-4ad6-99be-7efe88288f89">
        <type>Abp.Web.Mvc.Controllers.AbpAppViewController</type>
        <type>Abp.Web.Mvc.Controllers.AbpScriptsController</type>
        <type>Abp.Web.Mvc.Controllers.AbpUserConfigurationController</type>
        <type>Abp.Web.Mvc.Controllers.Localization.AbpLocalizationController</type>
        </module>
    </assembly>
    </typeCache>

### Tip02

*插件的dll文件替换时遇到进程锁定问题*  
请先停止iis站点或者应用程序池，替换插件dll后再启动

*如果配置了CI，比如tfs使用webdeploy发布*  
务必请在发布时指定webdeploy的选项，忽略插件目录`-skip:Directory="PlugIns"`。  
插件一般考虑手动更新（大多是非核心的功能，变更极少），如果CI每次都要考虑重新build插件并更新，就得不偿失了。  
假如非要CI每次更新插件程序集，那就需要先用webdeploy停止目标站点的应用程序池，发完后再启动应用程序池。  
详情请参见下方参考条目：*Operations on application pools as admin and non-admin*

## 参考

[ABP模块系统插件机制](https://aspnetboilerplate.com/Pages/Documents/Module-System#plugin-modules)  

[Taming the BuildManager, ASP.Net Temp files and AppDomain restarts](https://shazwazza.com/post/taming-the-buildmanager-aspnet-temp-files-and-appdomain-restarts/)  

[Operations on application pools as admin and non-admin](https://blogs.iis.net/msdeploy/operations-on-application-pools-as-admin-and-non-admin)  

## 本文源码下载

[Personball.Demo.7z](/assets/Personball.Demo.7z)
