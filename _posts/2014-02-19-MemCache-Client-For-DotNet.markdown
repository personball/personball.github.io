---
layout: post
title: "推荐一个.Net用Memcache Client库"
categories: Mvc网站开发 可扩展性
tags: AspNet Mvc MemCacheClient
---

#类库信息
##类库名：
EnyimMemcached
##Github地址：
https://github.com/enyim/EnyimMemcached [Click]
[Click]:https://github.com/enyim/EnyimMemcached
##命名空间：
Enyim.Caching
##获取方法：
直接git clone源代码 或 VS使用 Nuget 搜索Enyim，找到EnyimMemcached
##配置方法：
{% highlight xml %}
 <configSections>
    <sectionGroup name="enyim.com">
      <section name="memcached" type="Enyim.Caching.Configuration.MemcachedClientSection, Enyim.Caching" />
    </sectionGroup>
    <section name="memcached" type="Enyim.Caching.Configuration.MemcachedClientSection, Enyim.Caching" />
 </configSections>
  <enyim.com>
    <memcached>
      <servers>
        <!-- put your own server(s) here-->
        <add address="192.168.1.135" port="11211" />
      </servers>
      <socketPool minPoolSize="10" maxPoolSize="100" connectionTimeout="00:00:10" deadTimeout="00:02:00" />
    </memcached>
  </enyim.com>
  <memcached>
    <keyTransformer type="Enyim.Caching.Memcached.TigerHashKeyTransformer, Enyim.Caching" />
    <servers>
      <add address="192.168.1.135" port="11211" />
    </servers>
    <socketPool minPoolSize="2" maxPoolSize="100" connectionTimeout="00:00:10" deadTimeout="00:02:00" />
  </memcached>
{% endhighlight %}
##用例：
{% highlight C# %}
MemcachedClient mc = new MemcachedClient();
mc.Store(StoreMode.Set, key, value, DateTime.Now.AddMinutes(min));
mc.Get(key);
mc.Remove(key);
{% endhighlight %}

Store写入，Get读取，Remove删除  

* * *
#可能遇到的问题

##1.生成MemecacheClient对象耗时较长
##解决方法：
使用单件模式重新封装下

{% highlight C# %}
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
{% endhighlight %}

##2.是否使用Cas模式？
##解决方法：
如果只是用来做纯粹的数据缓存，可以不考虑cas。对于CAS，个人认为cas主要是对已存的内容进行修改的时候，为了解决一致性问题而引入的特性。说白了就是原子操作，操作时会携带版本号。纯粹的数据缓存只关心数据是否已缓存或者是否已失效，从写入到失效，之间没有改写的情况。
