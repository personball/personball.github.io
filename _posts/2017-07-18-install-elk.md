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

### Kibana

执行`sudo yum install kibana`

### Filebeat

执行`sudo yum install filebeat`

### X-Pack

执行`sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack`
执行`sudo /usr/share/kibana/bin/kibana-plugin install x-pack`
执行`sudo /usr/share/logstash/bin/logstash-plugin install x-pack`