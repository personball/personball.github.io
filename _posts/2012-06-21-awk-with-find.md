---
layout: post
title: "结合find的awk"
description: "结合find的awk"
category: BashShell
tags: [awk]
---
{% include JB/setup %}

源起：[http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=3754423&page=1&extra=#pid22172981](http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=3754423&page=1&extra=#pid22172981)

	find . -type f -exec awk 'BEGIN{tmp=0;}{if(tmp&&($0~/^$/))print FILENAME":""line:"FNR":"$0;tmp=($0~/,$/)}' {} \;

	find . -type f -exec awk 'BEGIN{tmp=0;}{if(tmp&&(NF==0))print FILENAME":"FNR":"$0;tmp=($0~/,$/)}' {} \;

找出当前目录下所有文件中的空行，该空行符合“相邻的上一行以逗号结尾”。  
对find命令再添加-name *.sql就可以限定范围。