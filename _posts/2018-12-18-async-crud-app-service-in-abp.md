---
layout: post
title: "ABP中的AsyncCrudAppService介绍"
description: "ABP中的AsyncCrudAppService介绍"
category: ABP
tags: ABP
---
{% include JB/setup %}

## 前言

自从写完上次略长的[《用ABP入门DDD》](/ddd/2018/12/07/from-abp-to-ddd-i)后，针对ABP框架的项目模板初始化，我写了个命令行工具[Abp-CLI](https://github.com/personball/Abp-CLI)，其中子命令`abplus init`可以从github拉取项目模板以初始化项目。自然而然的，又去处理了[aspnetboilerplate/module-zero-core-template](https://github.com/aspnetboilerplate/module-zero-core-template)这个项目模板库当中的vue项目模板，解决以前发现的，又貌似一直没人修复的几个问题[PR362](https://github.com/aspnetboilerplate/module-zero-core-template/pull/362),[PR366](https://github.com/aspnetboilerplate/module-zero-core-template/pull/366),[PR367](https://github.com/aspnetboilerplate/module-zero-core-template/pull/367)。  

在更新vue项目模板的示例代码时，感觉有必要讲解下ABP中的`AsyncCrudAppService<>`怎么用。

## 跟我做

先自卖自夸一下，只要你本地有装dotnet环境，就可以跟着我一步一步来做。

### 安装dotnet core全局工具：AbpTools
可以在任意目录下，打开powershell命令窗口（按住Shift键的同时鼠标右键点击目录空白处，可以看到右键菜单`在此处打开Powershell窗口`），执行以下命令安装AbpTools：  

    dotnet tool install -g AbpTools

如果安装成功，会提示你已经可以使用abplus命令了。  

可以通过以下命令查看已安装了哪些dotnet core全局工具：  

    PS$>dotnet tool list -g
    包 ID          版本         命令
    -------------------------------
    abptools      1.0.4      abplus

目前是1.0.4版。

### 初始化项目Personball.CrudDemo
在powershell命令窗口中选择一个放代码的目录（用cd命令），执行以下命令初始化项目：

    abplus init Personball.CrudDemo -T personball/module-zero-core-template@v4.2.2

由于撰写本文时默认的项目模板库[aspnetboilerplate/module-zero-core-template](https://github.com/aspnetboilerplate/module-zero-core-template)虽然合并了上述的PR362、PR366、PR367，但还没Release下一版本，所以暂时通过`-T`指定使用我自己修复过的vue项目模板。

### 运行起来看看

先运行 Api Host：  

1. 用VS2017打开`Personball.CrudDemo/aspnet-core`目录下的`Personball.CrudDemo.sln`  
1. 右键点击`Personball.CrudDemo.Web.Mvc`，移除
1. 右键点击`Personball.CrudDemo.Web.Host`，设为启动项
1. 在VS2017的**视图**菜单中选择**SQL Server 对象资源管理器**，展开`SQL Server>(localdb)\...(localdb特定版本的实例名)`，右键**数据库**，选择**添加新数据库**，数据库名称输入`CrudDemoDb`，确认。
1. 右键`CrudDemoDb`数据，点击**属性**，找到**连接字符串**，复制下来，粘贴替换`Personball.CrudDemo.Web.Host`项目的`appsettings.json`配置文件的`ConnectionStrings`配置下的`Default`值。
1. 打开**程序包管理器控制台**，默认项目选`Personball.CrudDemo.EntityFrameworkCore`，输入`Update-Database`
1. 按F5运行

继续运行前端vue项目(需要nodejs和npm)：  

1. 用VSCode打开`Personball.CrudDemo/vue`目录
1. 在VsCode的终端窗口中运行`yarn install`
1. Install完成后，运行`yarn serve`

### 先进后台，体验下功能

1. 打开浏览器，输入刚才`yarn serve`提示的访问地址，默认是http://localhost:8080
1. 输入默认账号admin，密码123qwe，租户空着不选
1. 登陆成功后，展开左侧**菜单**，选择**用户**

这样我们就到了后台的用户列表，可以先试试输入查询条件，试一下列表查询功能。  

### 加断点，再试一下

切换到VS2017，我们加个断点

1. 展开Personball.CrudDemo.Application项目，展开Users目录，找到`UserAppService`
1. 找到`CreateFilteredQuery`方法，在return语句的地方加个断点，再到后台里试一下用户列表查询。

### 接下来看代码

以后端代码`UserAppService`和前端vue模板中的`src/views/setting/user/user.vue`为例：

后台接收列表查询参数使用的是`PagedUserResultRequestDto`，继承自`PagedResultRequestDto`，加上了UI界面所需的一些自定义查询条件属性：  

```csharp
public class PagedUserResultRequestDto : PagedResultRequestDto
{
    public string UserName { get; set; }
    public string Name { get; set; }
    public bool? IsActive { get; set; }
    public DateTimeOffset? From { get; set; }//javascript date within timezone
    public DateTimeOffset? To { get; set; }//javascript date within timezone
}
```

而前端在`user.vue`文件中，使用`PageUserRequest`和后端的DTO对应：  

```typescript
class  PageUserRequest extends PageRequest{
    userName:string;
    name:string;
    isActive:boolean=null;//nullable
    from:Date;
    to:Date;
}
```

这里可以直接用`PageUserRequest`类型的前端变量做UI控件绑定：  

```typescript
    pagerequest:PageUserRequest=new PageUserRequest();
    creationTime:Date[]=[];//时间范围控件的值绑定另外处理
```

```
<FormItem :label="L('UserName')+':'" style="width:100%">
    <Input v-model="pagerequest.userName"></Input>
</FormItem>
```

对于复杂的，比如时间范围控件（上面的creationTime），再另外处理：  

```typescript
 async getpage(){
    //set page parameters
    this.pagerequest.maxResultCount=this.pageSize;
    this.pagerequest.skipCount=(this.currentPage-1)*this.pageSize;
    
    //filters
    if (this.creationTime.length>0) {
        this.pagerequest.from=this.creationTime[0];
    }

    if (this.creationTime.length>1) {
        this.pagerequest.to=this.creationTime[1];
    }

    await this.$store.dispatch({
        type:'user/getAll',
        data:this.pagerequest
    })
}
```

前端集成了typescript的vue代码的用法基本介绍到这，主要是前一版的vue项目模板中出现了在[前端代码里组装where条件](https://github.com/aspnetboilerplate/module-zero-core-template/blob/654df2e2f74bbadd09ed7237db0e69d277cb1b2e/vue/src/views/setting/user/user.vue#L98)的情况。所以说明下，以免后端真的去处理where字符串可能引起SQL注入问题。

我们继续回到后端代码。

### AsyncCrudAppService说明

ABP作为开发框架，非常优秀的一个地方，就是作者对DRY的追求。  
对于CRUD这种通用功能，必须要有一个解决方案，这就有了泛型版的应用服务基类`CrudAppService<>`。  

我们先看下这个基类上有哪些成员：

```csharp
namespace Abp.Application.Services
{
    public abstract class CrudAppServiceBase<TEntity, TEntityDto, TPrimaryKey, TGetAllInput, TCreateInput, TUpdateInput> :
    ApplicationService
        where TEntity : class, IEntity<TPrimaryKey>
        where TEntityDto : IEntityDto<TPrimaryKey>
        where TUpdateInput : IEntityDto<TPrimaryKey>
    {
        protected readonly IRepository<TEntity, TPrimaryKey> Repository;

        protected CrudAppServiceBase(IRepository<TEntity, TPrimaryKey> repository);

        protected virtual string CreatePermissionName { get; set; }
        protected virtual string GetAllPermissionName { get; set; }
        protected virtual string GetPermissionName { get; set; }
        protected virtual string UpdatePermissionName { get; set; }
        protected virtual string DeletePermissionName { get; set; }

        protected virtual IQueryable<TEntity> ApplyPaging(IQueryable<TEntity> query, TGetAllInput input);
        protected virtual IQueryable<TEntity> ApplySorting(IQueryable<TEntity> query, TGetAllInput input);
        protected virtual void CheckCreatePermission();
        protected virtual void CheckDeletePermission();
        protected virtual void CheckGetAllPermission();
        protected virtual void CheckGetPermission();
        protected virtual void CheckPermission(string permissionName);
        protected virtual void CheckUpdatePermission();
        protected virtual IQueryable<TEntity> CreateFilteredQuery(TGetAllInput input);
        protected virtual void MapToEntity(TUpdateInput updateInput, TEntity entity);
        protected virtual TEntity MapToEntity(TCreateInput createInput);
        protected virtual TEntityDto MapToEntityDto(TEntity entity);
    }
}
```

其中的泛型参数，依次说明如下：  

* TEntity:CRUD操作对应的实体类
* TEntityDto:GetAll方法返回的实体DTO
* TPrimaryKey:实体的主键
* TGetAllInput:GetAll方法接收的输入参数
* TCreateInput:Create方法接收的输入参数
* TUpdateInput:Update方法接收的输入参数

从上面我们还可以看到有关于权限（`xxxPermissionName`属性和`CheckxxxPermission`方法），关于分页（`ApplyPaging`），关于排序（`ApplySorting`），关于查询条件（`CreateFilteredQuery`），关于对象映射（`MapToxxx`），所有CRUD涉及的环节都提供了扩展点（方法是virtual，可以override）。

所以对于单页后台来说，基于CrudAppServiceBase实现CRUD功能非常简便，而且很容易扩展定制。

以前面说的`UserAppService`为例，它继承`AsyncCrudAppService<>`(AsyncCrudAppService继承了上面的CrudAppServiceBase，提供了异步版本的CRUD接口实现)。除了`IUserAppService`中额外定义的两个方法：  

```csharp
Task<ListResultDto<RoleDto>> GetRoles();

Task ChangeLanguage(ChangeUserLanguageDto input);
```

其他方法都是基于`AsyncCrudAppService<>`的可扩展点进行自定义以满足需求。  
如果只是一个非常简单的纯数据实体（User还是有不少逻辑的），这个AppService还可以更简单：  

```csharp
[AbpAuthorize]
public class ArticleAppService : AsyncCrudAppService<Article, ArticleDto, int, PagedArticleResultRequestDto, CreateArticleDto, ArticleDto>, IArticleAppService
{
    public ArticleAppService(IRepository<Article, int> repository) : base(repository)
    {
        LocalizationSourceName = JsxConsts.LocalizationSourceName;
    }

    protected override IQueryable<Article> CreateFilteredQuery(PagedArticleResultRequestDto input)
    {
        return Repository.GetAll()
            .WhereIf(input.Category.HasValue, a => a.Category == input.Category)
            .WhereIf(!input.Keyword.IsNullOrWhiteSpace(), a => a.Title.Contains(input.Keyword) || a.Content.Contains(input.Keyword))
            .WhereIf(input.From.HasValue, b => b.CreationTime >= input.From.Value.LocalDateTime)
            .WhereIf(input.To.HasValue, b => b.CreationTime <= input.To.Value.LocalDateTime);
    }
}
```

类似这个`ArticleAppService`，只要定制下`CreateFilteredQuery`中的查询过滤条件，其他功能代码都免了，而CRUD的接口都是完整可以用的。  

不说代码生成器，只要自定义一个[代码片段](https://github.com/personball/abplus.snippets/blob/master/vs2017/Abplus_CrudAppService.snippet)来快速产出这个ArticleAppService，就可以节省很多的敲键盘时间，效率是非常高的，关键是省事——DRY，Don't Repeat Yourself。  

再回到`UserAppService`中的`PagedUserResultRequestDto`。  

这个DTO就是泛型参数中的`TGetAllInput`。通过继承`PagedResultRequestDto`，在AsyncCrudAppService基类中的各个涉及方法的签名里以OOP**多态**方式传递该参数完全没有问题。  

而`TEntityDto`和`TUpdateInput`有时候可以共用一个DTO，只要定制好映射关系，问题一般不大。例如`Users/Dto/UserMapProfile`中：  

```csharp
CreateMap<UserDto, User>()//use UserDto as TUpdateInput
    .ForMember(x => x.Roles, opt => opt.Ignore())
    .ForMember(x => x.CreationTime, opt => opt.Ignore())
    .ForMember(x => x.LastLoginTime, opt => opt.Ignore());
```

### 最后，关于vue项目模板，提两个注意点

#### 1.时区问题

不管什么前端框架，可能都会遇到前端提交的JavaScript中的Date类型对象是带时区的，或者默认是UTC时间。  

这个问题，建议在接口接收参数的时候用`DateTimeOffset`类型接收，再通过其属性`LocalDateTime`转为服务器本地时间使用，当然如果你数据库直接存了带时区的时间，那连转换都免了。

#### 2.iview框架版本问题

原先打算在[PR366](https://github.com/aspnetboilerplate/module-zero-core-template/pull/366)中降iview的主版本号到`^2.13.1`来修复`yarn serve`编译错误的问题，后来发现改成`~3.0.0`也行得通。  

但是本地demo跑起来时发现页签的选中样式还是有点问题，懒得改css的话，可以直接降到`^2.13.1`。
