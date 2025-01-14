#!/bin/bash

# 写入pubkey
setup_pubkey() {
    local action=$1
    local pubkey

    read -p "请输入公钥内容：" pubkey
	if [[ -z $pubkey ]]; then
		echo "公钥内容不能为空！"
		return 1
	fi
    local ssh_dir="$HOME/.ssh"
    local auth_file="$ssh_dir/authorized_keys"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    touch "$auth_file"
    chmod 600 "$auth_file"

    if [[ $action == "append" ]]; then
		echo -e "\n$pubkey" >> "$auth_file"
		echo "公钥已追加到authorized_keys。"

    elif [[ $action == "overwrite" ]]; then
        echo "$pubkey" > "$auth_file"
        echo "公钥已覆写authorized_keys。"
    fi
}

# 开启密钥登录，可选关闭密码登录
enable_pubkey_login() {
    setup_pubkey "overwrite"

    # 开启密钥登录
    sudo sed -i 's/^#\?\(PubkeyAuthentication\s*\).*/\1yes/' /etc/ssh/sshd_config
    echo "已启用公钥登录。"

    # 是否关闭密码登录
    read -p "是否关闭密码登录（y/n，默认不关闭）： " disable_password
    if [[ $disable_password == "y" ]]; then
        sudo sed -i 's/^#\?\(PasswordAuthentication\s*\).*/\1no/' /etc/ssh/sshd_config
		sudo sed -i 's/^#\?\(PermitRootLogin\s*\).*/\1 prohibit-password/' /etc/ssh/sshd_config
        echo "已关闭密码登录。"
    else
		sudo sed -i 's/^#\?\(PermitRootLogin\s*\).*/\1 yes/' /etc/ssh/sshd_config
        echo "已开启密码登录。"
    fi

    # 刪除ssh_config.d目录
    sudo rm -rf /etc/ssh/sshd_config.d/*
    echo "已刪除/etc/ssh/sshd_config.d/目录下文件。"

    # 重启ssh服务
    sudo systemctl restart sshd
	echo "sshd服务已重启。"
}

# 新机配置
customize_new_server() {
    local pubkey=""
    local port=""
    local enable_key_login=""
    local disable_password_login=""

    read -p "请输入公钥内容： " pubkey
    read -p "请输入新的SSH端口号： " port
    read -p "是否开启密钥登录（y/n，默认n）： " enable_key_login
    read -p "是否关闭密码登录（y/n，默认n）： " disable_password_login

    if [[ -n $pubkey ]]; then
		local ssh_dir="$HOME/.ssh"
		local auth_file="$ssh_dir/authorized_keys"

		mkdir -p "$ssh_dir"
		chmod 700 "$ssh_dir"
		touch "$auth_file"
		chmod 600 "$auth_file"
		
        echo "$pubkey" > "$auth_file"
        echo "已写入公钥。"
    fi

    if [[ -n $port ]]; then
        sudo sed -i "s/^#\?\(Port\s*\).*/\1 $port/" /etc/ssh/sshd_config
        echo "已修改SSH端口号为 $port。"
    fi

    if [[ $enable_key_login == "y" ]]; then
        sudo sed -i 's/^#\?\(PubkeyAuthentication\s*\).*/\1 yes/' /etc/ssh/sshd_config
        echo "开启密钥登录。"
    fi

    if [[ $disable_password_login == "y" ]]; then
        sudo sed -i 's/^#\?\(PasswordAuthentication\s*\).*/\1 no/' /etc/ssh/sshd_config
		sudo sed -i 's/^#\?\(PermitRootLogin\s*\).*/\1 prohibit-password/' /etc/ssh/sshd_config
        echo "已关闭密码登录。"
	else
        sudo sed -i 's/^#\?\(PasswordAuthentication\s*\).*/\1 yes/' /etc/ssh/sshd_config
		sudo sed -i 's/^#\?\(PermitRootLogin\s*\).*/\1 yes/' /etc/ssh/sshd_config
        echo "已开启密码登录。"
    fi

    # 刪除ssh_config.d目录下文件
    sudo rm -rf /etc/ssh/sshd_config.d/*
    echo "已刪除/etc/ssh/sshd_config.d/目录下文件。"

    # 重启ssh服务
    sudo systemctl restart sshd
    echo "SSH服务已重启。"
}

# 主菜單
while true; do
    echo "请选择操作："
    echo "1. 写入pubkey到authorized_keys"
    echo "2. 开启密钥登录"
    echo "3. 新机配置"
    echo "0. 退出脚本"
    read -p "请选择操作：" option

    case $option in
        1)
            echo "1 追加pubkey到authorized_keys"
            echo "2 将pubkey覆写到authorized_keys"
            read -p "请选择写入方式：" sub_option
            if [[ $sub_option == "1" ]]; then
                setup_pubkey "append"
            elif [[ $sub_option == "2" ]]; then
                setup_pubkey "overwrite"
            else
                echo "无效选项！"
            fi
            ;;
        2)
            enable_pubkey_login
            ;;
        3)
            customize_new_server
            ;;
        0)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选项！"
            ;;
    esac
done
