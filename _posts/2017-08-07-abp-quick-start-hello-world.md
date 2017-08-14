---
layout: post
title: "ABP系列——QuickStartA:概述、思想、入门和HelloWorld"
description: "ABP系列——QuickStartA:概述、思想、入门和HelloWorld。Abp最适合复杂的业务系统，以及天然针对SaaS的架构支持。"
category: ABP
tags: [abp]
---
{% include JB/setup %}

唔，说好的文章，欠了好久，先水一篇。

# 概述
先表个态：对绝大多数人来说，ABP是成熟的，足以用到生产环境的。  

* 最适合的：业务非常复杂且不追求极致性能的（这里并不是说ABP性能不行），或业务非常成熟稳定直接作为产品（卖软件）或服务（SaaS）进行销售的。  
* 最不适合的：极致追求性能，言必谈性能，不谈业务的。  

这里适合和不适合，主要是说投入产出比（不适合的那群人本身就在抗拒着，忙着挑刺）。

当我们遇到需要极致的性能需求的时候，其实重点在于方案如何设计，开发框架和开发语言理应为了性能让步，做出一定取舍，这种时候，ABP的众多特性，其实是被浪费了，所以并不是一个适合的场景。

但是更多时候，我们求的是快速开发，而快速开发（不仅仅是`快`，还要`好`）离不开几个特点：

1. 先进的建模思想；
1. 丰富的基础设施；
1. 开箱即用的基础功能；

上面第二点和第三点ABP有非常强大的优势。而第一点其实是指如何Hold住多变的业务逻辑，以及如何写出可维护性、可扩展性强的代码，主要是看写代码的人本身的功底。而ABP的源码又恰好在这方面有非常优秀的示范作用。

就我们团队的经验来说，从2015年，Abp版本0.7左右开始使用，期间还有一些不成熟的摸索，到今年上半年使用1.4.2以及1.5.0已经基本游刃有余，在三个月时间内开发完公司的两大系统（供应链管理系统和电商平台）。效率之高，也是我从业以来非常罕见的，当然其中团队的磨合也很重要，但Abp在其中起到的作用是非常巨大的。

PS：_为啥是1.4.2和1.5.0？今年上半年Abp作者升级太快了，跟不上啊！又怕引入.net core会造成未知风险（后来证明确实如此），就没继续升级跟进了。但是本系列会以当前最新的Abp版本v2.3（本来想说v2.2.2的，结果去看了下，果然又升到v2.3了，所以这是一个非常活跃的项目，别怕没人维护！）作为演示基准。_

# ABP思想

1. 基于DDD（领域驱动设计）思想的分层架构；
2. 模块化设计；
3. 多租户，SaaS架构支持；
4. 坚持SOLID，DRY等原则的最佳实践；
5. UOW（UnitOfWork，工作单元），EventBus，业务逻辑解耦利器；
6. IoC，依赖注入，本地化语言，泛型仓储，AOP，应用服务直接映射WebApi，聚合根，值对象，等等等等...

借用官网的图：

<img src="https://github.com/aspnetboilerplate/aspnetboilerplate/raw/dev/doc/img/abp-concerns.png" alt="abp-concerns" width="800px" />

Don't repeat yourself! 框架替你做重复的事，你只需集中精力处理业务逻辑！和`IRepository.Update(entity)`说再见，`SaveChange`以后也只会偶尔露面了。

# ABP入门

感谢将ABP介绍到中文社区的朋友们，这段主要是传送门： 

1. [阳铭的博客](http://www.cnblogs.com/mienreal/p/4528470.html)   
2. [ABP框架理论研究总结（较新）](http://www.cnblogs.com/farb/p/ABPTheory.html)

建议想粗略看个大概的朋友可以先看看阳铭的博客，想认真入坑的，可以看tkb的《ABP框架理论研究总结》。  

_这里把阳铭的博客列在前面是有些私心的,本人到上海工作的原因就是入了abp的坑，并且有幸进入阳铭的团队直到现在，所以领导的博客要靠前点。_

# HelloWorld, Step By Step，先跑起来

### Step 1 快速构建解决方案
点击链接>>[Abp官网解决方案自动生成工具](https://aspnetboilerplate.com/Templates)。  
如图，我们选择`Asp.Net Mvc 5.x`项目，`多页Web应用`，`包含module-zero`，并且输入解决方案名称(同时是根命名空间)`Personball.Demo`：  

<img src="/assets/images/abp/sln_generator.png" alt="sln generator" width="800px" />

点击*生成项目*

等待下载完成。解压后，得到解决方案：

<img src="/assets/images/abp/sln_demo.png" alt="sln_demo" width="800px"/>

### Step 2 初始化数据库

<img src="/assets/images/abp/sln_demo2.png" alt="sln_demo2" width="800px">

1. 右键点击`Personball.Demo.Web`作为启动项目;
1. 修改`Web.config`数据库连接字符串，连接到可用的数据库实例（需要建立一个空数据库`Personball_Demo`）;
1. 打开`程序包管理器控制台`，选择`Personball.Demo.Entityframework`作为当前项目;
1. 执行`Update-Database`;

### Step 3 启动
最后，F5启动，ok，一切正常！

<img src="/assets/images/abp/sln_demo3.png" alt="sln_demo3" width="800px">

还可以立即体验到多语言机制哦！  
*PS 默认账户是admin，密码123qwe*

### Step 4 Git Init，一切就绪

在程序包管理器控制台，运行如下命令获取vs版gitignore文件

    (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/github/gitignore/master/VisualStudio.gitignore","$pwd\.gitignore")

然后执行git初始化命令，添加所有文件，提交。

    git init
    git add .
    git commit -am 'Init'

Ok,一切就绪，赶快去了解业务需求吧！

# 这篇水完了，后面会有干货的。

欢迎加入QQ群讨论：

1. ABP架构设计交流群(134710707)
2. ABP架构设计交流群2(579765441)
