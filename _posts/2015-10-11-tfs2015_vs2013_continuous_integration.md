---
layout: post
title: "tfs2015 vs2013 配置持续集成"
description: "tfs2015 vs2013 持续集成 配置的各种坑。"
category: ci
tags: TFS CI 
---
{% include JB/setup %}

今天刚配置完tfs2015+vs2013的持续集成（自动构建+自动发布），记录一下走过的坑。  
tfs2015和tfs build server是之前其他同事装的，略去不讲，列一下几个坑以及埋坑方法。  

##前提

微软TFS的持续集成配过一次后会觉得真的还是蛮方便的，当然前提是你对它的构建工具和VS足够了解。  

首先，打开vs2013的 _团队资源管理器_ ，连接上TFS后，在团队资源管理首页上可以看到 _生成_ ，点击进入生成后，新建生成定义。  
自动生成的配置不麻烦，略去不表，参考[创建或编辑生成定义](https://msdn.microsoft.com/zh-cn/library/ms181716)，关键是生成后的自动发布，重点在 _过程_ 的配置上。  

##过程的配置重点

过程这一节的配置，使用默认模板，重点在于配置：

1. Build中的Projects 指定需要生成的解决方案；
2. Build中的Configurations 指定要使用的配置，如 Any CPU\|Release 如果配置名与默认可选的不同，可以直接编辑修改
3. Build中的Advanced 设置msbuild的参数选项;
4. Test中的Advanced 可以选择关闭测试项目的执行，disable tests；

其中msbuild的参数选项，是首次配置最迷糊的地方，其实这里就是用/p 设置一些msbuild脚本要用到的变量值。  

    /p:DeployOnBuild=True /p:PublishProfile=yourpublishprofile /p:AllowUntrustedCertificate=True /p:VisualStudioVersion=12.0  /p:Username=yourusername /p:Password=yourpassword

这里指定了vs版本号，就要提一下，生成服务器上需要安装vs，可以只选web开发相关功能安装，vs2013大概也要9G空间。  

##明明是类库项目，为啥msbuild在找发布配置文件？
这个坑，其实不容易遇到，只要是按部就班新建类库项目的话。（我也不知道为啥我们团队的类库项目会遇到这个情况）  
症结在类库项目csproj文件的内容上，用记事本或其他文本编译器打开类库项目的csproj文件，在其中搜“Microsoft.WebApplication.targets”，应该是一个或两个import配置节，删除即可。  
targets文件和csproj文件其实都是定义了一些msbuild的流程任务，而Microsoft.WebApplication.targets文件是为web应用准备的，一般类库项目是不该有这个配置的。

##error MSB4166: Child node "3" exited prematurely
中文提示应该是 “字节点 3 过早退出，正在关闭”。  
这个问题的处理，资料真不多，找了半天，最后终于看到一篇文章，是要设置msbuild的平台，由anycpu 改为 x86。  

##指定非官方的nuget源
为解决方案启用nuget restore后，如果不使用官方的源，可以在.nuget目录下的NuGet.targets中配置 PackageSource。  

##为何发布后，web.config 的配置转换没起作用？

参考 过程的配置重点 第二条

Build中的Configurations 指定要使用的配置: Any CPU\|YourConfigName 

##LibGit2Sharp报异常，git2-msvstfs.dll中 git__thread__init 不存在

这个处理了很久，解决方式是在 msbuild 参数上加上 /p:GenerateBuildInfoConfigFile=false

##其他问题

如果一个解决方案中有多个项目需要发布，那么发布的配置文件名必须一致。  

webdeploy发布工具的使用也很重要，回头另开一帖。

##参考
1. [MSBuild用法参考](http://www.infoq.com/cn/articles/MSBuild-1/)
2. [创建或编辑生成定义](https://msdn.microsoft.com/zh-cn/library/ms181716)
