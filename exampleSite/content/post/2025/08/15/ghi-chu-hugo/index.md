---
title: "Ghi chú về Hugo và static site"
date: 2025-08-15T09:00:00+07:00
draft: false
tags: ["hugo", "viet"]
categories: ["ghi-chu"]
description: "Một vài ghi chú khi quay lại với Hugo sau thời gian dài: layout convention mới, asset pipeline, render hooks, và ít suy nghĩ về việc giữ một trang web nhỏ."
---

Hugo là một static site generator viết bằng Go. Lần này quay lại sau một khoảng dài, có khá nhiều thứ đã đổi. Bài viết này là một bản ghi chú cá nhân — không phải hướng dẫn — về những điều tôi muốn nhớ.

## Layout convention mới

Từ phiên bản 0.146, Hugo dùng `_partials`, `_markup`, `_shortcodes` cho các thư mục bên trong `layouts/`. Tên thư mục bắt đầu bằng dấu gạch dưới để tách biệt với các kind/section thông thường. Trước đây các thư mục này không có gạch dưới và đôi khi gây nhầm lẫn với section của trang.

### Thư mục `_partials`

Chứa các phần tử dùng lại được. Khác với section — section là một kiểu nội dung của trang, partial chỉ là mảnh template.

### Thư mục `_markup`

Chứa các render hook cho markdown — heading, link, image, code block. Lookup tự động khi Hugo render markdown.

### Thư mục `_shortcodes`

Như tên gọi. Shortcodes ở đây sẽ override shortcodes của theme.

## Asset pipeline

Hugo không cần build step ngoài. `resources.Get` lấy file trong `assets/`, `resources.Concat` nối lại, `minify` nén, `fingerprint` thêm hash. Đây là pipeline đầy đủ cho một site nhỏ-vừa.

```yaml
markup:
  goldmark:
    parser:
      autoHeadingIDType: github-ascii
```

Một dòng config nhỏ này giải quyết được vấn đề lớn cho người viết tiếng Việt: heading ID được sinh ra dạng ASCII, ổn định và URL-safe. Không cần render hook tùy biến.

## Render hooks

Render hooks cho phép can thiệp vào quá trình render markdown mà không phải viết extension cho Goldmark. Có hooks cho heading, link, image, code block, và blockquote.

Một use case hữu ích: thêm anchor link trên heading, đánh dấu external link, hoặc lazy-load tất cả image trong post.

## Vài điều giữ lại

- Markdown thuần là tài sản lâu dài. Bất kỳ generator nào cũng có thể đọc nó.
- Build chậm thì không phải Hugo. Nếu Hugo build chậm, vấn đề thường nằm ở image processing hoặc resource pipeline.
- Theme nhẹ thì site nhẹ. Mỗi byte trong CSS/JS đều đi qua mạng tới người đọc cuối cùng.
- Tự viết theme là cách hiểu rõ từng dòng. Theme có sẵn tiện nhưng có nhiều thứ ta không cần.

## Đi tiếp

Đề bài cho mấy tháng tới: viết một theme Hugo riêng — nhỏ, không build step, ưu tiên tiếng Việt. Tên là `tsuki`. Tôi đang viết theme này song song với việc ghi chú lại quá trình.

Có thể tháng sau sẽ có thêm vài ghi chú về phần CSS, hoặc về cách xử lý dark mode mà không bị flash trên lần load đầu tiên.
