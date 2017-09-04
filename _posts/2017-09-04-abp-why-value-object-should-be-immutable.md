---
layout: post
title: "Abp系列——为什么值对象必须设计成不可变的"
description: "Abp系列——领域层代码设计:为什么值对象必须设计成不可变的，什么是不可变性。"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

这篇是之前翻备忘录发现漏了的，前阵子刚好同事又提及过这个问题，这里补上。  
*本文重点在于理解什么是值对象的不可变性。*

## Abp的ValueObject以及EF的ComplexType

Abp中对应DDD概念的值对象有个基类：`ValueObject<T>`。  
这个基类默认重写了`Equals`，`GetHashCode`等用于比较两个实例是否相等的方法和重载了`==`，`!=`操作符。  
在构建一些比较复杂的实体时，我们可以把属于同一个概念的多个属性或字段封装成一个值对象。  
这个值对象在实体中又对应EntityFramework的复杂类型`ComplexType`。  
所以在内存中或者在数据库中，这个对象都可以作为一个整体被赋值、复制或`修改`？  

如果不加控制，修改很有可能发生，但是，`这类对象，必须设计成不可变的！不能被修改`！

## 用两个测试用例举个反例

还是`Personball.Demo`解决方案。  
*这已经是我的御用示例项目了，我本地git库保留master分支为当初下载的原始zip文件解压后的源码，新开一篇文章就建个新分支折腾。*

我们假设一个场景：

    我们有一个创业者A的住址信息，他要开办一家公司A，由于资源不足，他希望把自己的住址登记成公司的办公地址。

我们在`Personball.Demo.Core`项目根目录加两个值对象`Address1`和`Address2`：  

    public class Address1 : ValueObject<Address1>
    {
        public string RegionCode { get; set; }

        public string Street { get; set; }
    }

    public class Address2 : ValueObject<Address2>
    {
        protected Address2()
        {
            //for orm
        }

        //只能通过ctor构造
        public Address2(string regionCode, string street)
        {
            RegionCode = regionCode;
            Street = street;
        }

        //setter 被保护起来了
        public string RegionCode { get; protected set; }
        //setter 被保护起来了
        public string Street { get; protected set; }
    }

新建`Creators`目录，加实体`Creator`:  

    public class Creator : Entity
    {
        public Address1 HouseAddress1 { get; set; }

        public Address2 HouseAddress2 { get; set; }
    }

新建`Companies`目录，加实体`Company`:  

    public class Company : Entity
    {
        public string Name { get; set; }

        public Address1 OfficeAddress1 { get; set; }

        public Address2 OfficeAddress2 { get; set; }
    }

在`Personball.Demo.Tests`项目中新建目录`Companies`加测试文件`Company_Tests`。  

*如果`测试资源管理器`无法发现单元测试用例，可以删掉临时目录`%TEMP%\VisualStudioTestExplorerExtensions`，再重启VS即可。*  

### 第一个测试用例：  

    [Fact]
    public void HouseAddress1_Should_Not_Be_Modified1()
    {
        var creatorA = new Creator
        {
            HouseAddress1 = new Address1
            {
                RegionCode = "100100",
                Street = "xxxx路xxxx号101。"
            },
            HouseAddress2 = new Address2("100100", "xxxx路xxxx号101。")
        };

        var companyA = new Company
        {
            Name = "xxx初创公司",
            //公司地址用A的住址，合情合理
            OfficeAddress1 = creatorA.HouseAddress1,
            OfficeAddress2 = creatorA.HouseAddress2
        };

        //迭代N次后，可能会有这种需求（办公地址后面追加个公司名称）
        companyA.OfficeAddress1.Street += companyA.Name;

        //断言失败，creatorA.HouseAddress1.Street已被修改！
        //creatorA.HouseAddress1.Street.ShouldBe("xxxx路xxxx号101。");
        
        //是同一个实例！
        creatorA.HouseAddress1.ShouldBeSameAs(companyA.OfficeAddress1);
    }

不要吐槽上面这个`生造的需求`，“办公地址后面加个公司名称”，只是表达这个意思：  

    我们很可能在维护了几个月代码后，不经意间，会将一个实体的一个值对象赋值给另一个实体，另一个实体又紧接着修改了自己的这个值对象中的某个属性。

也可能加了这行代码“办公地址后面加个公司名称”的已经是另一个人了。  
这个问题如果发生了，很难定位排查。  
那么如何防止这种情况发生？  

### 第二个测试用例：  

    [Fact]
    public void HouseAddress2_Should_Not_Be_Modified2()
    {
        var creatorA = new Creator
        {
            HouseAddress1 = new Address1
            {
                RegionCode = "100100",
                Street = "xxxx路xxxx号101。"
            },
            HouseAddress2 = new Address2("100100", "xxxx路xxxx号101。")
        };

        var companyA = new Company
        {
            Name = "xxx初创公司",
            OfficeAddress1 = creatorA.HouseAddress1,
            OfficeAddress2 = creatorA.HouseAddress2 //不经意就会这么干
        };

        //迭代N次后，不小心可能会这么干
        //编译器报错，setter无法访问！
        //companyA.OfficeAddress2.Street += companyA.Name;
        
        //想改就必须new一个！
        companyA.OfficeAddress2 = 
            new Address2(companyA.OfficeAddress2.RegionCode, 
                        companyA.OfficeAddress2.Street + companyA.Name);
        
        //断言通过，creatorA.HouseAddress2.Street不受影响！
        creatorA.HouseAddress2.Street.ShouldBe("xxxx路xxxx号101。");
        
        //不同实例！
        creatorA.HouseAddress2.ShouldNotBeSameAs(companyA.OfficeAddress2);
    }

当我们用了`Address2`，其属性的setter都被protected限制了从外部直接赋值时，`companyA.OfficeAddress2.Street`不能被直接修改了！  
想修改它时，必须new一个新实例！这时候，对`creatorA.HouseAddress2`自然是没有影响的。  
这并不是特别高深的原理（很基础的OOP知识点），但是能从根本上预防上述问题。  

## 总结

值对象必须被设计成不可变的，当你（或者其他人）想修改它时，必须new一个新实例！  

值对象必须被设计成不可变的，当你（或者其他人）想修改它时，必须new一个新实例！  

值对象必须被设计成不可变的，当你（或者其他人）想修改它时，必须new一个新实例！  

重要的事说三遍，刚才说了预防问题的原理很简单，这个导致问题的原理其实也很简单。  
就是OOP编程语言，其主要类型都是引用类型，变量hold的大多时候都是一个地址。  
很多时候都是地址传来传去，一个不注意，修改对象的影响范围是在你预料之外的。  
*因此，OOP语言基本都有限制可访问性的关键字（基于类的铁定有，基于原型的没仔细研究过，不确定）*

话说回来，如果有几年工作经验了，却发现好多语言层面的关键字被冷落，是不是该反思下。。。

如果说从贫血模型到充血模型是一次成长，从充血模型到重新审视语言层面提供的特性，又是一次成长。  

最后啰嗦一句，其实`实体的各种属性更应该被保护起来，限制必须通过方法去修改`。  
否则，你如何保证以后维护代码的`三个月后的自己`或者其他人会遵守之前的业务规则？  

如果是主从关系的多个实体，那就通过聚合根去约束，更复杂的，通过领域服务去约束。  

Over.
