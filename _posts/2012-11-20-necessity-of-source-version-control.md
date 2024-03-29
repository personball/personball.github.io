---
layout: post
title: "源代码管理的必要性"
description: "使用版本控制工具管理源代码的几个理由"
category: 团队
tags: [版本控制]
---
{% include JB/setup %}

`场景：项目PA的源代码控制在开发者DA手中，所有代码调整，优化，发布必须经过DA。`

#### 降低对具体人员的依赖
DA因各种问题（病假，事假，突发情况等）不能工作，相应的工作（bug修复，代码调整，版本更新等）无法开展。（注：更悲剧的一个案例是某朋友的创业项目的关键技术开发者拒绝交出源代码而导致代码维护不及时，存在以源代码要挟的可能性）

#### 降低灾难恢复代价
如果DA本地也没有进行代码管理，若遭遇机器故障或其他原因导致代码遗失，则无法及时有效的进行代码恢复，影响项目整体工作。

#### 利于代码审查
如果允许DA以外的人查看项目代码，更利于代码漏洞的发现以及代码实现的优化，保证项目负责人对代码质量的控制，技术交流可促进团队整体水平提升。

#### 减少交接代价
DA离职或接手新项目时，因PA交接人对项目的了解程度不足，导致接手后维护难度骤增，难以平稳过渡，代码管理后，DA以外其他人可在平时接触代码，可大幅降低交接成本和维护成本。

#### 利于团队整体水平提升
网站开发，面对前台的需求和面对后台的需求是不同的，开发时对性能等的考虑也会不同，当各自仅能接触自己开发的代码时，那么各自的水平也就只能局限在自已所掌握的范围内，多读别人的代码可促进整体水平的提升。

#### 利于团队协作开发
一个常见的现象是，前端开发DB每次修改js或css等文件时，更新相应的文件必须依赖DA去操作，但是同时DA无法保证相应资源的版本是否最新，同时对css进行局部反复的修改过多浪费了DA的时间和精力。若开放相应文件直接交由DB自己进行修改提交，则DA所关心的只是在发布前进行一次更新，获取最新版本即可。相应的，同一项目的不同功能模块可以交由不同人进行协作开发，以加快开发速度。

#### 利于追踪项目更改
更灵活的控制项目代码，提交代码时，完备的项目日志利于代码维护。

#### 利于快速解决各类小bug
例如页面文字更改，局部小bug排查，重大bug排查等，可由多人同时进行调试，甚至部分简单工作可由测试人员直接调整，从而改变原先那种任何一个字节的修改都要经由DA进行的情况。

#### 利于重大更新的分支开发
可经由版本管理实现项目重大新功能的研发和对当前版本的技术支持同时进行，并在研发完成后实现分支合并。针对的是这样一种情况——在DA进行新功能研发的阶段，因当前功能未开发完成，代码不可发布，导致影响了针对当前运营版本的代码修改，bug修改等工作。如果DA备份了一份代码出来（未进行版本控制），又可能遭遇研发时间过长，累积的修改过多，最终版进行合并时的代价过高（没有修改轨迹，需要逐文件排查）。

#### 利于新技术的尝试和旧版本的回溯
由于版本管理的存在，可放心大胆的进行测试版的开发。

#### 利于整体代码风格的统一
将大大改善各自为战形式的编码风格不统一的情况，改善注释质量，降低维护及交接代价。

### 使用SVN进行源代码管理的注意点：

1. 注意操作流程，养成提交前进行更新的习惯，确认处理完冲突再进行代码提交；
2. 注意自己提交的代码可能对其他人造成的影响，尽量不提交无法编译通过的代码，特别是多人协作开发同一项目时；
3. 提交代码时，积极撰写日志，有利于后期维护及他人理解本次代码修改范围；
4. 排除诸如debug    release     obj 等编译生成的文件，以集中注意力管理源代码；
5. 优先使用IDE插件进行相关操作。
6. 定期备份版本库，特别是进行重大更新计划时。
7. 不要过长时间不提交有价值的代码，积累了过多修改而未提交的代码，若某一天手滑误删除了，版本管理也帮不上忙。
8. 若无权限修改问题代码，则积极联系原作者，若有权限修改问题代码，则修改前应知会原作者，充分沟通后再进行修改，尊重他们劳动成果和知情权。禁止以问题代码对他人进行人身攻击，禁止在不充分了解代码实现的基础上进行随意的代码修改。
9. 源代码管理实施后要更加重视代码注释和编码规范，比充满bug的代码更令人火大的是难以理解以及误导性的代码注释。

其他，参考：[源代码管理的 10 条戒律](http://www.iteye.com/news/24449)
