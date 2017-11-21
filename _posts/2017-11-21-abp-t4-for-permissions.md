---
layout: post
title: "Abp系列——T4应用:权限树定义"
description: "Abp系列——T4应用:权限树定义，Abplus.T4.PermissionsFromJson"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

今天介绍下，如何使用T4根据json文件自动生成权限定义。

## 先看成果

成果是：  

1. 要新增一个权限定义时，打开Json文件，找到目标节点，加个权限定义；  
1. 生成下Core程序集（因为Json文件都是嵌入式资源文件）；  
1. 跑一遍T4，ok，新增的权限名常量有了，权限树上也加了新权限。  

截图：  

<img src="/assets/images/abp/abp_t4_perms.png" alt="abp_t4_perms" width="600px"/>

## 开工

还是从`Personball.Demo`项目开始，我从`dev`分支新建了一个`feature_t4_permissions`。  
展开`Personball.Demo.Core`程序集，按下述步骤操作

### 安装包，获取相关文件

打开*程序包管理器控制台*，默认项目选中`Personball.Demo.Core`，执行如下命令，安装获取相关文件：  

    //安装过程中会提示是否执行T4，请取消，还有地方需要修改    
    Install-Package Abplus.T4.PermissionsFromJson

该nuget包带来如下几个文件：  

1. Authorization\Builders\Permissions\Sample.json  
1. Authorization\Builders\BuilderUtils.cs  
1. Authorization\Builders\PermissionBuilder.tt  
1. Authorization\Builders\T4MultipleOutputManager.ttinclude  

### 几处修正

1. 选中`Sample.json`，F4查看属性，确保json文件的属性是*嵌入的资源*  
1. 打开`BuilderUtils.cs`，将`【YourCompany.YourProject】`替换成`Personball.Demo`  
1. 打开`PermissionBuilder.tt`，将`【YourCompany.YourProject】`替换成`Personball.Demo`  
1. 打开`PermissionBuilder.tt`，修正你所使用的`Newtonsoft.Json`的引用路径（版本号）  
1. 打开`Authorization\DemoAuthorizationProvider.cs`，在`SetPermissions`方法中追加一行代码`BuilderUtils.Build(context, "Sample");`

其中`SetPermissions`方法中，可以注释掉原先的`context.CreatePermission`调用，然后针对每个权限定义json文件，增加代码：  

    //【Json文件名】替换，如Sample，无文件名后缀
    BuilderUtils.Build(context, "【Json文件名】");

*如果需要json文件的具体字段定义，请参考`BuilderUtils.cs`文件中`PermissionJson`类的定义。*

### Run

生成Core程序集，然后运行`PermissionBuilder.tt`（右键点击tt文件，*运行自定义工具*）

### 清理

待所有`AbpAuthorizeAttribute`中用到的权限字符串常量（如标在`TenantAppService`上的`[AbpAuthorize(PermissionNames.Pages_Tenants)]`）都替换成T4自动生成的以后，就可以删除`Authorization`目录下的`PermissionNames.cs`了。  

同时可以清理`DemoAuthorizationProvider`中`SetPermissions`方法中原有的代码，统一全部调用`BuilderUtils.Build`。  

### 感谢

感谢曾经的同事 @菜刀和板砖 提供本文关键实现。

