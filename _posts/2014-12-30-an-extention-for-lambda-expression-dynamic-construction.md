---
layout: post
title: "如何动态构造Lambda表达式（动态构造Lambda查询条件表达式）"
description: "如何动态构造Lambda表达式，动态构造Lambda查询条件表达式，查询条件累加，Linq。"
category: web开发
tags: AspNetMvc Lambda EntityFramework6
---
{% include JB/setup %}

###声明
本文对Lambda表达式的扩展，示例代码来源于网络。

###场景描述
web开发查询功能的时候，如果查询条件比较多，就会遇到动态组合查询条件的情况。在手写sql的情况下，我们一般会根据传入的参数，针对where部分进行sql语句的动态组装，而现在在使用EF的时候遇到这个问题，查询条件不再是以sql字符串的形式传递了，而是一个Lambda表达式，那么如何进行Lambda表达式的动态构造呢？  
虽然Lambda表达式可以声明为变量，但是要进行表达式累加，目前并没有默认的、好用且方便的方法，参考了很多资料，寻到一剂良方。

###先看看效果
先看看扩展后的使用示例：

    public ActionResult List(int? page, string where)
    {
        Expression<Func<ComArticle, bool>> Conditions = PredicateExtensions.True<ComArticle>();
        Conditions = Conditions.And(x => x.Shenhe == true && x.Company.City.CityId == CurrentCity.CityId);

        int t_id = 0;
        if (int.TryParse(where.GetByName("t"), out t_id) && t_id > 0 && t_id < 7)
        {
            var tmp = (EN_ArticleType)Enum.Parse(typeof(EN_ArticleType), t_id + "");
            Conditions = Conditions.And(x => x.Type == tmp);
        }

        var items = articleRepo.GetMany(Conditions).OrderByDescending(a => a.AddTime).ToPagedList(page ?? 1, 5);
        return View(items);
    }

如果有传入的t_id则Conditions会通过And条件累加Type筛选。  
这里的关键在于对Expression的扩展，和PredicateExtensions.True<T>()这个东西。  
那么，我们看看PredicateExtensions的代码。  

###扩展
简单的扩展，受益于ExpressionVisitor。

    public class ParameterRebinder : ExpressionVisitor
    {
        private readonly Dictionary<ParameterExpression, ParameterExpression> map;
        public ParameterRebinder(Dictionary<ParameterExpression, ParameterExpression> map)
        {
            this.map = map ?? new Dictionary<ParameterExpression, ParameterExpression>();
        }
        public static Expression ReplaceParameters(Dictionary<ParameterExpression, ParameterExpression> map, Expression exp)
        {
            return new ParameterRebinder(map).Visit(exp);
        }
        protected override Expression VisitParameter(ParameterExpression p)
        {
            ParameterExpression replacement;
            if (map.TryGetValue(p, out replacement))
            {
                p = replacement;
            }
            return base.VisitParameter(p);
        }
    }

    public static class PredicateExtensions
    {
        public static Expression<Func<T, bool>> True<T>() { return f => true; }
        public static Expression<Func<T, bool>> False<T>() { return f => false; }
        public static Expression<T> Compose<T>(this Expression<T> first, Expression<T> second, Func<Expression, Expression, Expression> merge)
        {
            // build parameter map (from parameters of second to parameters of first)  
            var map = first.Parameters.Select((f, i) => new { f, s = second.Parameters[i] }).ToDictionary(p => p.s, p => p.f);

            // replace parameters in the second lambda expression with parameters from the first  
            var secondBody = ParameterRebinder.ReplaceParameters(map, second.Body);

            // apply composition of lambda expression bodies to parameters from the first expression   
            return Expression.Lambda<T>(merge(first.Body, secondBody), first.Parameters);
        }

        public static Expression<Func<T, bool>> And<T>(this Expression<Func<T, bool>> first, Expression<Func<T, bool>> second)
        {
            return first.Compose(second, Expression.And);
        }

        public static Expression<Func<T, bool>> Or<T>(this Expression<Func<T, bool>> first, Expression<Func<T, bool>> second)
        {
            return first.Compose(second, Expression.Or);
        }
    }

ExpressionVisitor可以深入了解下。over

