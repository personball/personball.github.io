---
layout: post
title: "Entity Framework 6 优化"
description: "Mvc + EF6 完整优化终极版"
category: ORM
tags: [EntityFramework6]
---
{% include JB/setup %}

好久没写博客了，终于憋出了一个大招，现在总结下。  
虽然文章题目是针对EF的，但涉及的内容不仅仅是EF。

###场景介绍
目前在做的一个项目，行业门户，项目部分站点按域名划分如下：

1. user.xxx.com:用户登陆注册
2. owner.xxx.com:个人用户后台
3. company.xxx.com:企业后台
4. manage.xxx.com:网站管理

其中user.xxx.com为个人用户及企业用户登陆入口，  
manage.xxx.com/login为网站管理后台登陆入口。  

四个项目都是mvc4+ef6+autofac+automapper。  

补充信息：  

* .net framework 4.0
* asp.net mvc4
* Entity Framework 6
* 服务器：阿里云ECS win2008 r2 双核 4G内存 IIS7.5

于是，用过ef的都知道，ef首次访问数据库的时候，耗费的时间很长。  
如果四个项目都是首次访问，那么个人用户首次登陆的时候，会经历两次ef首次访问（user站和owner站）。

暂不论项目本身是否有更好的架构方案，或者配合集群加一层进行可用性缓冲等。  
`本文的目标就是要尽可能的降低用户在上述情况下遇到的等待时间。`

`以下所有测试前提:`

1. 站点代码有添加优化手段的情况下，回收程序池，并重启站点；
2. 站点代码未变化的情况下，回收程序池，并重启站点。

###初始状态
`贴图不太方便，只给搜集的数据作为展示`  
无任何优化措施的初始状态，更新各站点后：

1. 首次打开user：5.47s （注意，此时未使用到EF，仅一个空的登陆表单）；
2. 登陆owner后台：user处理登陆过程（9.37s，涉及用EF访问数据库），owner响应（14.54s，首次访问站点耗时+EF访问数据库耗时，仅涉及用户验证，后台首页为空）；
3. 注销owner后台，回到user，登陆company后台，company后台响应（15.19s，首次访问站点耗时+EF访问数据库耗时，仅涉及企业验证，后台首页为空）；
4. 注销company后台，打开manage，manage响应并跳转到登陆页（2.96s，首次访问）；
5. 登陆manage，耗时（8.23s，处理登陆过程涉及EF）

简单归纳下就是：

	1. owner登陆体验到的延迟共计（5.47s + 9.37s + 14.54s）
	2. company登陆体验到的延迟共计（15.19s，要感谢登陆owner的时候已经”激活“了user以及user的EF）
	3. manage登陆体验到的延迟共计（2.96s + 8.23s）

###第一个问题，站点首次访问的耗时大约5秒

`这时候还没EF什么事，只是一个空的登陆表单`

首次访问，一般分两块：

1. 站点更新后重新加载程序文件；
2. iis程序池回收后也会需要重新加载（程序池默认是**按需**触发运行的，没人访问它就不启动了）

很多.net程序员会忽略这个问题。  
（这真的是许多年的无奈经验之谈，大多会说，**第一次访问本来就会很慢**。）  
或者通过脚本定时访问，以规避这个问题（不让用户遇到就行了）

这里我倒想真的试试解决这个问题。

###第一个问题的解决方案：Application Initialization

这是在iis8出来后才有的，iis8内置的功能，而对于iis7.5也提供了一个扩展以支持这个功能。

[Application Initialization Module for IIS 7.5](http://www.iis.net/downloads/microsoft/application-initialization)  

在页面接近底部的地方，找到适合自己架构的安装链接

* x86 for Windows 7
* x64 for Windows 7 or Windows Server 2008 R2

安装这个iis模块后，在iis界面中并没有模块图标和配置界面，还需要安装:  

[http://files.dotblogs.com.tw/jaigi/1306/2013619347830.zip](http://files.dotblogs.com.tw/jaigi/1306/2013619347830.zip)

具体配置方法见：  

[让IIS 7 如同IIS 8 第一次请求不变慢](http://www.cnblogs.com/chehaoj/p/3432100.html)

`如果仅配置程序池StartMode为AlwaysRunning还不放心的话，`  
`也可以同时针对站点开启preload和DoAppInitAfterRestart。`

配置好后，测试了下，效果十分不错。  
回收程序池后首次打开各站点，延迟都很低。  
其实这个模块的思路和定时从外部触发一个访问是一样的，只是，更好的地方在于，它本身在程序池回收重启的时候就完成了这件事，而不会让外部访问有机会遇到**首次访问**的情况。

好了，完成这一步，解开了多年心结，省了5秒！

###第二个优化点：EF Pre-Generated Mapping Views，大概节省4秒

这个优化点，一般仔细去EF的网站找找还是容易找到的。  
具体原因原理不说了，这里引用下博客园dudu大神的文章。  

[来，给Entity Framework热热身](http://www.cnblogs.com/dudu/p/entity-framework-warm-up.html)

搬一下代码：

>	
>	using (var dbcontext = new CnblogsDbContext())
>	{
>	    var objectContext = ((IObjectContextAdapter)dbcontext).ObjectContext;
>	    var mappingCollection = (StorageMappingItemCollection)objectContext
>	    	.MetadataWorkspace.GetItemCollection(DataSpace.CSSpace);
>	    mappingCollection.GenerateViews(new List<EdmSchemaError>());
>	}
>	//对程序中定义的所有DbContext逐一进行这个操作

我把它配置在每个站点的Application_Start中了，我的项目使用了Autofac和Repository+UnitOfWork模式，没有异常。

经过这一环节，又砍掉了剩下延迟中的50%时间，大概4秒多点。  
归纳下测试数据：(结合以上两种优化后的成果)

	1. owner登陆体验到的延迟共计（ <1s + 4.68 + 4.99）
	2. company登陆体验到的延迟共计（5.5，同样要感谢登陆owner的时候已经**激活**了user的EF）
	3. manage登陆体验到的延迟共计（4.23）

###第三个优化点（杀手锏）：使用Ngen创建EntityFramework的本地代码镜像（EF版本6以上）

EF的文档要认真看啊！这个真是不小心挖出来的解决方案，主要是被我看到了一句话：

	The .NET Framework supports the generation of native images for managed applications and libraries as a way to help applications start faster and also in some cases use less memory.

具体参考：[Improving Startup Performance with NGen (EF6 Onwards)](http://msdn.microsoft.com/en-us/data/dn582034)  

Ngen使用方法：

	安装命令：[path to ngen]/ngen.exe install "[path to dll]"
	查询命令：[path to ngen]/ngen.exe display System.Xaml /verbose|findstr "EntityFramework"
	卸载命令：[path to ngen]/ngen.exe uninstall "[DisplayName in System.Xaml]"

具体原理就不解释了。这里就记一下使用经验：

1. ngen 安装后，不用试图去寻找生成的.ni.dll文件在哪，这是系统本身起作用的，就相当于已经**安装**好了
2. 卸载时候用的标识名是查询命令中查到的包含版本信息和PublicToken的完整dll名
3. path to dll 没必要指向你部署的站点中的bin目录，你可以建个目录（比如系统盘根目录下建个NgenTargets目录），把目标dll拷出来放进去。
4. ngen安装后，站点中的dll文件不可以删除，还是保持原样，删掉会500的。这个作用机制是系统级别的，和站点没啥关系，而且一次ngen安装后，所有站点都能享受到这个提速。
5. EF的provider等相关dll也可以试试，这个我还没试。

这一步之后，归纳下测试数据：

	1. owner登陆体验到的延迟共计（45ms+1.02s+1.06s）
	2. company登陆体验到的延迟共计（1.42s，同样要感谢登陆owner的时候已经”激活“了user的EF）
	3. manage登陆体验到的延迟共计（925ms+197ms）

###哇咔咔，畅快！

###参考

[让IIS 7 如同IIS 8 第一次请求不变慢](http://www.cnblogs.com/chehaoj/p/3432100.html)
[Pre-Generated Mapping Views](http://msdn.microsoft.com/en-us/data/Dn469601.aspx)
[来，给Entity Framework热热身](http://www.cnblogs.com/dudu/p/entity-framework-warm-up.html)
[Performance Considerations for Entity Framework 4, 5, and 6](http://msdn.microsoft.com/en-us/data/hh949853.aspx#9)
[Improving Startup Performance with NGen (EF6 Onwards)](http://msdn.microsoft.com/en-us/data/dn582034)
