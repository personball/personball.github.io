---
layout: post
title: "Abp系列——DTO入参验证使用方法及经验分享"
description: "Abp系列——DTO入参验证使用方法及经验分享，声明式的入参验证逻辑，IValidatableObject，ICustomValidate，多个DTO重用验证逻辑，OOP多态。"
category: ABP
tags: [ABP]
---
{% include JB/setup %}

>本系列目录：[Abp介绍和经验分享-目录](/abp/2017/05/31/abp-framework-series)  

## 声明式的入参验证逻辑

声明式入参验证主要使用了`System.ComponentModel.DataAnnotations`中提供的各种验证参数的Attributes，将Attribute标记到属性上，即可(这是在早期Asp.Net Mvc中就支持的写法)。  
例如：  

    public class DemoInputDto
    {
        [Required]
        public int? Value1 { get; set; }

        [Range(0, int.MaxValue)]
        public int Value2 { get; set; }

        [Required]
        public DateTime? Time1 { get; set; }

        [RegularExpression("\\d+")]
        public string RegMatchStr { get; set; }
    }

以前都是配合Mvc控制器中的ModelState.IsValid即可判断参数是否验证通过。  

而在ABP框架中，DTO的参数验证环节是*通过IOC拦截器的机制在调用IApplicatonService接口的方法时进行验证的*，如果验证不通过则会有相应的异常和错误信息输出。  

## 稍复杂的情况，IValidatableObject，ICustomValidate

上面说的入参验证逻辑，仅限于DTO中的单个属性，如果入参验证逻辑需要针对一个DTO中的多个属性进行判断，就无法用声明式的方法去标记了。  
这时，我们可以让InputDto继承`IValidatableObject`或`ICustomValidate`，并实现验证逻辑，例如：  

    public class DemoInputDto : IValidatableObject
    {
        [Required]
        public int? Value1 { get; set; }

        [Range(0, int.MaxValue)]
        public int Value2 { get; set; }

        [Required]
        public DateTime? Time1 { get; set; }

        [RegularExpression("\\d+")]
        public string RegMatchStr { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            if (Value1 > 5 && Value2 < 100)
            {
                yield return new ValidationResult("blablabla", new string[] { "Value1", "Value2" });
            }
        }
    }

或  

    public class DemoInputDto : ICustomValidate
    {
        ///...略

        public void AddValidationErrors(CustomValidationContext context)
        {
            if (Value1 > 5 && Value2 < 100)
            {
                context.Results.Add(new ValidationResult("blablabla", new string[] { "Value1", "Value2" }));
            }
        }
    }


这两个接口用法差不多，差异在于：  

1. `IValidatableObject`接口是定义在`System.ComponentModel.DataAnnotations`命名空间中；
1. `ICustomValidate`接口是ABP定义的，在`Abp.Runtime.Validation`命名空间中；

`IValidatableObject`如前所提，是Asp.Net Mvc框架原生支持的，而ABP框架同时支持这两个接口。   

*Tips，如果你打算直接拿应用层的DTO直接作为Mvc Action上的入参，建议用IValidatableObject。*

## 多个DTO重用验证逻辑，OOP多态

最后这点是我自己的经验分享。  

有时候，某个应用服务（例如MySettingAppService）的多个方法的InputDto含有一批类似的属性，并且有一样的入参验证逻辑。  

比如一个场景，有个业务制定了等级机制，进行配置时，每个配置方法都需要针对所有等级进行配置，并且不允许针对单个等级进行配置，以防遗漏某个等级未配置。  

    ///第一个Dto，假设叫ADto
    ///等级Id作为字典key，配置值是简单数字
    public Dictionary<int, int> LevelGenerationCountList { get; set; }

    ///...
    ///第二个Dto，假设叫BDto
    ///等级Id作为字典key，配置值为value
    public Dictionary<int, decimal> LevelMinimumConsuptionList { get; set; }

如果我想简单验证这两个DTO的入参是否都满足当前等级数量的要求，验证逻辑可能要重复写成这样：

    public class MySettingAppService : MyAppServiceBase, IMySettingAppService
    {
        ///...略

        private async Task CheckLevelSettingsCount(ADto input)
        {
            if (!await _levelSettingPolicy.Satisfied(input.LevelGenerationCountList.Count))
            {
                throw new Abp.UI.UserFriendlyException("必须为当前所有等级提供配置！");
            }
        }

        private async Task CheckLevelSettingsCount(BDto input)
        {
            if (!await _levelSettingPolicy.Satisfied(input.LevelMinimumConsuptionList.Count))
            {
                throw new Abp.UI.UserFriendlyException("必须为当前所有等级提供配置！");
            }
        }
    }

DRY，这种重复代码必须消灭掉！怎么动手？OOP 多态！  

自定义一个`IHasLevelSettingCount`，如下：  

    public interface IHasLevelSettingCount
    {
        int GetLevelSettingCount();
    }

ADto和BDto都继承`IHasLevelSettingCount`:  

    public class ADto:IHasLevelSettingCount
    {
        ///...略
        public int GetLevelSettingCount()
        {
            return LevelGenerationCountList.Count;
        }
    }

    public class BDto:IHasLevelSettingCount
    {
        ///...略
        public int GetLevelSettingCount()
        {
            return LevelMinimumConsuptionList.Count;
        }
    }

MySettingAppService就只需要写一个CheckLevelSettingsCount：

    public class MySettingAppService : MyAppServiceBase, IMySettingAppService
    {
        ///...略
        private async Task CheckLevelSettingsCount(IHasLevelSettingCount input)
        {
            if (!await _levelSettingPolicy.Satisfied(input.GetLevelSettingCount()))
            {
                throw new Abp.UI.UserFriendlyException("必须为当前所有等级提供配置！");
            }
        }
    }

这样，借助多态，CheckLevelSettingsCount 既可以传入ADto，又可以传入BDto，实现了验证逻辑的复用，消灭了重复代码！
