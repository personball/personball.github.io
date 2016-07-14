---
layout: post
title: "使用Enum位模式进行多重状态（或权限）管理"
description: "c# 使用枚举类型位模式进行多重状态（或权限）管理，flag标记，按位或，按位与"
category: web开发
tags: AspNetMvc Enum
---
{% include JB/setup %}

### 前言

对于Enum在AspNet Mvc中的应用，我之前提到一种扩展，[如何在 Asp.net Mvc 开发过程中更好的使用Enum](http://personball.com/web开发/2014/09/21/an-extension-for-enum-in-dotnet-mvc-develop/)。这里将介绍另一种更好的使用Enum的方法。  

### Enum定义
以一个代表权限的枚举作为示例。

    [Flags]
    public enum RolePerm
    {
        View=1,
        Add=2,
        Edit=4,
        Del=8
    }

### 按位或赋值以及按位与验证
原理很简单，请自行复习位运算。简述如下：  
按位或，两个bit只要有一个是1，则置1；  
按位与，两个bit只要有一个是0，则置0。  
示例代码：  

    class Program
    {
        static void Main(string[] args)
        {
            //初始化一个空Enum
            var perm =new RolePerm();
            Console.WriteLine((int)perm);//0
            Console.WriteLine(perm.ToString());//0
            //按位或
            perm = RolePerm.View | RolePerm.Add;
            Console.WriteLine((int)perm);//3
            Console.WriteLine(perm.ToString());//View, Add
            
            //tips:在asp.net mvc 的模型绑定阶段，表单或url中的字符串“View, Add”，
            //可以被自动绑定到其对应的枚举类型参数中，请自行尝试

            //按位与，验证是否有其中一个权限
            if ((perm & RolePerm.Del)==RolePerm.Del)//false
            {
                Console.WriteLine("YES,有删除权限");
            }
            else
            {
                Console.WriteLine("NO,没有删除权限");
            }
            //按位与，验证是否有其中多个权限
            perm = perm | RolePerm.Edit;//使perm不等于待比较的pend
            var pend = RolePerm.View | RolePerm.Add;
            if ((perm & pend) == pend)//true
            {
                Console.WriteLine("YES,授权范围内");
            }
            else
            {
                Console.WriteLine("NO,不在授权范围内 ");
            }
            Console.Read();
        }
    }

上述代码以权限作为示例，同理，可以定义一个保存多种状态的枚举变量Status，以相同的方式进行状态验证。不再赘述，请自行尝试。

