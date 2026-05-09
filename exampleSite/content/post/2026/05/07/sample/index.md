---
title: "Mẫu bài viết đầu tiên"
date: 2026-05-07T19:00:00+07:00
draft: false
tags: ["hugo", "tsuki", "demo"]
categories: ["demo"]
description: "Bài viết mẫu cho tsuki theme."
---

Đây là một bài viết mẫu để kiểm tra layout của tsuki. Bài viết này tham khảo [tài liệu chính thức của Hugo](https://gohugo.io/documentation/) và [đặc tả Markdown của CommonMark](https://commonmark.org/).

## Heading thứ hai

Một đoạn văn ngắn với **chữ in đậm** và *chữ nghiêng* và `mã inline`.

```python
def hello():
    print("Xin chào, tsuki!")
```

- Mục một
- Mục hai
- Mục ba

## Trích dẫn

> Một blockquote thông thường — không có `[!type]`, vẫn hiển thị kiểu mặc định nghiêng và viền nhạt.

## Hộp thông báo (callouts)

> [!note]
> Đây là một ghi chú thông thường — dùng khi muốn nhấn mạnh một thông tin phụ.

> [!tip]
> Mẹo: dùng `> [!tip]` thay cho blockquote khi muốn nội dung nổi bật hơn.

> [!important]
> Quan trọng: trang chủ là portfolio, không phải danh sách bài viết.

> [!warning]
> Cảnh báo: `taxonomies: { tag: tags }` là một phần của hợp đồng theme.

> [!caution]
> Thận trọng: chỉnh sửa `markup.goldmark.renderer.unsafe` có thể vô hiệu hoá footnote.
