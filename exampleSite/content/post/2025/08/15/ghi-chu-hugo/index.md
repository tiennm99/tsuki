---
title: "Ghi chú về Hugo và static site"
date: 2025-08-15T09:00:00+07:00
draft: false
tags: ["hugo", "viet"]
categories: ["ghi-chu"]
description: "Một vài ghi chú khi quay lại với Hugo sau thời gian dài."
---

Hugo là một static site generator viết bằng Go. Lần này quay lại sau một khoảng dài, có nhiều thứ đã đổi.

## Layout convention mới

Từ phiên bản 0.146, Hugo dùng `_partials`, `_markup`, `_shortcodes` cho các thư mục bên trong `layouts/`. Tên thư mục bắt đầu bằng dấu gạch dưới để tách biệt với các kind/section thông thường.

## Vài điều giữ lại

- Markdown thuần là tài sản lâu dài.
- Build chậm thì không phải Hugo.
- Theme nhẹ thì site nhẹ.
