---
layout: post
title: "jsonp跨域调用数据的前后台说明"
description: "jsonp跨域调用数据的前后台说明 ,以Asp.Net Mvc为例"
category: Web开发
tags: [Jsonp]
---
{% include JB/setup %}

jsonp的基础知识不多讲，只提一点，即**jsonp所请求的其实是一段js代码**，比如一个函数调用：

	someFunc(para1,para2);

当然，前端页面上肯定需要函数的定义。jsonp调用了这段代码，并**立即执行**。  
如果你的函数名是确定的，这当然没有问题。但是我们经常看到jquery封装的jsonp调用会携带一个callback参数，这个其实就是个随机的函数名，方便匿名函数接管函数内容，从而通过函数的参数（前面说的那端jsonp所调用的js代码）实现数据调用。

前端示例：
{% highlight javascript %}
$.ajax({
    url:"http://yourdomain.com/hello",
    dataType: "jsonp",
    success:function(a){
        alert(a.UserName);
    }
})
{% endhighlight %}

后台示例：
{% highlight c# %}
public class HelloController : Controller
{
    public ContentResult Index(string callback)
    {
        string UserName="";
        string AdminUrl="";
        string Phone="";
        //一些业务代码
        ...
        //组装返回结果
        if(string.IsNullOrEmpty(UserName))
        {
            return Content(callback+"({'res':\"0\"})");
        }
        else
        {
            string result = callback + "(" + "{res:\"1\",UserName:\"" + UserName + "\",AdminUrl:\"" + AdminUrl + "\",Phone:\"" + Phone + "\"}" + ")";
            return Content(result);
        }
    }
}
{% endhighlight %}

`注意，关键在于接收一个callback参数，返回的是 callback(JSON对象)形式。`
