---
layout: post
title: "shell大括号参数扩展（Parameter Expansion）"
description: "shell大括号参数扩展（Parameter Expansion）"
category: Shell
tags: Bash
---
{% include JB/setup %}

参考了[shell十三问](http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=218853&page=7)  
以及[http://hi.baidu.com/leejun_2005/blog/item/ebfee11a4177ddc1ac6e751d.html](http://hi.baidu.com/leejun_2005/blog/item/ebfee11a4177ddc1ac6e751d.html)

提炼下记忆方式：
{% capture text %}
${变量名#(##)*分隔符}剔除首个（或最末个即最右端）分隔符左侧字串
${变量名%(%%)分隔符*}剔除首个（或最末个即最左端）分隔符右侧字串

${变量名/被替换字串/替换字串} 替换首个匹配
${变量名//被替换字串/替换字串} 替换所有匹配
{% endcapture %}
{% include JB/liquid_raw %}

关于#和%的另一种助记方法：

	首先看键盘上的#$%键，#      $      %   
	使用#就表明匹配方向是从左向右  
	使用%就表明匹配方向是从右向左  
	单个#或单个%表示非贪婪匹配，匹配最短的部分  
	两个#或两个%表示贪婪匹配，匹配最长的部分  
	最后，剔除匹配部分。（*和分隔符直接看作匹配模式即可）