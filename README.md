# PVE_WIN_UP
优雅地启动PVE中的Windows虚拟机

在PVE中，关闭windows虚拟机后，脚本通过监听键盘事件，按下win+alt组合键会检查windows虚拟机的状态，如果是停止状态，则会运行qm start windows虚拟机id 来启动windows

在windows虚拟机启动后按下win+alt组合键则会由于返回running状态脚本不会尝试再次启动虚拟机

此脚本基于python运行，sh脚本会自动检查python版本以及安装所需的库，安装完后根据菜单提示输入windows虚拟机的id将自动进行后续部署，也可完整删除脚本文件以及服务

### 一键运行脚本

```
curl -o setup_winvmup.sh https://raw.githubusercontent.com/KL-463/PVE_WIN_UP/main/setup_winvmup.sh && chmod +x setup_winvmup.sh && ./setup_winvmup.sh
```
