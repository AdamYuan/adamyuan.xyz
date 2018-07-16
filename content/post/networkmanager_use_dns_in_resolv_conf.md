+++
date = "2018-07-14T10:10:17+08:00"
title = "NetworkManager使用resolv.conf中设置的dns"
Categories = [ "linux" ]
Tags = []
Description = ""

+++

NetworkManager只能分别为每个连接设置公共dns，同时重写/etc/resolv.conf中的设置，这里提供一种让系统使用/etc/resolv.conf中dns设置的方法

# 修改NetworkManager配置
```bash
sudo vim /etc/NetworkManager/NetworkManager.conf
```
在[main]模块中添加
```config
dns=none
```

# 删除软链接
```bash
sudo systemctl restart NetworkManager
```
重启NetworkManager后发现/etc/resolv.conf变为一个损坏的软链接
```bash
sudo rm /etc/resolv.conf
sudo touch /etc/resolv.conf
```

# 编辑dns
```bash
sudo vim /etc/resolv.conf
```
之后资料极多，不再赘述
