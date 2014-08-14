---
layout: post
title: "用jQuery写简单的网站监控"
description: "用jQuery ajax 遍历分站的可访问性"
category: Web开发
tags: [Jquery]
---
{% include JB/setup %}

去年写过shell脚本使用curl监控网站是否正常，今天突然发觉，其实jquery+firebug的网络面板，更简单也更直观。

示例代码：
{% highlight html %}
<!DOCTYPE html>
<html>
<head>
<title>Test jquery http access</title>
<script src="./jquery.min.js" type="text/javascript" ></script>
<script type="text/javascript">
$(function(){
    var urls = new Array("sh","tj","nj","wx","sz",
    	"cz","hz","nb","hf","fz","xm","wh","zz","gz","szs");
    for(var i = 0,len = urls.length;i < len;i++){
        $.ajax({url:"http://"+urls[i]+".yourDomain.com"})
    }
})
</script>
</head>
<body>
</body>
</html>
...{% endhighlight %}

`以上代码存为html，同目录下放好jquery文件，然后用火狐打开即可，打开firebug的网络面板。`

有点取巧了，不过蛮方便。

`当然，不适合全天候监控。`