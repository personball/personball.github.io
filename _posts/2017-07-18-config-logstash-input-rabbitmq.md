---
layout: post
title: "配置logstash直接在rabbitmq上建立队列订阅消息"
description: "配置logstash直接在rabbitmq上建立队列订阅消息"
category: ELK
tags: [ELK]
---
{% include JB/setup %}

在`/etc/logstash/conf.d`目录新建`logstash-rabbitmq-input.conf`内容如下

    input {
        rabbitmq {
            exchange => "RebusTopics"
            exchange_type => "topic"
            key => "Abp.Auditing.AuditingStores.AuditInfoMqMessage, Abplus.MqMessages.AuditingStore"
            durable => "true"
            queue => "logstash-input-rabbitmq"
            user => "user"
            password => "password"
            vhost => "dev_host"
            host => "127.0.0.1"
        }
    }
    output {
    elasticsearch { hosts => ["localhost:9200"] }
    }

`/usr/share/logstash/bin/logstash -f logstash-rabbitmq-input.conf --config.test_and_exit` 检测配置是否正确
