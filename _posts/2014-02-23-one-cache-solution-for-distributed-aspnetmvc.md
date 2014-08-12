---
layout: post
title: "AspNetMvc分布式缓存方案"
description: "AspNetMvc的一个分布式缓存方案"
category: Web开发
tags: [AspNetMvc]
---
{% include JB/setup %}

###首先，认识一下.Net的Cache组件
在web开发过程中，刚开始，我们可能会这么使用缓存：

{% highlight C# %}
//添加
HttpContext.Cache.Add(key,
                     value,
                     null,
                     DateTime.Now.AddMinutes(min),
                     System.Web.Caching.Cache.NoSlidingExpiration,
                     System.Web.Caching.CacheItemPriority.Normal, null);
//获取
object obj = HttpContext.Cache["key"]; 
{% endhighlight %}

有一回，我想缓存一些东西到Cache里，然后定期处理，于是在Global.asax中的Application_Start()方法中写了个Timer，去访问Cache

{% highlight C# %}
HttpContext.Cache["key"];//HttpContext空引用错误
{% endhighlight %}

HttpContext是http请求的上下文对象，在Timer这种定时处理的逻辑中，是不存在http上下文的，那要如何访问Cache？
问度娘，发现了[HttpContext.Current.Cache&&HttpRuntime.Cache](http://www.cnblogs.com/McJeremy/archive/2008/12/01/1344660.html)

原来HttpContext.Current.Cache，HttpRuntime.Cache是同一个对象。 
那么，在使用Cache时我们可以直接使用HttpRuntime.Cache。 
但是，HttpRuntime.Cache是存在于单台web服务器的内存中的本机缓存，不利于水平扩展，需要替代者。

###进入正题，分布式缓存Memcache

这个替代者就是Memcache
[.Net使用Memcache](/web开发/2014/02/19/memcache-client-for-dotnet/)

使用MemCache固然很好，但是一开始没有这个资源去额外配置一个MemCache，或者网站规模还没到玩集群的时候，怎么从代码上去方便的切换这个状态呢，不如封装下Cache操作。

{% highlight C# %}
using Enyim.Caching;
using Enyim.Caching.Memcached;
using System;
using System.Configuration;
using System.Web;
namespace wCacheService
{
    public class CacheHelper
    {
        /// <summary>
        /// CacheHelper的配置信息
        /// </summary>
        public static CacheHelperSection config = (CacheHelperSection)ConfigurationManager.GetSection("CacheHelperSection");
        /// <summary>
        /// 读取缓存
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public static object Get(string key)
        {
            if (config.IsUseMemCache)
            {
                key = config.MemCacheKeyPre + key;
                MemcachedClient mc = Singleton_MemCacheClient.GetInstance();
                return mc.Get(key);
            }
            else
            {
                return HttpRunTimeCache_Get(key);
            }
        }
        /// <summary>
        /// 添加缓存,注意value不可以是IList类型
        /// </summary>
        /// <param name="key"></param>
        /// <param name="value"></param>
        /// <param name="min"></param>
        public static void Add(string key, object value, int min)
        {
            if (!string.IsNullOrEmpty(key) && value != null && min > 0)
            {
                if (config.IsUseMemCache)
                {
                    key = config.MemCacheKeyPre + key;
                    MemcachedClient mc = Singleton_MemCacheClient.GetInstance();
                    mc.Store(StoreMode.Set, key, value, DateTime.Now.AddMinutes(min));
                }
                else
                {
                    HttpRunTimeCache_Add(key, value, min);
                }
            }
        }
        /// <summary>
        /// 清理缓存
        /// </summary>
        /// <param name="key"></param>
        public static void Remove(string key)
        {
            if (config.IsUseMemCache)
            {
                key = config.MemCacheKeyPre + key;
                MemcachedClient mc = Singleton_MemCacheClient.GetInstance();
                mc.Remove(key);
            }
            else
            {
                HttpRunTimeCache_Remove(key);
            }
        }
        #region asp.net原生缓存
        /// <summary>
        /// 原生的.Net缓存组件的操作
        /// </summary>
        /// <param name="key"></param>
        /// <returns></returns>
        public static object HttpRunTimeCache_Get(string key)
        {
            return HttpRuntime.Cache[key];
        }
        /// <summary>
        /// 原生的.Net缓存组件的操作
        /// </summary>
        /// <param name="key"></param>
        /// <param name="value"></param>
        /// <param name="min"></param>
        public static void HttpRunTimeCache_Add(string key, object value, int min)
        {
            HttpRuntime.Cache.Add(key,
                             value,
                             null,
                             DateTime.Now.AddMinutes(min),
                             System.Web.Caching.Cache.NoSlidingExpiration,
                             System.Web.Caching.CacheItemPriority.Normal, null);
        }
        /// <summary>
        /// 原生的.Net缓存组件的操作
        /// </summary>
        /// <param name="key"></param>
        public static void HttpRunTimeCache_Remove(string key)
        {
            HttpRuntime.Cache.Remove(key);
        }
        #endregion
    }
    /// <summary>
    /// 单件模式 memcache client
    /// </summary>
    public class Singleton_MemCacheClient
    {
        private static MemcachedClient _mc;
        private static object _lock = new object();
        private Singleton_MemCacheClient() { }
        public static MemcachedClient GetInstance()
        {
            if (_mc == null)
            {
                lock (_lock)
                {
                    _mc = new MemcachedClient();
                }
            }
            return _mc;
        }
    }
    /// <summary>
    /// CacheHelper配置类
    /// </summary>
    public class CacheHelperSection : ConfigurationSection
    {
        public CacheHelperSection() { }
        [ConfigurationProperty("MemCacheKeyPre", DefaultValue = "")]
        public string MemCacheKeyPre
        {
            get
            {
                return (string)this["MemCacheKeyPre"];
            }
            set
            {
                this["MemCacheKeyPre"] = value;
            }
        }
        [ConfigurationProperty("IsUseMemCache", DefaultValue = "false")]
        public bool IsUseMemCache
        {
            get
            {
                return (bool)this["IsUseMemCache"];
            }
            set
            {
                this["IsUseMemCache"] = value;
            }
        }
    }
}

{% endhighlight %}

配置方式：

{% highlight xml %}
 <configSections>
    <section name="CacheHelperSection" type="wCacheService.CacheHelper,wCacheService, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null"/>
  </configSections>
  <CacheHelperSection MemCacheKeyPre="" IsUseMemCache="false" />
{% endhighlight %}

如此，码代码的时候可以兼顾分布式缓存，日后配置了Memcache就设置IsUseMemCache为true即可。当然为了多一种选择，这里也开放了调用.net原生缓存的方法。 

__注意，使用memcache时，需要配置memcache相关参数，详见 [一个.Net用Memcache Client库](/web开发/2014/02/19/memcache-client-for-dotnet/)__

