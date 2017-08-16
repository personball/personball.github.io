---
layout: post
title: "一则使用WinDbg工具调试iis进程调查内存占用过高的案例"
description: "一则使用WinDbg工具调试iis进程调查内存占用过高的案例"
category: WinDbg
tags: [WinDbg]
---
{% include JB/setup %}

最近遇到一个奇葩内存问题，跟了三四天，把Windbg玩熟了，所以打算分享下。

## 症状简介

我们团队的DEV开发环境只有一台4核16G的win2012r2。  
这台服务器上装了SqlServer、TFS（项目管理、远程Git库、CI、生成代理）、两个系统的整套DEV环境（六七个iis站点和八九个win服务），  
还有其他一些辅助服务什么的，总之负担相对较重，内存占用经常10个G以上。

现象是经常报内存不足（平常明明还剩余至少5个G的内存）。  
然后我们发现有个iis站点不对劲，是一个为电商平台后台管理系统提供api接口的项目（我们的项目基本是前后端完全分离的，这个PortalApiHost为所有后台功能提供支持）。  
这个站点经常占用非常高的内存，2G，3G，甚至这次发现最高达到5G，难道是开发框架有问题？或者是业务代码哪里有严重的内存泄露？或者以前遇到过的某个Linq坑错用了IEnumerable<T> 接口，把大量DB数据拉到内存里了？

多次试验后，基本排除上面提到的可能性。  
因为这货内存占用较高时，我们发现所有功能一切正常。所有后台功能操作了一遍，接口响应速度非常快。日志也没记录什么相关错误，没异常，审计日志显示的执行时间也很正常。  

一切都很正常，就是内存占用高！怎么破？！

>从8月4日到8月8日，DEV服务器上进程号为15832的Ecom站点进程，经历了内存用量从启动到最高占用2个G（8月7日下班时），又回落到1.6G（8月8日早上），后继续回落到1.3G。  
>
>证明GC正常，且无内存泄露问题。  
>
>8月8日下午17:30左右再次查看15832，内存占用达到5G，无论如何都是有问题的了,需要继续跟进。

## Windbg搞起来

为了查明这个奇葩的高内存问题，我们尝试了各种工具，这里主要讲下WinDbg

<img src="/assets/images/windbg/windbg_pic.png" alt="windbg01" width="300px" />

1. [下载winsdksetup.exe](https://download.microsoft.com/download/E/1/B/E1B0E6C0-2FA2-4A1B-B322-714A5586BE63/windowssdk/winsdksetup.exe)
1. 安装，只选择`Debugging Tools for Windows`
1. 配置环境变量，符号表路径` _NT_SYMBOL_PATH = symsrv * symsrv.dll * d:\symbols * http://msdl.microsoft.com/download/symbols`
1. 以管理员身份启动windbg，附加进程（如果提示调试器只能有一个，很有可能这个进程是从VS启动的，可以在VS那边换成不调试启动），直接输入进程号（PID）
1. 也可以离线化，先创建iis进程转储文件w3wp.dmp(任务管理器中右键目标进程即可看到，注意完成后复制转储文件的路径)，再用windbg `Open Crash Dump File`
1. 先用 `.loadby sos clr` 加载调试DotNet必须的dll。(如果是.net framework 2.0及以前的程序，将clr换成mscorwks)
1. `.loadby sos clr` 不好用的话，也可以`.load C:\Windows\Microsoft.NET\Framework64\v4.0.30319\sos.dll` 指定具体路径
1. 调试结束时，关闭windbg前应该 `debug菜单 -> detach debugee`，否则进程会崩溃，dump文件无妨。

<img src="/assets/images/windbg/windbg_pic2.png" alt="windbg02" width="300px" />
<img src="/assets/images/windbg/windbg_pic2-2.png" alt="windbg02-2" width="300px" />
<img src="/assets/images/windbg/windbg_pic3.png" alt="windbg03" width="300px" />

## Windbg命令笔记
有了windbg，怎么开始？具体过程和windbg的输出就不记录了，占篇幅太长。  
那么在使用windbg，面对如此多的输出，我们重点看什么？`重点看统计信息`，几乎每个命令的输出最后都会有统计信息，一般按对象占用字节数大小升序排列。  

这里记一些常用命令：  

    .loadby sos clr  //加载.net framework 调试dll，clr对应.net 4.0及以上，.net 4.0以前用 mscorwks
    !eeheap         //查看.net堆信息, 选项 -gc 只看托管堆gc heap， -loader 只看loader heap
    !heap -s        //基本堆状态
    !dumpdomain     //查看AppDomain及程序集加载信息
    !dumpheap -mt 00000011  //查询method table
    !dumpheap -strings  //查询所有字符串对象
    !dumpheap -stat //堆内对象统计
    !gcroot 00000011    //查询指定地址对象是被谁调用或者实例化的
    !do 00000012    //查看指定地址内容
    !dumpmodule 00000013    //查看指定模块

往内存溢出方向使用这些命令尝试了几十次后，终于发现`!dumpdomain`有些异常:  
前面说的5G大小的dump文件，copy`!dumpdomain`的输出经过`grep ^Domain `过滤，居然有17个AppDomain，  

    [wbc@mbp:~]$grep ^Domain data3
    Domain 1:           000000fae3c28510
    Domain 2:           000000ff2ea50480
    Domain 3:           000000ff32481580
    Domain 4:           000000ff3545b2c0
    Domain 5:           000000ff35bab0c0
    Domain 6:           000000ff3abaec40
    Domain 7:           000000fae3bf01d0
    Domain 8:           000000ff3c95e560
    Domain 9:           000000ff3ea0d170
    Domain 10:          000000ff40d31e80
    Domain 11:          000000ff42b36a20
    Domain 12:          000000ff43d65a00
    Domain 13:          000000ff45eba410
    Domain 14:          000000ff46a4f080
    Domain 15:          000000ff48524090
    Domain 16:          000000ff4800aac0
    Domain 17:          000000ff43d74920
    [wbc@mbp:~]$

难道是CI发布密集，AppDomain来不及卸载？(等等！发布后进程没回收？这是webdeploy的作用？)  

## 总结

和同事多次*发布-回滚-发布-回滚...*验证后，总结：

*(这条是猜测，是IIS的作用还是webdeploy的作用未经证实)*  
IIS 通过webdeploy方式发布时，不会回收进程，会自动增加新的AppDomain和卸载旧的AppDomain。然而，在短时间内密集发布，可能导致旧的AppDomain来不及卸载，再加上服务器本身如果负载较高，cpu比较紧张的话，加载新AppDomain及其相关程序集（需要编译IL）就会非常占用内存。

解决方法：  

在每次发布后，确保回收应用程序池。  
[msdeploy远程回收应用程序池](https://blogs.iis.net/msdeploy/operations-on-application-pools-as-admin-and-non-admin)

其他优化点(查内存，查出来几个非主要问题，也是可优化的地方)：  

1. 针对iis站点的进程，合理设置cpu关联，可以减少托管堆数量（和可用cpu核心数量相同），降低内存占用。  
1. 清理无用目录和文件，减少[FCN问题](https://shazwazza.com/post/all-about-aspnet-file-change-notification-fcn/)
1. 去掉Nlog异步写文件，去除不必要的nlog target或rules

*FCN* `File Change Notification`，FCN贡献了上述5G内存占用中字符串对象的773MB内存占用。  
基本都是重复的以`关键目录的更改通知。..bin dir change or directory rename..`开头的类似日志的内容。  

*CLR* windbg中，经常可以看到很多module，这是托管模块，是c#编译后代码被CLR处理的单元

## 参考

* [SOS.dll](https://docs.microsoft.com/en-us/dotnet/framework/tools/sos-dll-sos-debugging-extension)
* 《CLR via C#》  
* 极力推荐李争老师：《微软互联网信息服务(iis)最佳实践》，第9章开始，后半本都是windbg的使用范例，满满干货。

## 追记莱特大神提醒

numa跨越可能引起性能问题

>[Numa 简介](https://msdn.microsoft.com/zh-cn/library/dn282282(v=ws.11).aspx#bkmk_Intro)  
>非一致性内存访问 (NUMA) 是一种计算机系统体系结构，该体系结构适用于多处理器设计，此类设计中某些内存区域具有更大的访问延迟。 这取决于系统内存和处理器互连的方式。 某些内存区域直接连接到一个或多个处理器，而所有处理器通过各种类型的互连构造相互连接。 对于较大的多处理器系统，这种排列方式会减少内存争用并提高系统性能。  
>NUMA 体系结构将内存和处理器分组，称为 NUMA 节点。 从系统中任何单个处理器的角度来看，与该处理器位于相同 NUMA 中的内存称为本地，而包含在其他 NUMA 节点中的内存称为远程。 处理器可以更快地访问本地内存。  
>通常扩展为利用许多处理器和大量内存的大多数现代操作系统和许多高性能应用程序（例如 Microsoft SQL Server）都包括可识别和适应计算机 NUMA 拓扑的优化功能。 若要避免远程访问损失，NUMA 感知应用程序会尝试为数据分配内存并计划处理器线程，以在相同的 NUMA 节点中访问该数据。 这些优化功能可最大程度地减少内存访问延迟并减少内存互连流量。  
