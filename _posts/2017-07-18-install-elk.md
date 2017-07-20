---
layout: post
title: "ELK安装笔记"
description: "ElasticSearch，LogStash，Kibana安装笔记"
category: ELK
tags: [ELK]
---
{% include JB/setup %}

## ELK

1. [ElasticSearch](https://www.elastic.co/cn/downloads/elasticsearch)
2. [LogStash](https://www.elastic.co/cn/downloads/logstash)
3. [Kibana](https://www.elastic.co/cn/downloads/kibana)

Server:CentOS 7

## 采用RPM导入官方源方式进行安装

    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

在`/etc/yum.repo.d/`建立文件`elastic.repo`内容如下

    [elastic-5.x]
    name=Elasticsearch repository for 5.x packages
    baseurl=https://artifacts.elastic.co/packages/5.x/yum
    gpgcheck=1
    gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
    enabled=1
    autorefresh=1
    type=rpm-md


### ElasticSearch

执行`sudo yum install elasticsearch`

### LogStash

执行`sudo yum install logstash`

如果执行`systemctl list-unit-files|grep logstash`未找到logstash.service,则在`/etc/systemd/system`目录下新建logstash.service,内容如下

    [Unit]
    Description=logstash

    [Service]
    Type=simple
    User=logstash
    Group=logstash
    # Load env vars from /etc/default/ and /etc/sysconfig/ if they exist.
    # Prefixing the path with '-' makes it try to load, but if the file doesn't
    # exist, it continues onward.
    EnvironmentFile=-/etc/default/logstash
    EnvironmentFile=-/etc/sysconfig/logstash
    ExecStart=/usr/share/logstash/bin/logstash "--path.settings" "/etc/logstash"
    Restart=always
    WorkingDirectory=/
    Nice=19
    LimitNOFILE=16384

    [Install]
    WantedBy=multi-user.target


### Kibana

执行`sudo yum install kibana`

### Filebeat

执行`sudo yum install filebeat`

### X-Pack

* 执行`sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack`  
* 执行`sudo /usr/share/kibana/bin/kibana-plugin install x-pack`  
* 执行`sudo /usr/share/logstash/bin/logstash-plugin install x-pack`  