---
layout: post
title: "模板引擎Razor Engine用法示例"
description: "Razor Engine 用法示例"
category: tools
tags: [RazorEngine]
---
{% include JB/setup %}

好久没写博客了，回宁波后最近几个月一直忙些线下的事情。  
敲代码方面脱产有阵子了，生疏了，回头一看，这行业果然更新飞快。  
最近线下的事情基本忙完，准备开始干回老本行，最重要的一件事就是升级abplus库，以符合dotnet standard标准。  
本篇就是看到abplus里的T4工具，想着换个模板引擎，据说Razor Engine不错，所以玩了下看看。  

## Razor Engine

介绍RazorEngine的资料很多，这里就简单提提：

1. RazorEngine最早出自微软AspNet Mvc框架，经历过那个时期的老人基本有印象，Web开发的网页文件，从`.aspx`文件变为了`.cshtml`。  
1. Razor语法非常干净利落，用起来比`.aspx`的视图语法（各种`<%  %>`配对，心累）舒服多了，也正因为此，很多人希望用它替代T4模板（T4模板语法较旧，没有专门编辑器的话，就没有高亮和智能提示）  
1. Razor模板有强类型概念，对于循环生成多个结果比T4方便
1. Razor使用场景非常灵活，以nuget包形式安装，只要把模板（字符串）和替换数据给它，就能给出替换结果，可以处理运行时动态模板。

但是实际用过后发现，目前RazorEngine在某些地方是不如T4方便的：  

1. RazorEngine只处理模板语法，应用场合很灵活，输入只要模板的内容，所以它不管理模板文件，你需要自己管理模板文件，并读取模板内容丢给它；
1. 与上面一样，RazorEngine不管理输出文件，只能你自己控制输出文件路径，按照dotnet core之前的framework的情况，你还得手动把输出的代码文件(比如类定义`.cs`文件)添加到项目里，这个就不如T4（模板文件和输出文件在vs中直接嵌套式关联，并直接可参与当前项目编译）方便；  

综上，利大于弊，还是值得使用的，不过目前dotnet core版的RazorEngine还不太稳定，这次没跑成功，略遗憾。  
下面给的是framework 4.6下的示例代码。  

## 示例代码

首先，安装包  

    Install-Package RazorEngine

示例代码  

    static void Main(string[] args)
    {
        //读取模板，按照嵌入式资源文件方式管理
        var assembly = Assembly.GetExecutingAssembly();
        //默认命名空间，这里和程序集名称一致
        var defaultNameSpace = assembly.GetName().Name;
        //模板文件名，如果有文件夹，则要加上文件夹名
        var templateFileName = "template1.cshtml";

        var templateContent = string.Empty;
        using (var reader = new StreamReader(
            assembly.GetManifestResourceStream(
                $"{defaultNameSpace}.{templateFileName}")))
        {
            templateContent = reader.ReadToEnd();
        }

        //编译模板
        Engine.Razor.Compile(templateContent, "templateKey", null);

        //使用模板，这里的model信息通过其他途径获取，就能实现很多工具
        //1.连DB，根据表生成类
        //2.读dll，根据程序集内定义的实体信息反射得到类名数据等，
        //  生成辅助代码，如简单CRUD的DTO
        //3.读dll，根据程序集里DTO的定义、AppService接口定义，
        //  或WebApi的定义生成js或者ts调用代理和前端的模型定义
        var output = Engine.Razor.Run("templateKey", null, 
                    new { Name = "MyRazorEngineTestClass" });
        
        //输出到文件
        Console.WriteLine(assembly.Location);
        var folderName = "RazorOutput";
        var fileName = "tempClass.cs";
        var targetFolder = $"{
            assembly.Location.Substring(0, 
            assembly.Location.LastIndexOf('\\'))}\\..\\..\\{folderName}";
        
        if (!Directory.Exists(targetFolder))
        {
            Directory.CreateDirectory(targetFolder);
        }
        var targetPath = $"{targetFolder}\\{fileName}";
        File.WriteAllText(targetPath, output);

        Console.Write(output);
        
        Console.ReadLine();
    }


demo项目解决方案如图  

<img src="/assets/images/razor_01.png" alt="razor_01" width="600px" />  

可以看到代码中有一个模板编译的步骤，可以了解下[RazorEngine运行的原理](https://antaris.github.io/RazorEngine/AboutRazor.html)

完。
