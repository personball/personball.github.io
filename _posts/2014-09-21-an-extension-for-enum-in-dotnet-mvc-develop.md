---
layout: post
title: "如何在 Asp.net Mvc 开发过程中更好的使用Enum"
description: "枚举类型生成下拉菜单，枚举类型直接输出描述"
category: web开发
tags: AspNetMvc Enum
---
{% include JB/setup %}

### 场景描述
在web开发过程中，有时候需要根据Enum类型生成下拉菜单；  
有时候在输出枚举类型的时候，又希望输出对应的更具描述性的字符串。  
`喜欢直接用中文的请无视本文`

不多说，直接看代码。  
以下代码借鉴自http://stackoverflow.com/

`本文针对 Aspnet Mvc 4 开发而言`

### Enum定义

	using System.ComponentModel;
	namespace xxxxx.yyyyy
	{
	    public enum EN_ArticleType
	    {
	        [Description("软装家饰")]
	        RuanZhuang=1,
	     
	        [Description("家居风水")]
	        FengShui,
	     
	        [Description("装修技巧")]
	        JiQiao,
	     
	        [Description("行业动态")]
	        DongTai,
	     
	        [Description("样板美图")]
	        MeiTu,
	     
	        [Description("人才招聘")]
	        Jobs
	    }
	}

### 扩展HtmlHelper

	using System;
	using System.Collections.Generic;
	using System.ComponentModel;
	using System.Linq;
	using System.Linq.Expressions;
	using System.Web.Mvc;
	using System.Web.Mvc.Html;

	namespace xxxx.ExtendMethods
	{
	    public static class HtmlHelperUtils
	    {
	        /// <summary>
	        /// Creates the DropDown List (HTML Select Element) from LINQ 
	        /// Expression where the expression returns an Enum type.
	        /// </summary>
	        /// <typeparam name="TModel">The type of the model.</typeparam>
	        /// <typeparam name="TProperty">The type of the property.</typeparam>
	        /// <param name="htmlHelper">The HTML helper.</param>
	        /// <param name="expression">The expression.</param>
	        /// <returns></returns>
	        public static MvcHtmlString DropDownListForEnum<TModel, TProperty>(this HtmlHelper<TModel> htmlHelper,
	            Expression<Func<TModel, TProperty>> expression)
	            where TModel : class
	        {
	            return htmlHelper.DropDownListForEnum(expression, null);
	        }

	        public static MvcHtmlString DropDownListForEnum<TModel, TProperty>(this HtmlHelper<TModel> htmlHelper,
	            Expression<Func<TModel, TProperty>> expression, object htmlAttributes)
	            where TModel : class
	        {
	            TProperty value = htmlHelper.ViewData.Model == null
	                ? default(TProperty)
	                : expression.Compile()(htmlHelper.ViewData.Model);
	            string selected = value == null ? String.Empty : value.ToString();
	            if (htmlAttributes == null)
	            {
	                return htmlHelper.DropDownListFor(expression, createSelectList(expression.ReturnType, selected));
	            }
	            else
	            {
	                return htmlHelper.DropDownListFor(expression, createSelectList(expression.ReturnType, selected), htmlAttributes);
	            }
	        }

	        /// <summary>
	        /// Creates the select list.
	        /// </summary>
	        /// <param name="enumType">Type of the enum.</param>
	        /// <param name="selectedItem">The selected item.</param>
	        /// <returns></returns>
	        private static IEnumerable<SelectListItem> createSelectList(Type enumType, string selectedItem)
	        {
	            return (from object item in Enum.GetValues(enumType)
	                    let fi = enumType.GetField(item.ToString())
	                    let attribute = fi.GetCustomAttributes(typeof(DescriptionAttribute), true).FirstOrDefault()
	                    let title = attribute == null ? item.ToString() : ((DescriptionAttribute)attribute).Description
	                    select new SelectListItem
	                    {
	                        Value = item.ToString(),
	                        Text = title,
	                        Selected = selectedItem == item.ToString()
	                    }).ToList();
	        }
	    }
	}


### 视图层输出下拉菜单

	 @Html.DropDownListForEnum(model => model.Type, new { @class = "col-sm-2" })

### 扩展Enum

	using System;
	using System.ComponentModel;
	using System.Reflection;

	namespace xxxx.ExtendMethods
	{
	    public static class EnumUtils
	    {
	        public static string GetEnumDescription(this Enum value)
	        {
	            FieldInfo fi = value.GetType().GetField(value.ToString());

	            DescriptionAttribute[] attributes =
	                (DescriptionAttribute[])fi.GetCustomAttributes(
	                typeof(DescriptionAttribute),
	                false);

	            if (attributes != null &&
	                attributes.Length > 0)
	                return attributes[0].Description;
	            else
	                return value.ToString();
	        }
	    }
	}

### 输出Enum value对应的Description

	@item.Type.GetEnumDescription()  //item是实体，Type是EN_ArticleType类型的属性

### 结束
请自行尝试。
：）















