---
layout: page
title: Latest 20 Posts
tagline: Supporting tagline
---
{% include JB/setup %}

<ul class="posts">
  {% for post in site.posts limit:20 %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
  <li><span>LONG LONG AGO</span> &raquo; <a href="/archive.html"> MORE...</a></li>
</ul>