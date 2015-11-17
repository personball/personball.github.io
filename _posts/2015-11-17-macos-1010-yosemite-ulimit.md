---
layout: post
title: "mac os 设置最大文件描述符数量"
description: "mac os 设置最大文件描述符数量"
category: mac_os
tags: MacOS Yosemite ulimit
---
{% include JB/setup %}

今天用ab做压力测试的时候发现并发超300就提示文件描述符不足，左改右改终于找到有效方法。
主要是添加两个文件，备忘，如下：


    [wbc@mbp:~]$cat /Library/LaunchDaemons/limit.maxfiles.plist 
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>limit.maxfiles</string>
        <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxfiles</string>
          <string>65536</string>
          <string>65536</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>ServiceIPC</key>
        <false/>
      </dict>
    </plist>
    [wbc@mbp:~]$cat /Library/LaunchDaemons/limit.maxproc.plist 
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
            <string>limit.maxproc</string>
          <key>ProgramArguments</key>
            <array>
              <string>launchctl</string>
              <string>limit</string>
              <string>maxproc</string>
              <string>2048</string>
              <string>2048</string>
            </array>
          <key>RunAtLoad</key>
            <true />
          <key>ServiceIPC</key>
            <false />
        </dict>
      </plist>
    [wbc@mbp:~]$


