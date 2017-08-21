---
layout: post
title: "Abp系列——如何使用Abp插件机制(注册权限、菜单、路由)"
description: "Abp系列——如何使用插件机制(注册权限、菜单、路由)，BuildManager，ControllerFactory。"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series) 

Abp的模块系统支持插件机制，可以在指定目录中放置模块程序集，然后应用程序启动时会扫码该目录，加载其中所有程序集中的模块。  

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
1. 启用后，登陆，点开`Roles`菜单，点开角色Admin的编辑弹窗，看权限的选项，确实增加了我们刚才在插件中定义的新权限！  

<img src="/assets/images/abp/abp_plugin_permission.png" alt="abp_plugin_permission" width="800px"/>

*如果你有Asp.Net Zero的代码（收费的），那么权限编辑功能是可以直接使用的，这里官网免费生成的项目仅包含了module-zero基础功能，UI部分并未实现权限编辑功能。*

### 注册菜单

和权限类似，菜单通过继承`NavigationProvider`，实现`SetNavigation`方法，并添加到`INavigationConfiguration.Providers`即可。

同上，插件可以实现自己的NavigationProvider，并注册。

*权限和菜单相对简单，接下来是重点。*  

*这次折腾插件机制最大的收获，是了解到了Asp.Net Mvc 5.2.3是如何自动注册Area路由和如何查找Controller和实例化Controller。*  

如果先参考了[ABP模块系统插件机制](https://aspnetboilerplate.com/Pages/Documents/Module-System#plugin-modules)，可能就没有针对Asp.Net Mvc 5.2.3 的深入探究了。  
所以接下来所说的，是我还不知道`[assembly: PreApplicationStartMethod(typeof(PreStarter), "Start")]`和`PlugInSources.AddToBuildManager()`时的事情。（只怪自己一开始没仔细查文档，没料到插件机制的文档是放在模块系统里的）  

### 注册路由和寻找Controller

todo AreaRegistration的自动注册机制
todo DefaultControllerFactory寻找Controller类型和实例化Controller类型的机制

### 利用PreApplicationStartMethod避免上述折腾

todo abp.web里解决插件中的Controller无法识别的方法

## 参考

[ABP模块系统插件机制](https://aspnetboilerplate.com/Pages/Documents/Module-System#plugin-modules)

## 本文源码下载

[Personball.Demo.7z]()
