---
layout: post
title: "ABP系列——QuickStartB:正确理解Abp解决方案的代码组织方式、分层和命名空间"
description: "ABP系列——QuickStartB:正确理解Abp解决方案的代码组织方式、分层和命名空间，N层结构，DDD以及命名空间的秘密。"
category: ABP
tags: [abp]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series) 

欢迎加入QQ群讨论：

1. ABP架构设计交流群(134710707，已满)
1. ABP架构设计交流群2(579765441，已满)
1. ABP架构设计交流群3(291304962)

介绍ABP的文章，大多会提到ABP框架吸收了很多最佳实践，比如：

## 1.N层
（复用一下上篇的图）

<img src="/assets/images/abp/sln_demo.png" alt="sln_demo" width="800px"/>

* 展现层(Personball.Demo.Web)：asp.net mvc只是其展现层，abp同时支持宿主为控制台程序、win服务或桌面程序WPF（wpf我不熟，理论上支持）  
* 应用服务层(Personball.Demo.Application)：对外提供功能的大粒度层次，参考门面模式（Facade Pattern）(*另一种理解：应用服务是按用例组织代码提供功能*)  
* 领域层(Personball.Demo.Core)：业务逻辑的核心实现（有ORM、Uow的支持，这里实际上是发挥各种设计模式的地方）  
* 基础设施层(Personball.Demo.EntityFramework)：主要是提供领域层中仓储接口的实现  

先指出一个问题：

*基础设施层(Personball.Demo.EntityFramework)*  

由于这个项目过度偏向具体ORM的实现，其实称为基础设施层并不合适，这会导致开发过程中真正需要对通用功能进行实现时（接口可以定义在Core程序集中），开发者往往不知道通用功能的实现到底应该放在哪比较好。  

所以，个人觉得需要增加一个真正的基础设施层项目，例如`Personball.Demo.Infrastructure`项目，且其模块应依赖于`Personball.Demo.EntityFramework中的DemoDataModule`

## 2.模块化

然后，除了表面上看得到的分层(程序集水平划分)，ABP也是模块化的，上述每个程序集其中都含有至少一个模块：  

* 展现层(Personball.Demo.Web):`DemoWebModule`
* 应用服务层(Personball.Demo.Application):`DemoApplicationModule`
* 领域层(Personball.Demo.Core):`DemoCoreModule`
* 基础设施层(Personball.Demo.EntityFramework):`DemoDataModule`
* Personball.Demo.WebApi:`DemoWebApiModule`（此模块负责提供WebApi接口，可看做是展现层的扩展）

*模块存在的意义是什么？*  
Abp的模块定义了一套启动时的初始化流程，为配置、IoC注册等行为提供恰当的时机，理解模块各个Init方法的执行顺序非常重要。  
上述各模块各自配置了依赖关系，例如：  

    [DependsOn(typeof(AbpZeroCoreModule))]//可以依赖其他模块组件（通过nuget包分发）
    public class DemoCoreModule : AbpModule
    {
        ...//略
    }

    [DependsOn(typeof(DemoCoreModule) //也可以依赖本解决方案中现有的模块
        , typeof(AbpAutoMapperModule))]
    public class DemoApplicationModule : AbpModule
    {
        ...//略
    }

借助IOC容器进行解耦。

## 3.除了程序集、模块这种划分方式，还有一个经常被忽略的问题——命名空间

这是本篇的最主要目的（单独列个QuickStartB的原因），虽然很多经验丰富的开发人员可能早已轻车熟路，在此我还是要重点讲一下。

我们首先看各个程序集的`默认命名空间`，很多新手可能根本不会关注这个事情，`右键程序集->属性->应用程序`。  
列一下上述各个项目的默认命名空间：  

* 展现层(Personball.Demo.Web):`Personball.Demo.Web`
* 应用服务层(Personball.Demo.Application):`Personball.Demo`
* 领域层(Personball.Demo.Core):`Personball.Demo`
* 基础设施层(Personball.Demo.EntityFramework):`Personball.Demo`
* Personball.Demo.WebApi:`Personball.Demo`

_请注意!!_：除了作为Abp框架宿主的Web项目，所有lib类型的程序集，其默认命名空间都是我们创建解决方案时输入的`Personball.Demo`。  

那么为什么另外四个程序集不是和Web项目一样，默认命名空间和程序集名称一致呢？  

我们来看上面提到的各个模块其代码文件在程序集中的位置：

* `DemoWebModule`       //App_Start目录下，所处命名空间为`Personball.Demo.Web`
* `DemoApplicationModule`//项目根目录下，所处命名空间为`Personball.Demo`
* `DemoCoreModule`//项目根目录下，所处命名空间为`Personball.Demo`
* `DemoDataModule`//项目根目录下，所处命名空间为`Personball.Demo`
* `DemoWebApiModule` //Api目录下，所处命名空间为`Personball.Demo.Api`

_请注意!!_:除了DemoWebModule，其他模块所处目录结构和命名空间完全一致。  
_请注意!!_:DemoWebModule引用其他模块（除DemoWebApiModule以外）时，由于三个模块都处于根命名空间下，对DemoWebModule来说是直接可见的。

所以，命名空间类似树形目录：

    越是在上级空间中的对象，越具有可共享倾向（暂不考虑其他保护级别），越是往下级目录靠，其实就是越特殊
    
如果说，
    
    程序集是水分划分代码（划分层次，程序集名称的最后一段代表其所在层次）

那么，
    
    命名空间是垂直划分代码（划分概念，命名空间Personball.Demo.abc中的abc代表这部分代码所专注的领域和概念或者说是提供哪方面的功能）

这是正交的关系。  

为了提供功能，必然需要跨越多个层次，在每个层次中都保证同样的目录结构（vs新建类或接口的所处命名空间），那么

    同一个领域或概念在不同层次中是天然可见的，不需要特地用using语句引入命名空间

命名空间和程序集的组织方式，当然不是Abp特有的，这是C#的基础，但是感觉很多人没被点破。

### 3.2如果上面的描述还是不好理解，那么举个反例：

假如程序集`Personball.Demo.Core`的默认命名空间也是*Personball.Demo.Core*。  
（这个Core命名空间语义上也并未体现什么技术或者业务概念，不是一个好的实践）。  

当我想定义一个其他地方都能公用的常量或枚举或异常时，假设是个枚举ErrorCode，我在*Personball.Demo.Core程序集*根目录下加了这个文件，内容如  

    namespace Personball.Demo.Core
    {
        public enum ErrorCode
        {
            None = 0
        }
    }

*namespace改不改？*

* 如果不改，那么意味着所有引用到ErrorCode的地方，我都需要写`using Personball.Demo.Core;`
* 如果改，改成`namespace Personball.Demo`，那么不仅是这个文件，以后在这个程序集增加的所有文件，特别是子目录中的，`每次都要改`。

其他程序集同理。


所以，类库程序集，为了更和谐的组织代码，方便自己，也同时为了语义表达，请多关注默认命名空间。只改开始的这一次，一切都会方便很多。  

顺带提下，针对Abp做非侵入式扩展的组件Abplus，其默认命名空间是Abp，目录结构和Abp保持一致。  
这样，我向Abp框架提交PR时，大部分代码都不用改命名空间，甚至目录结构也不用动，直接在fork的abp分支上把abplus的代码复制过来即可使用。

差不多了，洗洗睡了。

