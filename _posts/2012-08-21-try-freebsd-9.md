---
layout: post
title: "FreeBSD9.0体验记"
description: "FreeBSD9.0体验记"
category: unix
tags: [FreeBSD9.0]
---
{% include JB/setup %}

最近在看《构建高可用Linux服务器》
由于对FreeBSD的稳定性仰慕已久，正好参照该书的指导进行体验一二。
先感谢下该书作者余大大，同时做个声明：`本文中若有命令脚本涉及版权问题，请与personball@163.com联系`

###2012/08/21

####最小化安装，略；
这里本人安装的是FreeBSD9.0-i386 在官网找来的500多M的一个iso刻盘。

####更新ports源
国外的官方更新源一般网速都不太给力，改了更新源能省很多时间。

	#修改ports配置文件 
	vi /etc/portsnap.conf，
	#由于是最小化安装，连vim也是没有滴。
	#这里要注意，幸亏修改的东西不多，vi不是很熟悉，也够用了。
	
	#找到SERVERNAME=portsnap.freebsd.org改为：
	SERVERNAME=portsnap.hshh.org

portsnap首次执行

	portsnap fetch extract

以后更新执行

	portsnap fetch update

####安装axel
这个工具是代替默认的fetch，提高安装速度（其实就是获取源代码的速度吧？！）。

	cd /usr/ports/ftp/axel
	make install clean

然后修改make.conf
	
	vi /etc/make.conf

`!! FreeBSD9.0 在/etc目录下没有make.conf!!`
于是，find 查找一下。。

	freebsd# find . -name "make.conf"
	./usr/share/examples/etc/make.conf

貌似是在一个示例目录里。奇怪，先不管，去看看先。  
ok，全文都是注释掉的，那干脆直接copy到/etc下吧。  
copy make.conf到etc目录下后，注意文件权限为只读，先改成可写 
	
	chmod u+w make.conf

然后vi编辑，在文件末尾添加
	
	FETCH_CMD = axel
	FETCH_BEFOR_ARGS = -n 10 -a
	FETCH_AFTER_ARGS =
	DISABLE_SIZE = yes
	MASTER_SITE_OVERRIDE? = \
	http://ports.hshh.org/${DIST_SUBDIR}/\
	http://ports.cn.freebsd.org/${DIST_SUBDIR}/\
	ftp://ftp.freeBSDchina.org/pub/FreeBSD/ports/distfiles/${DIST_SUBDIR}/
	MASTER_SITE_OVERRIDE? =${MASTER_SITE_BACKUP}

####设置sudo
之前的操作都是用root账户登录的，但是在往后的工作中直接用root是比较危险的，这时候就需要sudo了。
也要自己动手哦，不像我本子上的ubuntu12是默认装了。  
依然去找ports

	cd /usr/ports/security/sudo && make install clean

直接按默认选择安装内容吧，除非对sudo比较了解，可以选择诸如“防止root执行sudo”之类的东东。
装完sudo，赋予帐号权限。  
修改文件 /usr/local/ect/sudoers
	
	#在 
	root ALL=(ALL) ALL
	#下添加一行
	你的用户名 ALL=(ALL) ALL

`!!遇到文件只读权限问题，自己动手chmod吧，记得编辑完再改回来，安全很重要。`

至此，可以登出root账户了。
快去试试自己的授权账户能否正常sudo吧。
一个简单的尝试，验证sudo是否正常：
登出root，换sudo授权帐号登入，试试重启sshd服务。

	$ service sshd restart  #试试直接执行命令
	Stopping sshd.
	kill: 1368: Operation not permitted  #直接执行不被允许
	sshd already running? (pid=1368).
	$ sudo service sshd restart   #试试sudo执行
	We trust you have received the usual lecture from the local System
	Administrator. It usually boils down to these three things:
	#1) Respect the privacy of others.
	#2) Think before you type.
	#3) With great power comes great responsibility.
	Password:                   #输入你自己的登录密码
	Stopping sshd.
	Starting sshd.               #成功重启

`!!注意，如果你的机器不在附近，最好换个方法来实验sudo（小心sshd挂了的话就不能正常远程了），`
`比如访问一个非root用户禁止访问的文件`  
举个例子：
	
	sudo cat /root/.history  #该文件非root用户不可访问

####安装vim

	cd /usr/ports/editors/vim
	#事后提示：悲惨经历告诉大家，不要编译装这货，装精简版的吧 还有个vim-lite
	sudo make install clean 

吐槽：安装遇到好多相依赖的东西啊，装vim的过程，连python 和 perl 一起装了，各种lib，囧，装了好久好久，可能是安装过程不小心多选了什么特性？= =

下回继续。。

#2012/08/22

####vim-lite
好吧，今天继续昨天没安装完的vim。  
实在是悲催，昨天中断安装过程，今天发现可以继续，但是历经1个多小时的安装，最后蹦出来3个ERROR，具体也不说了。  
回到/usr/ports/editor/目录，发现还有个vim-lite   精简版（难怪。。。昨天选的是非精简版安装，难怪需要那么多依赖支持。。悲剧。  
马上 sudo make install clean 不到2分钟就装完了！！ （。。。。。。）  
试了下，vim能用了，马上到主目录下添加自己的.vimrc吧。

####安装bash并切换默认shell为bash
安装部分很简单

	cd /usr/ports/shells/bash
	sudo make install clean

切换shell，书上命令

	sudo chsh -s /usr/local/bin/bash  #其实少了一个参数，用户名

安装完以后，我先试了下修改 /etc/passwd文件中对应自己账户的记录，最后一列，改为bash的路径/usr/local/bin/bash
但是退出后重新登录并不生效。
于是，百度了下，找到了命令，执行了

	sudo chsh -s /usr/local/bin/bash 你的用户名

重登录，echo $SHELL ,输出 /usr/local/bin/bash 则表示切换成功！  
bash相关设置，修改.profile  或者 .bashrc 就不讲了

####结束
基础工作就此结束，接下来大家要部署啥服务，就自己随便玩啦，要安装的程序，先到/usr/ports下find一下，找不到再去网上搜，ports是个好东西，哈。
