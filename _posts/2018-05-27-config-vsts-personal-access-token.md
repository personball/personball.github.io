---
layout: post
title: "配置VSTS认证方式使用Personal Access Token"
description: "配置VSTS认证方式使用Personal Access Token，Git, 避免重复输入密码"
category: vsts
tags: [VSTS Git]
---
{% include JB/setup %}

本文介绍下如何配置VSTS（visual studio team service，其实就是微软SaaS版的TFS）通过Personal Access Token访问其下的Git代码库。

### 问题

使用git的时候，每次拉取和推送都需要输入密码是一件挺讨厌的事。  
当我们使用github来托管代码时，github提供了几套机制来认证客户端，该配置页面如下图：

<img src="/assets/images/github_01.jpg" alt="github_01" width="600px"/>

github的帮助文档很完善，这里就不展开了，具体参见截图下方小字链接[generating SSH keys](https://help.github.com/articles/connecting-to-github-with-ssh/)或[generate a GPG key and add it to your account](https://help.github.com/articles/signing-commits-with-gpg/)。  

如果你的项目是开源项目，放github上没啥问题，如果需要不公开的私有库呢？  
我们一般选择微软的[VSTS](https://my.visualstudio.com/)，那么VSTS如何配置类似机制，避免每次都要输入密码？  

### 获取 Personal Access Token

<img src="/assets/images/vsts_01.jpg" alt="vsts_01" width="600px"/>  

如图，Personal Access Token的配置页面，点击`Add`  

<img src="/assets/images/vsts_02.jpg" alt="vsts_02" width="600px"/>  

填写描述，选择有效期限和适用哪个账户，选择 scopes，页面拉到底，点击`Create Token`

<img src="/assets/images/vsts_03.jpg" alt="vsts_03" width="600px"/>  

这里一定要注意了，图中打码并红色圈住的部分，*一定要复制下来保存好，这个token只会在当前显示一次*，以后是无法再次从vsts上获取的。

### 在本机管理 Personal Access Token

好了，我们拿到了Personal Access Token，接下来验证下是否可以正常使用这个token。  
在本地打开一个目录，按住`Shift`键，鼠标右击空白处，选择`在此处打开Powershell窗口`:  

<img src="/assets/images/vsts_04.jpg" alt="vsts_04" width="600px"/>  

在vsts中找到你的代码库（至少会有个MyFirstProject），并且复制clone地址。在Powershell提示符中输入  

`git clone https://familysrv.visualstudio.com/MyFirstProject/_git/MyFirstProject`  

如果出现新窗口要求输入微软账号，可以直接关闭，我们接下来可以在命令行中输入账号和token  

<img src="/assets/images/vsts_05.jpg" alt="vsts_05" width="600px"/>  

如上图，命令行提示输入Password的时候，输入刚才拿到的Token即可。  

至此，证明这个token确实是可用的。

可是当我们添加文件，推送上去的时候，还会提示需要输入账号密码！？  

*请注意，本文示例前面进行git clone的时候有警告：这是一个空库。*
*所以，首次git push进行推送的时候，需要声明远程分支，例`git push orgin master:master`*
  

我们应该把这个token存到哪里？  

请打开`控制面板`，`用户账户`，`管理你的凭据`，`windows凭据`：  

<img src="/assets/images/vsts_06.jpg" alt="vsts_06" width="600px"/>  

在普通凭据的右侧，点击`添加普通凭据`，如图进行输入，密码填之前拿到的token即可。  

<img src="/assets/images/vsts_07.jpg" alt="vsts_07" width="600px"/>  

重新打开Powershell，添加或修改文件，拉取，推送  

<img src="/assets/images/vsts_08.jpg" alt="vsts_08" width="600px"/>  

没有再提示需要输入账号密码，搞定！


*如果你是非windows系统，VSTS也可以配置SSH keys的方式进行认证，和Github配置方式差不多，具体见本文第二张图片VSTS左侧菜单  
`SSH public keys`*

### 参考

这篇讲了如何设置vsts的Personal Access Token 以及使用 Windows credentials manager 在本机存储这个token:   
[VSTS Personal access tokens with Git and Visual Studio 2017](https://blog.velingeorgiev.com/vsts-personal-access-tokens-with-git-visual-studio-2017)   

这里有详细说明非windows系统如何避免重复输入Github认证密码:  
[Is there a way to skip password typing when using https:// on GitHub?](https://stackoverflow.com/questions/5343068/is-there-a-way-to-skip-password-typing-when-using-https-on-github)
