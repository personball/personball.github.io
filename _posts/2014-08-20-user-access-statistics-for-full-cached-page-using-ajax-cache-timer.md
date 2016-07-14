---
layout: post
title: "全页缓存时，如何进行用户访问次数统计？（可防止恶意刷页面访问次数）"
description: "一个解决方案，主要处理整页缓存后，页面的访问次数统计以及防止用户恶意刷新页面的访问次数。"
category: Web开发
tags: AspNetMvc 
---
{% include JB/setup %}

### 场景以及目的

#### 场景：
如果我们开发了一个网站， 其中有一些企业页面，上面可能会有类似`访问量`，或者`人气值`之类的字段。  
那么很有可能，会遇到部分企业用户恶意刷新页面，以提高该访问量的值，对网站本身造成压力。  
同时因页面生成代价过大或者访问量提高后，为了优化，或者做某种CDN，我们很可能会对该页面进行整页缓存。  
那么如何在这两种场景下，对页面进行访问次数的统计？  
这里以AspNetMvc程序为例，给出一个简单方案。

#### 目的：

1. 当整页缓存(OutPutCache或某种CDN方案)时，进行该页面的访问次数统计；
2. 更灵活的定义用户有效访问次数（某时间段内，每ip仅算一次有效访问）。

### 解决方案：触发统计+数据暂存+定时汇总

#### 页面访问次数，最开始的处理流程可能是这样的：

1. 用户访问一个企业首页；
2. 服务器收到Http请求，进入一个控制器的Action中调用方法更新数据库中的访问次数字段；
3. 返回页面，页面上的访问次数比上一次显示的值大。

加了整页缓存后，上面的流程不再有效。  
服务器端不再重新运行一遍action中的代码。  
在页面缓存仍然有效的情况下，直接返回缓存的页面。  
这时候，我们必然需要另一个接口去触发统计的需求。  
这里要注意整页缓存后，页面上的用户登陆状态必然也需要异步加载。  
既然无论如何会触发一个ajax请求，不如直接用这个ajax请求触发页面访问次数的统计。  

#### 新的流程：

1. 用户访问一个企业首页；
2. 页面缓存有效的情况下，直接返回缓存的页面；缓存失效，则重新提取数据给出页面，但移除访问次数累加的相关代码；
3. 返回页面，页面上的访问次数不包含本次访问；
4. 浏览器加载完页面后，触发ajax去请求用户的登陆状态，同时进行访问次数的统计。

考虑到每次进行访问次数的累加都直接操作数据库的话，会造成过多的数据库io。  
我们可以先把相关数据放在cache中，然后定时处理。  
假设请求用户登陆状态的接口名为`hello`。  
当触发hello请求后，我们根据url_referer，判断hello请求来自哪个页面。  
并根据url中的参数信息，识别出是哪个企业的首页需要累加访问次数。  
同时可以关联访问者的ip，设置5分钟内该ip的多次访问在cache中只算一次。

#### 可扩展性考虑：

* 统计的触发可以不使用ajax，采用一个隐藏的img标签，其src指向独立的统计接口即可，这样对于浏览器未启用js的情况也适用。而且方便部署独立的统计服务器。
* 统计数据的暂存，可以不放到.Net内置的Cache中，转而使用分布式缓存，比如memcache。
* 定时器简单的情况下可以在web程序内使用Timer，但这样必须考虑iis回收的情况。另一种方案是结合memcache的情况下，可以写个独立的服务，定时操作memcache中暂存的数据进行汇总。

### 参考实现
这里给出一个简单实现。  
因本身项目的架构，hello接口在另一个二级域名下，ajax部分使用了jsonp：
{% highlight javascript %}
$(function () {
    $.ajax({
        url: "http://user.yourdomain.com/hello",
        dataType: "jsonp",
        success: function (json) {
            //do sth to update user info in page
        }
    })
})
{% endhighlight %}
hello 接口的后端基本实现参考[《jsonp跨域调用数据的前后台说明》](/web开发/2013/06/21/directions-about-jsonp-cross-domain-access/)。  
其中hello接口业务代码中的访问统计部分会调用如下方法(这里针对多个页面进行访问次数统计，使用正则判断url类别):
{% highlight c# %}
/// <summary>
/// 向缓存写入访问记录
/// </summary>
public static void PageViewCountRecord()
{
    //通过检查UrlReferrer和访客ip，累计浏览量，定时结算处理
    //ViewCountStatis_{ViewCountCategory}_{IP}_{PrimaryID}
    //AbsolutePath不含域名部分 如 /tuku/1234.html
    string _url = HttpContext.Current.Request.UrlReferrer.AbsolutePath;
    //类别
    int category = -1;
    Dictionary<string, int> dict = new Dictionary<string, int>();
    //类别路由
    dict.Add(Validate.UrlReg_bsite, (int)ViewCountCategory.BSite);
    dict.Add(Validate.UrlReg_tuku, (int)ViewCountCategory.Case);
    dict.Add(Validate.UrlReg_com, (int)ViewCountCategory.Com);
    dict.Add(Validate.UrlReg_des, (int)ViewCountCategory.Des);
    dict.Add(Validate.UrlReg_news, (int)ViewCountCategory.News);
    dict.Add(Validate.UrlReg_youhui, (int)ViewCountCategory.Youhui);
    dict.Add(Validate.UrlReg_tuku_img,(int)ViewCountCategory.CaseImg);
    foreach (string key in dict.Keys)
    {
        Regex tmpReg = new Regex(key, RegexOptions.IgnoreCase);
        if (tmpReg.IsMatch(_url))
        {
            category = dict[key];
            break;
        }
    }
    if (category > -1)
    {
        int _pid = 0;
        Regex digit = new Regex(@"\d+");
        //从url中取第一个匹配项（主键）
        Match m = digit.Match(_url);
        if (m != null)
        {
            int.TryParse(m.Value, out _pid);
        }
        if (_pid > 0)
        {
            string IP = IPTool.getIPAddress();
            //设置cache键名，键名前缀+类别+IP+对象主键
            string CacheKey = string.Format("{0}{1}_{2}_{3}", StatisticService.ViewCountCacheKeyPre, category, IP, _pid);
            //操作cache
            if (CacheService.HttpRunTimeCache_Get(CacheKey) == null)
            {
                CacheService.HttpRunTimeCache_Add(CacheKey, 1, ViewCountDelayMins * 2);
            }
        }
    }
}
{% endhighlight %}
简单设置定时器，在Global中：
{% highlight c# %}
protected void Application_Start()
{
    AreaRegistration.RegisterAllAreas();
    RegisterGlobalFilters(GlobalFilters.Filters);
    RegisterRoutes(RouteTable.Routes);
    MvcHandler.DisableMvcResponseHeader = true;
    //根据配置启用访问统计
    if (ConfigurationManager.AppSettings["ViewCountIsOpen"]=="1")
    {
        System.Timers.Timer myTimer = new System.Timers.Timer(int.Parse(ConfigurationManager.AppSettings["ViewCountDelayMins"])*60000);
        myTimer.Elapsed += myTimer_Elapsed;
        myTimer.Enabled = true;
        myTimer.AutoReset = true;
    }
}

void myTimer_Elapsed(object sender, ElapsedEventArgs e)
{
    StatisticService.PageViewCountStatis();//定时调用统计汇总
}

protected void Application_End()
{
    //下面的代码是关键，可解决IIS应用程序池自动回收的问题
    Thread.Sleep(1000);
    //这里设置你的web地址，
    //可以随便指向你的任意一个aspx页面甚至不存在的页面，
    //目的是要激发Application_Start
    string url = "http://user.yourdomain.com";
    HttpWebRequest myHttpWebRequest = (HttpWebRequest)WebRequest.Create(url);
    HttpWebResponse myHttpWebResponse = (HttpWebResponse)myHttpWebRequest.GetResponse();
    Stream receiveStream = myHttpWebResponse.GetResponseStream();//得到回写的字节流
}
{% endhighlight %}

统计汇总的方法如下(隐去了数据库表名)：
{% highlight c# %}
/// <summary>
/// 统计缓存的访问记录 
/// 缓存键名格式 "ViewCountStatis_{ViewCountCategory}_{IP}_{PrimaryID}"
/// </summary>
public static void PageViewCountStatis()
{
    //HttpContext.Current.Cache;由定时器触发的方法，无法访问HttpContext
    Cache _cache = HttpRuntime.Cache; 
    List<string> keys = GetKeys(_cache,ViewCountCacheKeyPre);
    //具体处理逻辑，访问统计涉及的需要更新的对应数据库表
    string[] tables = new string[7] { "table1",
                                  "table2",
                                  "table3",
                                  "table4",
                                  "table5",
                                  "table5",
                                  "table1"};//和ViewCountCategory的定义对应
    string[] whrKey = new string[7] { "CaseID",//案例编号
                                   "Id",//工地编号
                                   "ID",//设计师编号
                                   "Id",//公司编号
                                   "ID",//文章编号
                                   "ID",
    "CaseID"};//和ViewCountCategory的定义对应,编号对应的数据库列名
    //统计
    Dictionary<string, int> _dict = new Dictionary<string, int>();
    for (int i = 0; i < tables.Length; i++)
    {
        foreach (string key in keys.Where(k => k.StartsWith(ViewCountCacheKeyPre + i + "_")))
        {
            _cache.Remove(key);
            string[] strArr = key.Split('_');
            if (strArr.Length == 4)
            {
                int CaseID = 0;
                int.TryParse(strArr[3], out CaseID);
                if (CaseID > 0)
                {
                    string dictKey = i + "_" + CaseID;
                    if (_dict.ContainsKey(dictKey))
                    {
                        //++
                        _dict[dictKey]++;
                    }
                    else
                    {
                        _dict.Add(dictKey,1);
                    }
                }
            }
        }
    }
    //更新
    for (int i = 0; i < tables.Length; i++)
    {
        IList<string> _k=_dict.Keys.Where(k=>k.StartsWith(i+"_")).ToList();
        if (_k!=null&&_k.Count>0)
        {
            foreach (string item in _k)
            {
                int _id = 0;
                int.TryParse(item.Split('_')[1], out _id);
                if (_id > 0)
                {
                    string sql = " Update " + tables[i] 
                    + " Set ViewCount=ViewCount + " + _dict[item] 
                    + " Where " + whrKey[i] + "=" + _id;
                    DataSet ds=DataSqlServer.Default.FromSql(sql).ToDataSet();
                }
            }
        }
    }
}
{% endhighlight %}




