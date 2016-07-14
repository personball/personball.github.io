---
layout: post
title: "The Little Schemer 学习笔记"
description: "《The Little Schemer》 FP编程、lisp入门必备。"
category: FP
tags: [Lisp]
---
{% include JB/setup %}

### 《The Little Schemer》 FP编程、lisp入门必备

1. 这书貌似没中文版；
2. 有英文pdf版；[完整版下载链接](http://down.51cto.com/data/671043)
3. 英文不好的，被前几页噎住的，可以先到这里看[翻译好的前言部分](http://blog.csdn.net/sedgewick/article/details/6024036)
4. 看完人家翻译好的前言，那还等什么，下面的部分连英语三级都不需要！

该书大部分内容，会在左边给你一段“代码”，右边给你详细的解释，然后从上到下，就是解释“代码”的运行过程。就跟单步调试一样的流程。过程有点像思维训练，刚开始觉得有趣，看到后来觉得枯燥，但是事实上最好多看几遍。

### 摘记一下五法十诫
`Five Laws`

>The Law of Car: 
>	
>	The primitive car is defined only for non-empty lists
>
>The Law of Cdr: 
>	
>	The primitive cdr is defined only for non-empty lists. The cdr of any non-empty list is always another list.
>
>The Law of Cons: 
>	
>	The primitive cons takes two arguments. The second argument to cons must be a list. The result is a list.
>
>The Law of Null?: 
>	
>	The primitive null? is defined only for lists.
>
>The Law of Eq?: 
>
>	The primitive eq? takes two arguments. Each must be a non-numeric atom.
>

`Ten Commandments`

The First Commandment
	
	When recurring on a list of atoms, lat, ask two questions about it : (null? lat) and else.

	When recurring on a number, n, ask two questions about it : (zero? n) and else.

	When recurring on a list of S-exp, l, ask three question about it: (null? l), (atom? (car l)), and else.

The Second  Commandment

	Use cons to build lists.

The Third  Commandment

	When building a list, describe the first typical element, and then cons it onto the natural recursion.

The Fourth  Commandment

	Always change at least one argument while recurring. 

	When recurring on a list of atoms, lat, use (cdr lat).
	
	When recurring on a number, n, use (sub1 n). And when recurring on a list of S-exp, l, use (car l) and (cdr l) if neither (null? l) noe (atom? (car l)) are true.
	
	It must be changed to be closer to termination.   
	The changing argument must be tested in the termination condition:
	
	when using cdr, test termination with null? and when using sub1, test termination with zero?

The Fifth  Commandment

	When building a value with o+, always use 0 for the value of the terminating line, for adding 0 does not change the value of an addition.
	
	When building a value with *, always use 1 for the value of the terminating line, for multiplying by 1 does not change the value of a multiplication.
	
	When building a value with cons, always consider () for the value of the terminating line.

The Sixth  Commandment

	Simplify only after the function is correct.

The Seventh  Commandment

	Recur on the subparts that are of the same nature:
	* On the sublists of a list.
	* On the subexpressions of an arithmetic expression.

The Eighth  Commandment

	Use help function to abstract from representations.

The Ninth Commandment

	Abstract common patterns with a new function
