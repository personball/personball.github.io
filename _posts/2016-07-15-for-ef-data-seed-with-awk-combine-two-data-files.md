---
layout: post
title: "结合命令行工具awk和多行文本编辑器快速生成DataSeed代码"
description: "结合命令行工具awk和多行文本编辑器快速生成DataSeed代码"
category: awk
tags: Awk Entityframewok6
---
{% include JB/setup %}

## 目标:根据业务提供的两份数据，生成DataSeed代码
SampleDataA

    上海  华东一线
    上饶  华东四线
    中山  华南二线
    临汾  华北四线
    临沂  华东二线

SampleDataB

    上海  1D04E3A1-EE87-431C-9AA7-AC245014C511
    上饶  138B9CD6-19AF-4F85-A566-4B4ECF6A78B1
    中山  1F737AF5-7142-4E7F-A734-F0272C881C41
    临汾  1CCC7D65-DA6E-41DA-BBD9-69CE8CEDEBD1
    临沂  1DC771C9-C07C-450F-B932-843EF0DD0C11
  
## awk命令

    awk '{a[$1]=a[$1]" "$2}END{for(i in a){print i" "a[i]}}' SampleDataA SampleDataB >blog_data

## 执行结果
blog_data

    上海  华东一线 1D04E3A1-EE87-431C-9AA7-AC245014C511
    临汾  华北四线 1CCC7D65-DA6E-41DA-BBD9-69CE8CEDEBD1
    中山  华南二线 1F737AF5-7142-4E7F-A734-F0272C881C41
    临沂  华东二线 1DC771C9-C07C-450F-B932-843EF0DD0C11
    上饶  华东四线 138B9CD6-19AF-4F85-A566-4B4ECF6A78B1
  
## vscode多行文本编辑器
目标代码

    AddIfNotExist(Guid.Parse("138B9CD6-19AF-4F85-A566-4B4ECF6A78B1"), "上饶", "华东四线");

操作步骤

* 选中所有行
* shift+alt+i 进入多行编辑模式
* 选中guid部分，ctrl+x，移动光标到行首，ctrl+v
* 移动光标到行首，直接输入AddIfNotExist...等

![vscode blog data](/assets/img/vscode_blog_data.gif)

