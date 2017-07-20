---
layout: post
title: "logstash配置示例"
description: "配置logstash直接在rabbitmq上建立队列订阅消息，配置logstash解析nginx日志"
category: ELK
tags: [ELK]
---
{% include JB/setup %}


### Rabbitmq Input 解析审计日志

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
            add_field => {"env"=>"DEV"}
            add_field => {"test"=>"test"}
        }
    }
    filter{
        date{
            match => ["ExecutionTime","ISO8601"]
        }
    }
    output {
        elasticsearch { hosts => ["localhost:9200"] }
    }

`/usr/share/logstash/bin/logstash -f logstash-rabbitmq-input.conf --config.test_and_exit` 检测配置是否正确

### Filebeat Input 解析nginx日志（非默认格式）

在`/etc/logstash/conf.d`目录新增`dev-nginx-filebeat.conf`内容如下

    input {
        beats {
            # The port to listen on for filebeat connections.
            port => 5044
            # The IP address to listen for filebeat connections.
            host => "127.0.0.1"
        }
    }
    filter {
        grok {
            keep_empty_captures => "true"
            match => { "message" => ["%{IPORHOST:nginx_access_remote_ip} - %{DATA:nginx_access_user_name} \[%{HTTPDATE:nginx_access_time}\] \"%{WORD:nginx_access_method} %{DATA:nginx_access_url} HTTP/%{NUMBER:nginx_access_http_version}\" %{NUMBER:nginx_access_response_code} %{NUMBER:nginx_access_body_sent_bytes} %{DATA:nginx_time1} %{DATA:nginx_time2} \"%{DATA:nginx_access_referrer}\" \"%{DATA:nginx_access_agent}\""] }
            remove_field => "message"
        }
        date {
            match => [ "nginx_access_time", "dd/MMM/YYYY:H:m:s Z" ]
            remove_field => "nginx_access_time"
        }
        useragent {
            source => "nginx_access_agent"
            target => "nginx_access_user_agent"
            remove_field => "nginx_access_agent"
        }
    }
    output {
        elasticsearch {
            hosts => localhost
            manage_template => false
            index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
            document_type => "%{[@metadata][type]}"
        }
    }

`/etc/filebeat/filebeat.yml` 配置

    filebeat.prospectors:
    - input_type: log
    paths:
        - /usr/local/nginx/logs/*.log
    output.logstash:
    hosts: ["localhost:5044"]

