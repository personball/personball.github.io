---
layout: post
title: "Asp.net Mvc 复杂类型模型绑定之列表属性绑定方法及注意点"
description: "表单多值提交，checkboxlist 多选"
category: web开发
tags: AspNetMvc ModelBinder
---
{% include JB/setup %}

模型绑定的功能说明和表单键名的约定请见：  
[ASP.NET MVC 模型绑定的功能和问题](http://msdn.microsoft.com/zh-cn/magazine/hh781022.aspx)

本文记录几个注意点，请先观察示例代码。

###模型

    public class DesignerViewModel
    {
        //其他基本属性
        ...

        /// <summary>
        /// 设计风格
        /// </summary>
        [DisplayName("设计风格")]
        [Required(ErrorMessage = "请选择至少一个设计风格")]
        public List<CategoryStyle> CaseStyles { get; set; } 

        //CategoryStyle 仅含一个CategoryStyleID属性和Name属性
    }

###控制器

    public ActionResult Add()
    {
        ViewBag.CaseStylesSelect = styleRepo.GetAll();
        return View();
    }
    public ActionResult Add(DesignerViewModel model)
    {
        if (ModelState.IsValid)
        {
            //do sth 
    	}
        ViewBag.CaseStylesSelect = styleRepo.GetAll();
        return View(model);
    }

###视图

    @{
        List<CategoryStyle> styles = (List<CategoryStyle>)ViewBag.CaseStylesSelect;
        for (int i = 0; i < styles.Count(); i++)
        {
            <span class="col-sm-3">
                <input type="checkbox"
                       id="CaseStyles[@i].CategoryStyleId"
                       name="CaseStyles[@i].CategoryStyleId"
                       value="@(styles[i].CategoryStyleId)"
                       @((Model != null && Model.CaseStyles.Any(c => c.CategoryStyleId == styles[i].CategoryStyleId)) ? "checked" : "") />
                <input type="hidden" name="CaseStyles[@i].CategoryStyleId" value="0" />
                <label for="CaseStyles[@i].CategoryStyleId">@(styles[i].Name)</label>
            </span>
        }
    }

###注意点：

1. 提供默认值的hidden不能省；
2. 提供默认值的hidden不能放在checkbox之前；
3. 提供默认值的hidden的值必须和绑定对象的属性类型匹配。

关于第一点，按模型绑定的约定，这里要求name属性必须为*CaseStyles[0].CategoryStyleId*形式，但是这个索引很关键，提交的时候必须连续。
如果我们不提供hidden默认值，那么浏览器在提交checkbox的时候，只会提交选中的项（这也是为什么Html.Checkbox辅助方法会生成一个默认值为false的hidden，除非绑定的时候属性是可空类型，否则会抛异常），那么你会发现绑定到模型上的，只有从索引0开始的连续几项，如果你没选中第0项，甚至后面的都无法绑定上去。所以必须提供hidden默认值以提交连续的*CaseStyles[i].CategoryStyleId*。

第二点，如果hidden放在checkbox之前，提交表单的时候也会看到hidden的键值对在同名的checkbox之前，绑定的时候会使用前面这个健值对，而忽略后面这个同名键值对。这个估计是模型绑定在遇到表单同名键值对时候的默认行为。

第三点，这里我要绑定的是一个id，是int型，一开始我考虑到Html.CheckBox的情况，直接使用了一个值为false的hidden，发现绑定有异常，改为同为int的0即可。



###参考资料

[ASP.NET MVC 模型绑定的功能和问题](http://msdn.microsoft.com/zh-cn/magazine/hh781022.aspx)

