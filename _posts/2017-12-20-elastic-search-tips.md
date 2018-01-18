---
layout: post
title: "ElasticSearch 小记"
description: "ElasticSearch 安装，索引，查询，聚合"
category: ElasticSearch
tags: [ElasticSearch ELK]
---
{% include JB/setup %}

##介绍

[ElasticSearch](https://www.elastic.co/cn/)是一款搜索引擎中间件，因其强大的全文索引、查询统计能力和非常方便的全套基于Restful的接口，以及在自动分片、无停机升级扩容、故障转移等运维高效性，逐渐成为中小型甚至非专门处理搜索业务的大型公司的首选搜索引擎方案。  

入门可以看完整汉化的[《Elasticsearch: 权威指南》](https://www.elastic.co/guide/cn/elasticsearch/guide/current/index.html)，但打算上手实践或者应用到生产时，建议还是过一遍对应你所使用版本的[英文文档](https://www.elastic.co/guide/index.html)。

##安装

之前有写过一篇[ELK安装笔记](/elk/2017/07/18/install-elk)，这里就不重复介绍了。

##基本管理

之前在搭建ELK的时候，我并没有深入去研究ElasticSearch，更多的是看如何搭配Logstash和各种beats来收集我需要的服务器日志和应用日志，以及去尝试理解kibana界面的使用。而在写作本文的时候，我已经完成了ElasticSearch在公司业务中的使用，虽然只是简单索引订单和一些关键业务数据以便于出统计图表，还没真正去用全文搜索（要考虑分词插件和词库维护等，暂时没有足够资源去支持）功能，但也足以意识到ElasticSearch才是ELK的核心。

*注：完整看过ElasticSearch的查询语法、索引机制和聚合能力后，使用kibana会更顺手。*

下面记一些常见意图的实现和我初步使用的经验。

###查看索引，分片数、副本数

    $curl -XGET http://localhost:9200/_cat/indices?v
    health status index                      uuid                   pri rep docs.count docs.deleted store.size pri.store.size
    yellow open   boss_ecom_events-init      2fTTEmCsQFe1mJRYl9WAyg   5   1      38653            0       17mb           17mb
    yellow open   .kibana                    l0eRtbUdTNSbEcKWmTJ1Yg   1   1          2            1       12kb           12kb
    yellow open   logstash-2017.07.20        RejKqjPvRZeSoNaJ9mdq6A   5   1          3            0     28.2kb         28.2kb
    green  open   boss_ecom_indexservice     RRHlbrxvT-eX64vf3PhNyA   1   0      56259            0     28.5mb         28.5mb
    green  open   dev-boss_ecom_indexservice 8WuyMnrzSbqETqkadAm3TA   1   0      56267            3     28.6mb         28.6mb
    yellow open   dev-boss_ecom_events-init  hAekN-C3TCa6B27TvycJWw   5   1      38653            0     16.7mb         16.7mb
    yellow open   test_datetime              wL02JY1fRMi03TiHB-R_1w   5   1          3            0     16.1kb         16.1kb

* health:健康状况，红黄绿针对的是该索引在当前集群的可用级别。一般情况下，yellow表示指定的副本数不足，red表示有分片出问题了。
* status:索引除了创建和删除，还可以关闭以节省资源。
* index:索引名称
* uuid:略
* pri:分片数，默认5
* rep:副本数，默认1
* docs.count:索引中的文档数量
* docs.deleted:索引中删除的文档数量
* size:索引占用磁盘大小（store.size和pri.store.size的区别没注意过，具体请参考官方文档）

###查看模板，设置默认分片数、副本数

创建一个索引模板：

    curl -XPUT http://localhost:9200/_template/my_all -d '{"template":"*","settings":{"number_of_shards":3,"number_of_replicas":0}}'

查看索引模板列表：

    $curl -XGET http://localhost:9200/_cat/templates?v
    name     template order version
    my_all *        0

查看指定索引模板内容：

    curl -XGET http://localhost:9200/_template/my_all?pretty
    {
        "my_all" : {
            "order" : 0,
            "template" : "*",
            "settings" : {
            "index" : {
                "number_of_shards" : "3",
                "number_of_replicas" : "0"
            }
            },
            "mappings" : { },
            "aliases" : { }
        }
    }

通过索引模板，我们可以预先设定符合模板中指定命名规则的索引在创建时的配置参数，比如这里设置副本数为0，分片数为3。

*注意：副本数在索引创建后还可以修改，但是分片数一旦指定，就无法修改。除非明确知道自己要干什么，一般不建议修改分片数量。*

###查看mapping、setting，设置mapping设置setting

查看索引映射mapping：

    curl -XGET http://localhost:9200/test_datetime/_mappings?pretty
    {
        "test_datetime" : {
            "mappings" : {
            "accountregistermqmessage" : {
                "properties" : {
                "eventTime" : {
                    "type" : "date"
                },
                "mobile" : {
                    "type" : "text",
                    "fields" : {
                    "keyword" : {
                        "type" : "keyword",
                        "ignore_above" : 256
                    }
                    }
                },
                "operatorUserId" : {
                    "type" : "long"
                },
                "userId" : {
                    "type" : "long"
                },
                "userType" : {
                    "type" : "text",
                    "fields" : {
                    "keyword" : {
                        "type" : "keyword",
                        "ignore_above" : 256
                    }
                    }
                }
                }
            },
            "orders" : {
                "properties" : {
                "creationTime" : {
                    "type" : "date"
                },
                ...//略
                }
            }
            }
        }
    }

查看索引setting:

    curl -XGET http://localhost:9200/test_datetime/_settings?pretty
    {
        "test_datetime" : {
            "settings" : {
            "index" : {
                "creation_date" : "1509089305484",
                "number_of_shards" : "5",
                "number_of_replicas" : "1",
                "uuid" : "wL02JY1fRMi03TiHB-R_1w",
                "version" : {
                "created" : "5050099"
                },
                "provided_name" : "test_datetime"
            }
            }
        }
    }

设置setting：

    curl -XPUT http://localhost:9200/clientlog-*/_settings -d '{"number_of_replicas":0}'

设置mapping和设置setting类似，只要PUT对应上面查询到的Json结构的键值到`/索引名/_mappings`API即可，由于映射涉及数据类型等较复杂的规则和作用，这里不展开了。

###简单search，多索引、多类型

命令行简单查询：

    curl -XGET http://localhost:9200/boss_ecom_indexservice/_search?pretty=%26q=abc

上述所有curl命令中，api路径涉及指定索引名称和类型的url段都支持通配符，如`/clientlog-*/_settings`

### SDK NEST使用示例

对于比较复杂的查询，在命令行上编辑请求体Json对象就非常麻烦了，可以使用官方SDK:[Elasticsearch.Net & NEST](https://github.com/elastic/elasticsearch-net)。  
代码示例：  

<img src="/assets/images/es/nest_query.png" alt="nest_query" width="600px"/>

##其他经验

1. Q:如何全局设置索引属性？A:索引模板
1. Q:遇到时间不准的问题？A:索引时区、查询时区、聚合时区，建议索引文档时涉及时间的字段全部带上时区信息，查询指定时间范围和按时间聚合时，也明确指定时区，否则会发生一些时间对不上的问题。*如果用CSharp开发语言，请用DateTimeOffset代替DateTime*
1. Q:为什么ElasticSearch 6.0 开始逐渐抛弃对多类型的支持？A:lucena的限制（不支持多类型），如果ElasticSearch中的索引多个类型遇到有相同名称的字段，这些同名字段不能是不同的数据类型。
1. Q:terms聚合默认只取10个？A:设置Size
1. Q:直接在命令行里构建请求体好麻烦！A:复杂查询用NEST构建，用fiddler抓包再复制并修改请求体进行调试。
1. Q:父子文档、parent、routing有依赖关系！A:父文档必须先于子文档完成索引，否则相应子文档无法完成索引。
1. Q:嵌套文档和父子文档的区别？A:都是用来表达主从关系的，区别是父子文档各自独立，子文档变更时不会影响父文档，嵌套文档则是任一边变更将导致主从双方全部重新索引。
1. Q:命令行执行curl时，`&`符号怎么转义？A:`%26`，特别的，在_search时需要加上pretty，应该`/_search?pretty=%26q=abc`注意pretty后面的等号不可省略。
1. Q:如何设置ElasticSearch的访问账号及密码？A:ElasticSearch的收费插件X-Pack可以解决安全性问题，请参考[ELK安装笔记](/elk/2017/07/18/install-elk)。如果不想付费，可以和web站点一样设置ElasticSearch绑定内网IP。（对于kibana，可以做访问ip限制）
1. Q:聚合结果想附带一些其他信息？A:使用TopHits。
