---
layout: post
title: "awk利用关联数组合并记录"
description: "awk利用关联数组合并记录,shell按关键字合并记录。"
category: Shell
tags: Awk Bash
---
{% include JB/setup %}

问题源起：[http://bbs.chinaunix.net/thread-3753784-1-1.html](http://bbs.chinaunix.net/thread-3753784-1-1.html)

代码如下
{% capture text %}
$awk '{if(!a[$1]){a[$1]=$1" "$2;}else{a[$1]=a[$1]"_"$2}}END{for(i in a){print a[i]}}' file.txt
a 1_2_3
b 4_5
c 6_1
d 2_4
$cat file.txt
a 1
a 2
a 3
b 4
b 5
c 6
c 1
d 2
d 4
{% endcapture %}
{% include JB/liquid_raw %}