---
layout: post
title: "logstash配置示例"
description: "配置logstash直接在rabbitmq上建立队列订阅消息，配置logstash解析nginx日志"
category: ELK
tags: [ELK]
---
{% include JB/setup %}

### 提醒
`/etc/logstash/conf.d/`下虽然可以有多个conf文件，但是Logstash执行时，实际上只有一个pipeline，它会将`/etc/logstash/conf.d/`下的所有conf文件合并成一个执行。如果希望每个input-filter-output都互相独立，那么就需要在input中加自定义field，后面所有的filter和output必须加if条件语句，如

    input{
        rabbitmq{
            ...//略
            add_field=>{"custom_t"=>"auditing"}
        }
    }
    filter{
        if [custom_t]=="auditing"{
            date{
                ...//略
            }
        }
    }
    output{
        if [custom_t]=="auditing"{
            elasticsearch{
                ...//略
                index=>"auditing-%{+YYYY.MM.dd}"
            }
        }
    }

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

nginx日志示例（非默认）

    112.247.107.98 - - [27/Jul/2017:18:09:20 +0800] "POST /elasticsearch/_msearch HTTP/1.1" 200 0.830 0.830  21599 "http://abc.yourdomain.com/app/kibana" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4" "-" "10.173.163.214:5601" "abc.yourdomain.com:80"

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
            match => { "message" => ["%{IPORHOST:nginx_access_remote_ip} - %{DATA:nginx_access_user_name} \[%{HTTPDATE:nginx_access_time}\] \"%{WORD:nginx_access_method} %{DATA:nginx_access_url} HTTP/%{NUMBER:nginx_access_http_version}\" %{NUMBER:nginx_access_response_code} %{NUMBER:nginx_time1} %{DATA:nginx_time2} %{NUMBER:nginx_access_body_sent_bytes} \"%{DATA:nginx_access_referrer}\" \"%{DATA:nginx_access_agent}\" \"%{DATA:client_proxy_ip}\" \"%{IPORHOST:backend_server}:%{NUMBER:backend_server_port}\" \"%{IPORHOST:request_host}:%{NUMBER:request_host_port}\""] }
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

