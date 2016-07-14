---
layout: post
title: "ConfigurationSection：让web.config配置更有条理"
description: "使用ConfigurationSection组织配置文件"
category: Web开发
tags: [AspNetMvc]
---
{% include JB/setup %}

`本文针对新手`

使用Web.config的配置信息，一般都习惯于使用
	
	ConfigurationManager.AppSettings["ConfigKey"]

当程序不断迭代，开发维护了一段时间之后，是不是发现Web.config文件中的配置信息堆砌了一大堆？

{% highlight xml %}
 <appSettings>
    <add key="webpages:Version" value="1.0.0.0" />
    <add key="ClientValidationEnabled" value="true" />
    <add key="UnobtrusiveJavaScriptEnabled" value="true" />
    <add key="ConfigKeya" value="aaa" />
    <add key="ConfigKeyb" value="bbb" />
    <add key="ConfigKeyc" value="ccc" />
    <add key="ConfigKeyd" value="ddd" />
    <!-- xyz -->
    <add key="ConfigKeye" value="eee" />
    <!-- xyz -->
    <add key="ConfigKeyf" value="fff" />
    <!-- xyz -->
    <add key="ConfigKeyg" value="ggg" />
    <!-- xyz -->
    <add key="ConfigKeyh" value="hhh" />
    ...
  </appSettings>
{% endhighlight %}

是不是在引入第三方库的时候，发现他们的配置节很独立很清楚？

***

### 先来看看完成后的配置方式

{% highlight xml %}
  <configSections>
    <section name="EmailHelperSection" type="wUtils.EmailHelperSection, wUtils, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null"  />
  </configSections>
  <EmailHelperSection Smtp_Host="" Smtp_Account="" Smtp_Pwd="" />
{% endhighlight %}

### 如何读取这种配置信息？
首先需要写这个类：wUtils.EmailHelperSection，wUtils是命名空间

{% highlight C# %}
namespace wUtils
{
    /// <summary>
    /// EmailHelper配置类
    /// </summary>
    public sealed class EmailHelperSection : ConfigurationSection
    {
        public EmailHelperSection() { }
        [ConfigurationProperty("Smtp_Host", DefaultValue = "")]
        public string Smtp_Host
        {
            get
            {
                return (string)this["Smtp_Host"];
            }
            set
            {
                this["Smtp_Host"] = value;
            }
        }
        [ConfigurationProperty("Smtp_Account", DefaultValue = "")]
        public string Smtp_Account
        {
            get
            {
                return (string)this["Smtp_Account"];
            }
            set
            {
                this["Smtp_Account"] = value;
            }
        }
        [ConfigurationProperty("Smtp_Pwd", DefaultValue = "")]
        public string Smtp_Pwd
        {
            get
            {
                return (string)this["Smtp_Pwd"];
            }
            set
            {
                this["Smtp_Pwd"] = value;
            }
        }
    }
}
{% endhighlight %}

### 然后是使用配置信息的方式

{% highlight C# %}
 EmailHelperSection config = (EmailHelperSection)ConfigurationManager.GetSection("EmailHelperSection");
 string email = config.Smtp_Account;
 string password = config.Smtp_Pwd;
{% endhighlight %}

### Over
