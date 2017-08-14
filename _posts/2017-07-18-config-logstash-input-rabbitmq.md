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

### 1. Rabbitmq Input 解析审计日志

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

### 2. Filebeat Input 解析nginx日志（非默认格式）

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


### 3. Filebeat Input 对接应用程序日志(Nlog)

首先固定日志格式，特别注意时间戳，示例Nlog target

    ...
    <wrapper-target name="f2elk" xsi:type="AsyncWrapper" overflowAction="Grow" timeToSleepBetweenBatches="100" batchSize="100" queueLimit="10000">
      <target name="file2elk"
              xsi:type="File"
              layout="[${date:format=dd/MMM/yyyy\:HH\:mm\:ss zz00:culture=en}] [${Env}] [${Proj}] [${level}] [${logger}] MSG[${message}]MSG EX[${exception:format=toString}]EX"
              fileName="d://logs/elk/${Env}.${Proj}.${date:format=yyyyMMdd}.log"
              keepFileOpen="false"
              encoding="utf-8" />
    </wrapper-target>
    ...
    <logger name="*" minlevel="Debug" writeTo="f2elk" />

`filebeat.yml` 示例

    filebeat.prospectors:
    - input_type: log
    paths:
        - d:\logs\elk\*
    
    multiline.pattern: ^\[[0-9]{2}/[A-Za-z]{3}/[0-9]{4} #一定要注意时间戳格式和日志的输出匹配
    multiline.negate: true
    multiline.match: after

    output.logstash:
    hosts: ["localhost:5044"]

`/etc/logstash/conf.d/nlog-input.conf` 示例

    input {
        beats {
            # The port to listen on for filebeat connections.
            port => 5046
            # The IP address to listen for filebeat connections.
            host => "10.173.163.214"
            add_field =>{"custom_t"=>"nlog"}
        }
    }
    filter {
        if [custom_t]=="nlog"{
        grok {
            keep_empty_captures => "true"
            match => { "message" => ["\[%{HTTPDATE:LogTime}\] \[%{DATA:env}\] \[%{DATA:ProjectName}\] \[%{LOGLEVEL:Level}\] \[%{DATA:Logger}\] MSG\[%{DATA:LogMessage}\]MSG EX\[%{DATA:Exception}\]EX"] }
            remove_field => "message"
        }
        date{
            match => ["LogTime","dd/MMM/YYYY:H:m:s Z"]
        }
        }
    }
    output {
        if [custom_t]=="nlog"{
        elasticsearch {
            hosts => localhost
            manage_template => false
            index => "nlog-%{+YYYY.MM.dd}"
            document_type => "nlog"
        }
        }
    }

#### win2008 安装filebeat，无法执行ps脚本的问题

管理员身份执行cmd，用sc命令安装服务

    sc create filebeat displayName= filebeat binPath= "C:\\filebeat-5.5.1-windows-x86_64\\filebeat.exe -c C:\\filebeat-5.5.1-windows-x86_64\\filebeat.yml -path.home C:\\filebeat-5.5.1-windows-x86_64 -path.data C:\\ProgramData\\filebeat" start= auto
