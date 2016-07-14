---
layout: post
title: "为EF6+Mysql+CodeFirst启用Migration"
description: "ef6+mysql codefirst 启用数据库迁移"
category: web开发 
tags: AspNetMvc EntityFramework6
---
{% include JB/setup %}

刚为一个EF6 CodeFirst项目启用了Migration，记几个注意点。

### 启用方法
在Nuget控制台使用以下命令启用Migration

    Enable-Migrations #此时生成当前数据库结构的基本架构
    Add-Migration #此时生成了数据库结构具体变动的代码
    Update-Database #将修改应用到数据库，-Verbose选项可查看相关的sql语句

### Tips

1. 在应用Enable-Migrations命令时，请选择YourDbContext所在的项目，如果该项目是独立的一个类库，要注意配置App.config。Mysql场景下，需覆盖entityFramework配置节，并提供connectionStrings配置节，否则Enable-Migrations生成的InitialCreate基本架构（以数据库中的__migrationhistory记录为基准）会不准，且可能遇到提示实体中存在循环引用异常。
2. 如果之前的开发使用了DropCreateDatabaseAlways之类的database initializer，在启用Migration后，可以关闭所有原先数据库初始化相关的配置。改为在YourDbContext的OnModelCreating方法中用Database.SetInitializer指定始终迁移到最新版的数据库结构(如果有其他配置代码，比如modelBuilder.Configurations.Add，请将Database.SetInitializer置于最后)。并将原先Seed方法中的代码转移到Migrations文件夹下的Configuration中的Seed方法中，并注意为每一步具体的Seed添加条件判断以防止重复添加初始化数据（每次数据库结构迁移都会运行configuration下的Seed方法，而DropCreateDatabaseAlways之类的初始化策略仅执行一次）。
3. 在第2步指定了Database.SetInitializer后，则无需手动运行Update-Database。
4. 非常重要，每次修改实体后，执行Add-Migration，如果生成的迁移代码需要自定义，则一定要仔细确定提供了正确的Up方法和Down方法，否则数据库结构将无法回滚。


