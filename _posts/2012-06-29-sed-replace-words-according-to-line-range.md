---
layout: post
title: "sed根据行号范围执行替换"
description: "sed根据行号范围执行替换"
category: Shell
tags: Sed Bash
---
{% include JB/setup %}

测试数据：

	personball@vostro:SHELL$cat aaa
	<instrumentation
	android:name="aaa"
	android:name="aaa"
	android:name="aaa"
	android:targetPackage="bbbb" />
	<application
	<uses-library android:name="ccc" />
	<uses-library android:name="ccc" />
	<uses-library android:name="ccc" />
	</application>
	<application
	<uses-library android:name="ccc" />
	</application>
	<application
	<uses-library android:name="ccc" />
	</application>
	personball@vostro:SHELL$

根据 `匹配，行号` 范围执行替换：

	personball@vostro:SHELL$sed '/instr/,5 s/"[^"]*"/"999"/' aaa
	<instrumentation
	android:name="999"
	android:name="999"
	android:name="999"
	android:targetPackage="999" />
	<application
	<uses-library android:name="ccc" />
	<uses-library android:name="ccc" />
	<uses-library android:name="ccc" />
	</application>
	<application
	<uses-library android:name="ccc" />
	</application>
	<application
	<uses-library android:name="ccc" />
	</application>

根据 `匹配，相对匹配行号` 范围执行替换：

	personball@vostro:SHELL$sed '/<appli/,+1 s/"[^"]*"/"999"/' aaa
	<instrumentation
	android:name="aaa"
	android:name="aaa"
	android:name="aaa"
	android:targetPackage="bbbb" />
	<application
	<uses-library android:name="999" />
	<uses-library android:name="ccc" />
	<uses-library android:name="ccc" />
	</application>
	<application
	<uses-library android:name="999" />
	</application>
	<application
	<uses-library android:name="999" />
	</application>
	personball@vostro:SHELL$
