---
layout: post
title: "100行CSharp代码利用dynamic写个DSL(特定领域语言)"
description: "100行CSharp代码利用dynamic写个DSL(特定领域语言)构建Xml，TinyDSL.Xml。"
category: CLR
tags: [dynamic]
---
{% include JB/setup %}

最近看<a href="https://www.amazon.cn/gp/product/B00P8VZ8T4/ref=as_li_ss_tl?ie=UTF8&camp=536&creative=3132&creativeASIN=B00P8VZ8T4&linkCode=as2&tag=personball-23">CLR via C#(第4版)</a><img src="http://ir-cn.amazon-adsystem.com/e/ir?t=personball-23&l=as2&o=28&a=B00P8VZ8T4" width="1" height="1" border="0" alt="" style="border:none !important; margin:0px !important;" />  
读到第五章末尾`dynamic基元类型`时，看了下作者的一个利用dynamic动态调用string类型的Contains方法（静态方法）的实现，突然发现这个不就是Ruby的`method missing`么！虽然当时已经夜深，仍忍不住起来试试，写了个利用Dynamic构建Xml的小Demo，非常有趣。于是有了本文。


## 所以，我当时想处理什么问题呢？

Ruby的`method missing`机制，会ruby，用过ror框架（Ruby on Rails）的肯定见识过。  
RoR框架中的数据层，可以仅从方法名称中就可以推导出所需的sql查询条件（这个方法甚至没有定义过！）。在没有任何方法实现的情况下，由ruby提供机制以在运行时处理`当我找不到那个方法时，我应该做点什么？`，即`method missing`，在其中仅通过解析方法名，就可以构造sql语句并返回正确的查询结果。  
忘了是几年前，当时应该ruby才1.9版左右，看到这个特性，感觉特别惊艳。

而，CSharp在拥有dynamic后，也可以做到类似的事情，处理sql可能略繁琐，这里以构建Xml为例。  

我想要的效果是，让类似以下的代码(控制台项目)能运行，并且返回一个Xml结构：

    var xmlWrapper = 
    (某个dynamic对象)
    .A
        .B
            .C
                .D
                    .E;//ABCDE可以是任何字符串，当然没有任何预先的方法或者属性定义

期望的结果是：
    
    <root>
    <A>
        <B>
            <C>
                <D>
                    <E />
                </D>
            </C>
        </B>
    </A>
    </root>

这个好处是什么呢？构建Xml的时候，将多余字符减少到最少！恩，程序员都是懒人。  

## Step1 首先我们需要一个dynamic

上面的变量名`xmlWrapper`揭示了，我们需要一个Wrapper，这个Wrapper提供了dynamic的运行时绑定机制。  
而且，我们观察一下期望的代码书写方式`(某个dynamic对象).A.B.C`而非`.A().B().C()`，所以我们要针对动态调用属性进行处理。  
给Wrapper起个名字叫`XmlDynamicConstructor`，于是我们先有最初的版本：

    public sealed class XmlDynamicConstructor : DynamicObject
    {
        public XElement Element { get; }
       
        public XmlDynamicConstructor(XElement element)
        {
            //初始化时构建一个XElement对象，如上面期望结果中的root节点
            Element = element;
        }

        public override bool TryGetMember(GetMemberBinder binder, out object result)
        {
            var name = binder.Name;//获取调用时的名称，如上面的A
            var child = new XElement(name);
            child.Add(Element);
            //为了能继续“链式”调用，必须将返回结果设为一个Wrapper，
            //这里以节点A作为下一步处理的“根节点”
            result = new XmlDynamicConstructor(child);
            return true;
        }
    }

原理很简单，dynamic调用时，我们知道A这个属性或是A()方法并未定义过，所以在Wrapper中进行处理，将A构造为Xml的一个节点，然后继续返回包含A的Wrapper做下一步处理，又能在A节点中以同样的方式加入B节点，如此，一直继续下去。。。  
最后，我们尝试输出xmlWrapper的Element对象:  

    <E>
        <D>
            <C>
                <B>
                    <A>
                        <root />
                    </A>
                </B>
            </C>
        </D>
    </E>

额，为啥反了。。。  
原来是疏忽了，应该将`child.Add(Element);`修正为`Element.Add(child)`，再运行：

    <E />

勒个去，剩一个节点了？好吧，xmlWrapper这个变量，在每次调用时都被替换为子节点的引用了。  

由于`调用的执行是按栈的方式`进行的，貌似这个问题不好处理。我们暂且保留下root那个XElement对象的引用，输出root节点看看：  
修改`Main()`如下：  

    var root = new XElement("root");
    var xmlWrapper =
        ((dynamic)new XmlDynamicConstructor(root))
        .A
            .B
                .C
                    .D
                        .E;

    Console.WriteLine(root);
    Console.ReadLine();

输出：  

    <root>
    <A>
        <B>
            <C>
                <D>
                    <E />
                </D>
            </C>
        </B>
    </A>
    </root>

OK，对了！但是每次都要保留根节点，比较心塞，怎么解决这个问题？Wrapper内再加点东西？  

## Step2 改良，传递根节点引用，重写xmlWrapper的ToString

首先，从上面的结果来看，整个Xml的构建是没问题的，就是输出方式有点难看，我们分析分析。  
从调用方式上看，xmlWrapper虽然事实上每次调用后都会被替换为子节点的Wrapper，但是我更期望能直接Console.Write输出从root节点开始的整个结构。所以我们必须能在任何一个节点上都能找到根节点。  

改进下`XmlDynamicConstructor`，如下：

    public sealed class XmlDynamicConstructor : DynamicObject
    {
        public XElement Element { get; }
        //调用任一节点Wapper的RootElement时，实际返回的是root的Element
        public XElement RootElement { get { return _root.Element; } }

        private XmlDynamicConstructor _root;//保存root节点的Wrapper

        public XmlDynamicConstructor(XElement element)
        {
            //初始化时构建一个XElement对象，如上面期望结果中的root节点
            Element = element;
            _root = this;
        }

        public XmlDynamicConstructor(XElement element, XmlDynamicConstructor root)
        {
            Element = element;
            _root = root;
        }

        public override bool TryGetMember(GetMemberBinder binder, out object result)
        {
            var name = binder.Name;//获取调用时的名称，如上面的A
            var child = new XElement(name);
            Element.Add(child);
            //为了能继续“链式”调用，必须将返回结果设为一个Wrapper，
            //这里以节点A作为下一步处理的“根节点”
            result = new XmlDynamicConstructor(child, _root);//传递 _root
            return true;
        }

        public override string ToString()
        {
            return RootElement.ToString();//可直接用Console.Write输出xmlWrapper对象
        }
    }

改下调用代码，如下：

    var xmlWrapper =
        ((dynamic)new XmlDynamicConstructor(new XElement("root")))
        .A
            .B
                .C
                    .D
                        .E;

    Console.WriteLine(xmlWrapper);

输出，符合预期！调用方式也比前面要*人性化*很多！

## Step3 不能光会增加子节点，兄弟节点呢？

观察上面的调用方式，CSharp中的方法调用、属性调用的`点符号`已经被使用于`增加子节点`了，那么我们要换个符号用于`增加兄弟节点`，就用`加号`吧。  
在`XmlDynamicConstructor`敲个`override`看看，看来看去只有`TryBinaryOperation`比较像。  

    public override bool TryBinaryOperation(
        BinaryOperationBinder binder, object arg, out object result)
    {
        if (!(arg is XmlDynamicConstructor))
        {
            throw new ArgumentException(
                "operatiing object should be type of XmlDynamicConstructor!");
        }

        dynamic brother = arg;

        //AddChecked是指执行溢出检测的加法运算
        if (binder.Operation == ExpressionType.Add
            || binder.Operation == ExpressionType.AddChecked)
        {
            Element.AddAfterSelf(brother.RootElement);
        }
        else
        {
            throw new NotImplementedException();
        }

        result = this;
        return true;
    }

依然很简单的代码，试试看：

    static void Main(string[] args)
    {
        var xmlWrapper =
            ((dynamic) 
            new XmlDynamicConstructor(new XElement("root")))
                .A
                    .B
                        .C
                            .D
                                .E
                                +
                                ((dynamic)
                                new XmlDynamicConstructor(
                                    new XElement("F")))
                                .G
                                    .H
                                        .I;

        Console.WriteLine(xmlWrapper);
        Console.ReadLine();
    }

输出：

    <root>
    <A>
        <B>
            <C>
                <D>
                    <E />
                    <F>
                        <G>
                            <H>
                                <I />
                            </H>
                        </G>
                    </F>
                </D>
            </C>
        </B>
    </A>
    </root>

我们可以看到节点E和节点F成兄弟节点了，并且F还带着子节点。

## Step4 继续改良，要考虑下为Xml节点添加属性了

前面我们`override`了`TryGetMember`和`TryBinaryOperation`，我们可以看到他们分别对应dynamic调用属性和运算符时的处理。那么方法呢？  
再来个`override`，发现`TryInvokeMember`比较像（不再单独演示结果）： 

    public override bool TryInvokeMember(
        InvokeMemberBinder binder, object[] args, out object result)
    {
        var name = GetName(binder.Name);
        var child = new XElement(name);

        if (args.Length > 0)
        {
            var arg = args[0];
            //一个辅助方法设置XElemnt的xml属性
            XDC.SetAttributes(child, arg);
        }

        Element.Add(child);
        result = new XmlDynamicConstructor(child, _root);
        return true;
    }

还有之前`((dynamic) new XmlDynamicConstructor(new XElement("root")))`这行比较丑，换个短点的，比如`XDC.New("root")`。

篇幅已经挺长，不再单独演示了。

## 总结

通过继承`DynamicObject`，我们可以自定义如何处理dynamic类型的运行时动态绑定。当然这肯定有一定的性能开销，但是对于某些任务，这个机制是极其方便的，甚至可以说是非常潇洒的，正因如此，Ruby的`method missing`也被誉为`Ruby程序员的梦中情人`。  

希望本文能给大家一定收获。

完整代码请见[TinyDSL.Xml](https://github.com/personball/TinyDSL)  
*完整版`XmlDynamicConstructor`大概就80多行代码，`XDC`也才20几行，文章标题上说的100行写个DSL基本达成。*
