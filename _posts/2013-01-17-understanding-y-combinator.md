---
layout: post
title: "对于Y组合子的理解"
description: "对于Y组合子的理解"
category: FP
tags: [Lisp]
---
{% include JB/setup %}

#### 前言
这周闲来无事，狠狠研究了一把lambda演算，不可避免的涉及到对Y组合子的理解。因为是从“解决匿名递归函数 的定义” 引起的，看了网上很多帖子，感觉绕来绕去容易被搞糊涂。今天又翻了一下wiki，算是真正理解了，特地在此提炼一下。

#### 第一件事：我们要定义f （f指一个匿名递归函数，比如阶乘 power(n)）
为了定义power(n)，我们先定义一个函数：

	fact(n)=lambda n . n*fact(n-1)
	//这个定义是不能通过的,因为等号右侧的fact未定义，即：我们不能直接描述fact！！

那么，间接的，我们描述一个以 fact作为其中一个函数特例的高阶函数（即以函数为参数）

	G(x)(n)=lambda x n . n* x(n -1)  //这个定义是合法的。OK

Y组合字的作用是：

>我们应用Y组合子，即可得到合法定义的power。而避免直接定义fact。

我偷个懒，不具体推导，下面直接看Wiki中的例子（这里Y组合子即为fix()）：

>####例子
>考虑阶乘函数（使用邱奇数）。平常的递归数学等式
>
>	fact(n) = if n=0 then 1 else n * fact(n-1)
>
>可以用 lambda 演算把这个递归的一个“单一步骤”表达为
>
>	F = λf. λx. (ISZERO x) 1 (MULT x (f (PRED x)))
>
>这里的 "f" 是给阶乘函数的占位参数，用于传递给自身。 函数 F 进行求值递归公式中的一个单一步骤。 应用 fix 算子得到
>
>	fix(F)(n) = F(fix(F))(n)
>	fix(F)(n) = λx. (ISZERO x) 1 (MULT x (fix(F) (PRED x)))(n)
>	fix(F)(n) = (ISZERO n) 1 (MULT n (fix(F) (PRED n)))
>
>我们可以简写 fix(F) 为 fact，得到
>
>	fact(n) = (ISZERO n) 1 (MULT n (fact(PRED n)))
>
>所以我们见到了不动点算子确实把我们的非递归的“阶乘步骤”函数转换成满足预期等式的递归函数。

***
关键在于：F 是定义好的，fix 是定义好的 
	
	fix（F）=F(fix(F))(n)
		=(ISZERO n) 1 (MULT n (fix(F) (PRED n)))//即是目标函数

**原先同样形式中的fact为未定义，而现在这个形式中的fix(F) 却是已经定义了的！**
F的定义：

	F = λf. λx. (ISZERO x) 1 (MULT x (f (PRED x)))

fix即Y组合子，定义:
	
	Y = lambda y . (lambda x . y ( x x) ) (lambda x . y ( x x ) )

感谢：[http://blog.csdn.net/pongba/article/details/1336028](http://blog.csdn.net/pongba/article/details/1336028)  
还有：[http://blog.csdn.net/g9yuayon](http://blog.csdn.net/g9yuayon)  
wiki：[http://zh.wikipedia.org/wiki/不动点组合子](http://zh.wikipedia.org/wiki/不动点组合子)
