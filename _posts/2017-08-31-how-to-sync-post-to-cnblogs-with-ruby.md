---
layout: post
title: "如何使用ruby同步markdown博文到博客园"
description: "如何使用ruby同步markdown博文到博客园"
category: ruby
tags: [ruby]
---
{% include JB/setup %}

这两天折腾了一下用ruby通过MetaWeblog接口把本博客同步到博客园，特此记录。  

## MetaWeblog

MetaWeblog是一个专门关于博客的协议标准，通过xmlrpc，很简单的定义了新增、编辑、删除三个基本接口。

在博客园`设置页签的最下方，保存按钮之前`有每个用户的MetaWeblog接口地址：  

    MetaWeblog访问地址: http://rpc.cnblogs.com/metaweblog/personball

打开这个接口地址，可以看到接口文档。  

那么通过什么方式调用这个服务呢？  
最好是脚本语言，这毕竟不是开发项目，用需要编译生成的静态语言有点小题大做。  

如果你熟悉Python，或许也可以找到MetaWeblog的客户端库，下面介绍通过Ruby版MetaWeblog客户端进行XmlRpc调用。

## 通过Ruby脚本调用metaWeblog.newPost

准备工作：  

1. ruby升级到2.3版本；
1. gem install metaweblog

*对了，我这里是Mac系统。下面先讲几个注意点，具体操作放最后。*  

### Tip1 发布频率

博客园的MetaWeblog接口对博文发布频率做了限制，发布间隔太短会遇到提示：  

    30秒内只能发布1篇博文，请稍候发布

间隔30秒还是很容易触发，建议`发布间隔60秒`。

### Tip2 发布Markdown

发布Markdown内容要求`Post结构中的categories设成[Markdown]`，注意categories要求是`数组`，具体请看接口文档中`struct Post`一栏。  

### Tip3 扩展MetaWeblog中的Post对象

你找到的MetaWeblog客户端很可能是通用的，所以不会针对博客园的接口做适配，肯定需要针对Post对象做扩展。  

博客园MetaWeblog接口`Post`结构中的`title`是文章标题，`description`是文章内容，这两个都是必填项。  
*如果遇到异常提示，必须思考下是不是博客园服务器端抛出来的。*  


## 本博客的同步脚本

完整代码见：  

[cnblogs_post.rb](https://github.com/personball/personball.github.io/blob/master/cnblogs_post.rb)  
[post_sync.rb](https://github.com/personball/personball.github.io/blob/master/post_sync.rb)  

其中`cnblogs_post.rb`是针对博客园接口的扩展，主要加了个`:categories`，去掉了原先`MetaWeblog::Post`定义的`:link`。  
*`:dateCreated`虽然加了，但是目前博客园不使用接口传进去的值，而用服务器接收时间作为发布时间。需要修改的话，必须到后台编辑文章页面，展开最下方的`其他选项`，勾选`修改发布时间`。（我嫌麻烦，直接title上加日期前缀了）*  

`post_sync.rb`主要是单篇文章同步用脚本，处理了几个问题：  

1. 加载`cnblogs_post.rb`，以使用`MetaWeblog::CnblogsPost`；
1. 读取配置（接口地址、用户名、密码等）；
1. 打开_posts目录中的markdown文件，进行一定的处理（解析Jekyll文件头之类）；
1. 处理文章中的相对路径，主要是资源链接和博文链接等；


### Yaml配置文件

`post_sync.yml`范例：  

    target: http://rpc.cnblogs.com/metaweblog/personball
    source: http://personball.com
    username: yourUserName
    password: yourPWD

*配置文件一定记得不要推送到github上，`.gitignore`中必须指定忽略`post_sync.yml`。*  

### 批量调用

首先`post_sync.rb`必须设置成可执行：  

    chmod u+x post_sync.rb

然后使用bash脚本批量调用，
批量调用脚本参考[batch_sync.sh](https://github.com/personball/personball.github.io/blob/master/batch_sync.sh)  

这个脚本可以通过find命令遍历`_posts`目录自动生成：  

    find _posts/*|xargs -n 1 echo ./post_sync.rb >> batch_sync.sh

对了，其中`sleep 55s`这是通过vscode多行编辑插入的。

## 最后，强烈建议程序员一定要多玩玩命令行。

git add .
git commit -a
git push && ./post_sync.rb _posts/2017-08-31-how-to-sync-post-to-cnblogs-with-ruby.md

Go!
