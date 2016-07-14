---
layout: post
title: "Mac系统上的几个命令解释器(控制台)"
description: "Mac系统上的几个解释器的常用功能说明，七周七语言"
category: mac_os
tags: REPL Tips Mac
---
{% include JB/setup %}

### irb

* 语言：Ruby
* 帮助：help
* 清屏：CTRL+L
* 自动完成：Tab+Tab (若未开启，则在`/etc/irbrc`中`require 'irb/completion'`)
* 退出：quit/exit/CTRL+D

### io

* 语言：Io
* 清屏：CTRL+L
* 自动完成：无（可使用slotNames消息查看可用的槽）
* 退出：exit/CTRL+D

### gprolog

* 语言：Prolog
* 自动完成：Tab+Tab
* 退出：halt./CTRL+C e/CTRL+D

### swipl

* 语言：Prolog
* 帮助：help.
* 清屏：CTRL+L
* 命令以句点结束
* 编译并载入文件：['filename.pl'].
* 大写表示变量（待解）
* :- 规则符号
* ;下一个解，a 全部解
* 退出：halt./CTRL+D

### scala

* 语言：Scala
* 帮助：:help
* 清屏：CTRL+L
* 自动完成：Tab
* 退出：:quit/CTRL+D

### erl

* 语言：Erlang
* 命令以句点结束
* 自动完成：Tab
* 退出：CTRL+C a Enter

### clj

* 语言：Clojure
* 退出：CTRL+D

### lein repl

* 语言：Clojure
* 清屏：CTRL+L
* 自动完成：Tab
* 退出：quit/exit/CTRL+D

### ghci

* 语言：Haskell
* 帮助：:?
* 清屏：CTRL+L
* 自动完成：Tab
* 退出：:quit/CTRL+D

### rails console

* 语言：Ruby
* 加载了rails项目代码的irb,用法和irb差不多


`部分解释器（clj，erl，gprolog）不能清屏或不能自动完成（或许有方法而我没发现？）比较不方便。`

***
下面还有几个涉及数据库的控制台（叫解释器貌似不太合适）

### sqlite3 test.sqlite3

* 帮助：.help
* 查看表：.tables
* 查询语言：sql 以分号结尾
* 清屏：CTRL+L
* 退出：.quit/.exit/CTRL+D

### redis-cli

* 帮助：help
* 查询语言：Nosql,具体用法参考命令手册
* 清屏：CTRL+L
* 退出：quit/exit/CTRL+D

### mysql -uroot

* 帮助：help
* 查询语言：sql 以分号结尾
* 清屏：CTRL+L
* 退出：quit/exit/CTRL+D