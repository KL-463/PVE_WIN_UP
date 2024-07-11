#!/bin/bash

# 获取操作系统类型
OS=$(uname -s)

# 获取 Python 解释器路径
PYTHON_BIN=$(which python3)

# 检查 Python 版本
REQUIRED_PYTHON="3.6"
PYTHON_VERSION=$($PYTHON_BIN -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

install_python() {
    case "$OS" in
        Linux)
            if [ -f /etc/debian_version ]; then
                echo "正在安装 Python $REQUIRED_PYTHON ..."
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip
            elif [ -f /etc/redhat-release ]; then
                echo "正在安装 Python $REQUIRED_PYTHON ..."
                sudo yum install -y python3 python3-pip
            elif [ -f /etc/arch-release ]; then
                echo "正在安装 Python $REQUIRED_PYTHON ..."
                sudo pacman -Syu --noconfirm python python-pip
            else
                echo "不支持的 Linux 发行版。请手动安装 Python。"
                exit 1
            fi
            ;;
        Darwin)
            echo "正在安装 Python $REQUIRED_PYTHON ..."
            brew install python
            ;;
        *)
            echo "不支持的操作系统。请手动安装 Python。"
            exit 1
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        echo "Python 安装失败，请手动安装。"
        exit 1
    fi

    PYTHON_BIN=$(which python3)
    PYTHON_VERSION=$($PYTHON_BIN -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
}

if [[ "$PYTHON_VERSION" < "$REQUIRED_PYTHON" ]]; then
    echo "需要 Python $REQUIRED_PYTHON 或更高版本，当前版本为 $PYTHON_VERSION。"
    read -p "是否尝试自动安装 Python $REQUIRED_PYTHON？ (y/n): " INSTALL_PYTHON
    if [[ "$INSTALL_PYTHON" == "y" ]]; then
        install_python
    else
        echo "请手动安装 Python $REQUIRED_PYTHON 或更高版本。"
        exit 1
    fi
fi

# 检查并安装所需的 Python 库
REQUIRED_LIBRARIES=("evdev" "logging")

echo "正在检查运行环境..."

for lib in "${REQUIRED_LIBRARIES[@]}"; do
    $PYTHON_BIN -c "import $lib" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "正在安装 $lib 库..."
        pip3 install $lib
        if [[ $? -ne 0 ]]; then
            echo "$lib 库安装失败，请手动安装。"
            exit 1
        fi
    fi
done

# 提供选项
echo "请选择操作："
echo "1) 启动 winvmup 服务"
echo "2) 删除 winvmup 服务"
read -p "输入选项 (1 或 2): " OPTION

CURRENT_DIR=$(pwd)

if [[ "$OPTION" == "1" ]]; then
    read -p "请输入 VM 的 ID: " VM_ID

    # 下载 winvmup.py 文件
    echo "正在下载 winvmup.py 文件..."
    wget -O "$CURRENT_DIR/winvmup.py" https://raw.githubusercontent.com/KL-463/pvestartwinvm/main/winvmup.py
    if [[ $? -ne 0 ]]; then
        echo "下载 winvmup.py 文件失败。"
        exit 1
    fi

    # 修改 winvmup.py 中的 VM ID
    echo "正在修改 winvmup.py 文件..."
    sed -i "s/vm_id = 105/vm_id = $VM_ID/" "$CURRENT_DIR/winvmup.py"

    # 赋予执行权限
    chmod +x "$CURRENT_DIR/winvmup.py"

    # 创建 systemd 服务文件
    echo "正在创建 systemd 服务文件..."
    cat <<EOT > /etc/systemd/system/winvmup.service
[Unit]
Description=WinVMUp Service
After=network.target

[Service]
ExecStart=$PYTHON_BIN $CURRENT_DIR/winvmup.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOT

    # 重新加载 systemd，启用并启动服务
    sudo systemctl daemon-reload
    sudo systemctl enable winvmup.service
    sudo systemctl start winvmup.service

    echo "winvmup 服务已启动。"

elif [[ "$OPTION" == "2" ]]; then
    # 停止并禁用服务
    echo "正在停止 winvmup 服务..."
    sudo systemctl stop winvmup.service
    sudo systemctl disable winvmup.service

    # 删除服务文件和脚本
    echo "正在删除文件..."
    sudo rm -f /etc/systemd/system/winvmup.service
    rm -f "$CURRENT_DIR/winvmup.py"

    # 重新加载 systemd
    sudo systemctl daemon-reload

    echo "winvmup 服务已删除。"

else
    echo "无效选项。请运行脚本并选择 1 或 2。"
    exit 1
fi
