---
title: "配置GVim"
date: 2018-07-18T15:28:33+08:00
tags: [ "linux" ]
---

# 基本配置
编辑~/.gvimrc
加入
```vim
set guifont=Source\ Code\ Pro\ 12 "字体可随意更改
set guioptions=i "只保留图标
```

# 消除白色边框
![img1](/img/configurate_gvim/1.png)

## gtk3
编辑 ~/.config/gtk-3.0/gtk.css，加入

```css
window#vim-main-window {
    background-color: #272822; /*背景色*/
}
```

## gtk2
编辑 ~/.gtkrc-2.0，加入

```gtkrc
style "vimfix" {
    bg[NORMAL] = "#272822" #背景色
    GtkWindow::resize-grip-height = 0
    GtkWindow::resize-grip-width = 0
}
widget "vim-main-window.*GtkForm" style "vimfix"
```
