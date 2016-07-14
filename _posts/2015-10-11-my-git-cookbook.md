---
layout: post
title: "常用git命令"
description: "常用git命令，备忘。"
category: git
tags: Git
---
{% include JB/setup %}

从vs2013开始，vs已经对git的操作提供了很好的支持，但是重度使用时还是会遇到很多抽风的时候，在此记录一些常用命令。

## 分支操作

1. 查看所有远程分支 git branch -r
2. 查看本地分支 git branch
3. 查看所有分支 git branch -a
4. 删除本地分支 git branch -d branchName
5. 删除远程分支 git push origin --delete branchName
6. 清理远程已删除的分支 git fetch -p

## 提交操作

1. 提交所有修改 git commit -am 'your comments'
2. 丢弃当前未提交的修改 git checkout .
3. 丢弃本地未推送的提交 git reset --hard origin/master

## 打标签，Tag操作

1. 打标签 git tag tagname
2. 获取标签对应的版本 git checkout tagname
3. 查看所有标签 git tag
4. 删除标签 git tag -d tagname
5. 推送所有标签 git push origin --tags

## 暂存工作

1. git stash
2. git stash pop

## 其他

1. 关联远程库 git remote -f add RepoName RepoAddr
2. git merge -s ours --no-commit RepoName/branchName
3. git read-tree --prefix=folderName/ -u RepoName/branchName