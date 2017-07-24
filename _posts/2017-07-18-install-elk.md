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

在`/etc/yum.repo.d/`建立文件`elastic.repo`,内容如下

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

* [ElasticSearch 配置堆内存大小](https://www.elastic.co/guide/en/elasticsearch/reference/current/heap-size.html)
* [ElasticSearch 禁用Swapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration-memory.html)


### LogStash

执行`sudo yum install logstash`

如果执行`systemctl list-unit-files|grep logstash`未找到logstash.service,  
则在`/etc/systemd/system`目录下新建logstash.service,内容如下

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


[Logstash 配置持久化缓冲队列](https://www.elastic.co/guide/en/logstash/current/persistent-queues.html)

### Kibana

执行`sudo yum install kibana`

配置端口和Host,在`/etc/kibana/kibana.yml`中启用

    server.port: 5601
    server.host: "your_host_or_ip"

### Filebeat

执行`sudo yum install filebeat`

### X-Pack（Kibana开启认证机制）

* （必选）执行`sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack`  
* （必选）执行`sudo /usr/share/kibana/bin/kibana-plugin install x-pack`  
* （可选）执行`sudo /usr/share/logstash/bin/logstash-plugin install x-pack`

启用x-pack后，需要到各组件配置文件中修改账号密码。默认账号密码为:

* elastic : changeme
* kibana : changeme
* logstash_system: changeme

其中内建账号elastic的权限最高

    [personball@centos-linux ~]$ curl -XGET http://elastic:changeme@localhost:9200/_xpack/security/user
    {
        "elastic": {
            "username": "elastic",
            "roles": ["superuser"],
            "full_name": null,
            "email": null,
            "metadata": {
                "_reserved": true
            },
            "enabled": true
        },
        "kibana": {
            "username": "kibana",
            "roles": ["kibana_system"],
            "full_name": null,
            "email": null,
            "metadata": {
                "_reserved": true
            },
            "enabled": true
        },
        "logstash_system": {
            "username": "logstash_system",
            "roles": ["logstash_system"],
            "full_name": null,
            "email": null,
            "metadata": {
                "_reserved": true
            },
            "enabled": true
        }
    }
    [personball@centos-linux ~]$

访问elasticsearch携带账号密码示例

    curl -XGET http://elastic:changeme@localhost:9200/

`/etc/kibana/kibana.yml`配置更新，设置好elasticsearch的访问密码

    server.port: 5601
    server.host: "10.211.55.5"
    elasticsearch.url: "http://localhost:9200"
    elasticsearch.username: "elastic"
    elasticsearch.password: "changeme"

`/etc/logstash/conf.d/`各配置更新，设置好output访问elasticsearch的访问密码

    elasticsearch {
        hosts => ["localhost:9200"]
        user => "elastic"
        password => "changeme"
    }

### Metricbeat 系统级监控

`sudo yum install metricbeat`

导入Dashboard `/usr/share/metricbeat/scripts/import_dashboards -es http://elastic:changeme@localhost:9200/`   
（根据导入的查询和视图，添加自己的过滤器，可以较快建立可用的Dashboard）

[Metricbeate配置](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-configuration.html)
