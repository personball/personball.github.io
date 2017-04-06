---
layout: post
title: "rabbitmq notes"
description: "rabbitmq配置笔记"
category: MQ
tags: rabbitmq
---
{% include JB/setup %}

### 安装

系统：CentOS 6
环境： rabbitmq 依赖的[Erlang环境包](https://www.rabbitmq.com/releases/erlang/erlang-18.1-1.el6.x86_64.rpm)
    
    wget https://www.rabbitmq.com/releases/erlang/erlang-18.1-1.el6.x86_64.rpm

Server：[rabbitmq-server安装包](https://www.rabbitmq.com/releases/rabbitmq-server/v3.5.7/rabbitmq-server-3.5.7-1.noarch.rpm)

    wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.5.7/rabbitmq-server-3.5.7-1.noarch.rpm

### 配置

插件：启用web管理界面插件:

    rabbitmq-plugins enable rabbitmq_management

添加用户，设置用户为管理员以登录web管理界面:

    rabbitmqctl add_user {username} {password}

设置用户为管理员：
    
    rabbitmqctl set_user_tags {username} administrator

添加vhost:

    rabbitmqctl add_vhost test //rabbitmq 设置的vhost名称不用带斜杠/


设置用户对vhost的权限:

    rabbitmqctl set_permissions -p myvhost tonyg "^tonyg-.*" ".*" ".*"

rabbitmqctl参考：[rabbitmqctl Doc](https://www.rabbitmq.com/man/rabbitmqctl.1.man.html)

### 运行时辅助命令

查看端口占用情况

    netstat -a |grep 15672

查看哪个应用占用了该端口

    lsof -i:15672

防火墙开通指定端口

    /sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    /etc/rc.d/init.d/iptables save

关闭防火墙

    service iptables stop

### windows服务作为消费端

创建服务的命令

    sc create ServiceA displayname= "ServiceA_DisplayName" binPath= "/path/to/exe" start= auto
    sc start ServiceA

rabbitmq配置格式

    amqp://gqc:gqc@10.16.35.92/gqc_host

### CentOS辅助相关

centos 添加epel库

    yum install epel-release
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

centos 安装python pip

    yum install python-pip

## rabbitmq 配置集群

主节点所在服务器开放4369端口，开放25672端口

从节点添加hosts解析主节点的计算机名
    
    vim /etc/hosts
    +10.16.35.92 rabbitmqServer

从节点执行
    
    rabbitmqctl stop_app
    rabbitmqctl join_cluster rabbit@rabbitmqServer
    rabbitmqctl start_app


## rabbitmq 集群特性

1. 除队列外，其他元素全部自动镜像，队列默认持久化但不镜像（所在节点挂了则该队列内数据就下线了，节点恢复则原数据重新恢复上线），需要配置policy
2. 当队列需要高可用时，需要配置policy,启用队列的镜像和自动同步，可设置ha-sync-batch-size以提高队列性能，可设置queue-master-locator策略

policy设置范例(gqc_host中所有队列启用高可用，自动在所有节点上镜像并自动同步)

    Virtual Host    :   gqc_host
    Name            :   ha-all
    Pattern         :   .*
    Apply to        :   queues
    Definition      :   ha-mode:all  ha-sync-mode:automatic
    Priority        :   0


## 追记CentOS7安装步骤

* wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.9/rabbitmq-server-3.6.9-1.el7.noarch.rpm
* yum install erlang
* rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
* yum install rabbitmq-server-3.6.9-1.el7.noarch.rpm
* systemctl enable rabbitmq-server.service
* systemctl start rabbitmq-server
* rabbitmq 配置web管理界面插件、添加用户、添加vhost等
* systemctl edit rabbitmq-server 配置LimitNOFILE放开文件描述符限制

systemctl edit rabbitmq-server 输入范例：

    [Service]
    LimitNOFILE=32768

### CentOS7防火墙firewalld管理

* firewall-cmd --zone=public --add-port=15672/tcp --permanent
* firewall-cmd --zone=public --add-port=5672/tcp --permanent
* firewall-cmd --reload

### CentOS7服务管理

* systemctl --list-unit-files|grep rabbitmq
* systemctl enable rabbitmq-server.service
* systemctl edit rabbitmq-server 服务配置（放开文件描述符限制）

## 参考资料
[官方RPM安装文档](http://www.rabbitmq.com/install-rpm.html)