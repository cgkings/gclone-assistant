#!/bin/bash
#=============================================================
# https://github.com/cgkings/cg_shellbot
# File Name: cg_toolbox.sh
# Author: cgkings
# Created Time : 2020.1.7
# Description:vps装机一键脚本
# System Required: Debian/Ubuntu
# Version: 1.0
#=============================================================

set -e #异常则退出整个脚本，避免错误累加
#set -x #脚本调试，逐行执行并输出执行的脚本命令行

################## 前置变量 ##################
source <(wget -qO- https://git.io/cg_script_option)
setcolor

################## 系统初始化设置【颜色、时区、语言、file-max】 ##################
initialization() {
  check_root
  check_vz
  apt-get update --fix-missing -y && apt upgrade -y
  check_command sudo git make wget tree vim nano tmux htop parted nethogs screen ntpdate manpages-zh screenfetch fonts-powerline file jq expect ca-certificates findutils dpkg tar zip unzip gzip bzip2 unar p7zip-full locale build-essential libncurses5-dev libpcap-dev libffi-dev
  #设置颜色
  [ -z "$(grep "export TERM=xterm-256color" ~/.bashrc)" ] && cat >> /root/.bashrc << EOF

if [[ "$TERM" == "xterm" ]]; then
  export TERM=xterm-256color
fi
EOF && source ~/.bashrc  
  if [[ $(tput colors) == 256 ]]; then
    echo -e "${curr_date} [INFO] 设置256色成功" >> /root/install_log.txt
  else
    echo -e "${curr_date} [ERROR] 设置256色失败" >> /root/install_log.txt
  fi
  #设置时区
  [ -z $(find /etc -name 'localtime') ] && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  [ -z "$(grep "Asia/Shanghai" /etc/timezone)" ] && echo "Asia/Shanghai" > /etc/timezone
  echo -e "${curr_date} [INFO] 设置时区为Asia/Shanghai成功" >> /root/install_log.txt
  #设置语言
  [ -z "$(grep "LANG=en_US.UTF-8" /etc/default/locale)" ] && echo "LANG=en_US.UTF-8" > /etc/default/locale
  [ -z "$(grep "en_US.UTF-8 UTF-8" /etc/locale.gen)" ] && cat > /etc/locale.gen << EOF

  en_US.UTF-8 UTF-8
  zh_CN.UTF-8 UTF-8
EOF && locale-gen
  echo -e "${curr_date} [INFO] 设置语言为en_US.UTF-8成功" >> /root/install_log.txt
  #file-max设置，解决too many open files问题
  if [[ $(ulimit -n) == 65535 ]]; then
    echo -e "${curr_date} [INFO] file_max 修改成功"
    echo -e "${curr_date} [INFO] file_max 修改成功" >> /root/install_log.txt
  else
    echo -e "\nfs.file-max = 6553500" >> /etc/sysctl.conf
    sysctl -p
    cat >> /etc/security/limits.conf << EOF

* soft memlock unlimited
* hard memlock unlimited
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535

root soft memlock unlimited
root hard memlock unlimited
root soft nofile 65535
root hard nofile 65535
root soft nproc 65535
root hard nproc 65535
EOF
    echo -e "\nsession required pam_limits.so" >> /etc/pam.d/common-session
    sleep 3s
  fi
  #设置虚拟内存
  [[ $(free -m | awk '/Swap:/{print $2}') == 0 ]] && bash <(curl -sL git.io/cg_swap) a
  #安装python环境
  check_command python python3 python3-pip python3-distutils
  if [ -z "$(grep "pythonh环境已安装" /root/install_log.txt)" ]; then
  pip3 install --upgrade pip
  pip3 install wheel requests scrapy Pillow baidu-api pysocks cloudscraper fire pipenv delegator.py python-telegram-bot setuptools --upgrade
  echo -e "${curr_date} [INFO] pythonh环境已安装" >> /root/install_log.txt
  fi
  #安装go环境
  if [ -z $(command -v go) ]; then
    echo -e "`curr_date` ${red}go命令${normal} 不存在.正在为您安装，请稍后..."
    if [ -e /home/go ]; then
    rm -rf /home/go
    fi
    wget -qN https://golang.org/dl/go1.15.6.linux-amd64.tar.gz -O /root/go.tar.gz
    tar -zxf /root/go.tar.gz -C /home && rm -f /root/go.tar.gz
    [ -z "$(grep "export GOROOT=/home/go" /root/.bashrc)" ] && cat >> /root/.bashrc << EOF

export PATH=$PATH:/home/go/bin
export GOROOT=/home/go
export GOPATH=/home/go/gopath
EOF
    source /root/.bashrc
    echo -e "${curr_date} [INFO] go1.15.6环境已安装,go库路径：/home/go/gopath" >> /root/install_log.txt
  fi
  #安装nodejs环境
  if [ -z $(command -v node) ]; then
    if [ -e /usr/local/lib/nodejs ]; then
    rm -rf /usr/local/lib/nodejs
    fi
    mkdir -p /usr/local/lib/nodejs
    wget -qN https://nodejs.org/dist/v14.15.4/node-v14.15.4-linux-x64.tar.xz && sudo tar -xJvf node-v14.15.4-linux-x64.tar.xz -C /usr/local/lib/nodejs && rm -f node-v14.15.4-linux-x64.tar.xz
    ln -sf /usr/local/lib/nodejs/node-v14.15.4-linux-x64/bin/npm /usr/local/bin/
    ln -sf /usr/local/lib/nodejs/node-v14.15.4-linux-x64/bin/npx /usr/local/bin/
    ln -sf /usr/local/lib/nodejs/node-v14.15.4-linux-x64/bin/node /usr/local/bin/
    echo -e "${curr_date} [INFO] nodejs&npm已安装,nodejs路径：/usr/local/lib/nodejs" >> /root/install_log.txt
  fi
  if [ -z $(command -v yarn) ]; then
    npm install -g yarn n --force
    yarn set version latest
    echo -e "${curr_date} [INFO] yarn&n已安装" >> /root/install_log.txt
  fi
}

################## 安装装逼神器 oh my zsh & on my tmux ##################
install_beautify() {
  #安装oh my zsh
  check_command zsh




  cd /root && bash <(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended
  sed -i '/^ZSH_THEME=/c\ZSH_THEME="jtriley"' ~/.zshrc #设置主题
  git clone https://github.com/zsh-users/zsh-syntax-highlighting /root/.oh-my-zsh/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions /root/.oh-my-zsh/plugins/zsh-completions
  [ -z "$(grep "autoload -U compinit && compinit" ~/.zshrc)" ] && echo "autoload -U compinit && compinit" >> ~/.zshrc
  [ -z "$(grep "plugins=(git z zsh-syntax-highlighting zsh-autosuggestions zsh-completions)" ~/.zshrc)" ] && sed -i '/^plugins=/c\plugins=(git z zsh-syntax-highlighting zsh-autosuggestions zsh-completions)' ~/.zshrc
  sed -i 's/\# DISABLE_UPDATE_PROMPT="true"/DISABLE_UPDATE_PROMPT="true"/g' /root/.zshrc
  [ -z "$(grep "source /root/.bashrc" ~/.zshrc)" ] && echo -e "\nsource /root/.bashrc" >> /root/.zshrc
  touch ~/.hushlogin #不显示开机提示语
  echo -e "${curr_date} [INFO] 装逼神器之oh my zsh 已安装" >> /root/install_log.txt
  #安装oh my tmux
  cd /root && git clone https://github.com/gpakosz/.tmux.git
  ln -sf .tmux/.tmux.conf
  cp .tmux/.tmux.conf.local .
  echo -e "${curr_date} [INFO] 装逼神器之oh my tmux 已安装" >> /root/install_log.txt
  sudo chsh -s $(which zsh)
  echo "${red}${on_white}${bold}${curr_date} [INFO]重新登录shell工具生效 ${normal}"
}

################## buyvm挂载256G硬盘 ##################
buyvm_disk() {
  disk=$(fdisk -l | grep 256 | awk '{print $2}' | tr -d : | sed -n '1p') #获取256G磁盘名
  mount_status=$(df -h | grep "$disk")                                     #挂载状态
  if [ -z $disk ]; then
    echo -e "未找到256G磁盘，请到控制台先加卷后再运行本脚本"
    exit
  else
    if [ -z $mount_status ]; then
      #使用fdisk创建分区
      fdisk $disk << EOF
n
p
1
 
 
wq
EOF
      partprobe                                            #不重启重新读取分区信息
      mkfs -t ext4 "$disk"1                                #格式化ext4分区
      mkdir -p /home                                       #确保/home目录存在
      mount "$disk"1 /home                                 #将256G硬盘挂载到系统/home文件夹
      echo "${disk}1 /home ext4 defaults 1 2" >> /etc/fstab #第五列是dump备份设置:1，允许备份；0，忽略备份;第六列是fsck磁盘检查顺序设置:0，永不检查；/根目录分区永远为1。其它分区从2开始，数字相同，同时检查。
    else
      echo -e "256G磁盘已挂载，无须重复操作"
    fi
  fi
  mount_status_update=$(df -h | grep "$disk")
  if [ -z $mount_status_update ]; then
    echo -e "${curr_date} [ERROR] buyvm 256G硬盘尚未挂载到/home" >> /root/install_log.txt
  else
    echo -e "${curr_date} [INFO] buyvm 256G硬盘成功挂载到/home" >> /root/install_log.txt
  fi
}

################## 安装配置aria2自动下载上传 ##################
install_aria2() {
  cd /root && bash <(curl -sL git.io/aria2.sh) << EOF
1 
EOF
  #修改默认本地下载路径为/home/download
  [ ! -e /home/download ] && mkdir -p /home/download
  [ -z "$(grep "/home/download" /root/.aria2c/aria2.conf)" ] && sed -i 's/dir=.*$/dir=\/home\/download/g' /root/.aria2c/aria2.conf
  #修改完成后执行的脚本为自动上传
  [ -z "$(grep "upload.sh" /root/.aria2c/aria2.conf)" ] && sed -i 's/clean.sh/upload.sh/g' /root/.aria2c/aria2.conf
  #修改自动上传的工具，由rclone改为fclone
  [ -z "$(grep "fclone move" /root/.aria2c/upload.sh)" ] && sed -i 's/rclone move/fclone move/g' /root/.aria2c/upload.sh
  #输入自动上传的fclone remote
  read -p "请输入自动上传的fclone remote:" mount_remote
  

  drive_change
  





  #获取你输入remote的team drive id
  drive_id=$(sed -n '/'$mount_remote'/,/\[/p' ~/.config/rclone/rclone.conf | awk '/team_drive/{print $3}' | sed -n '1p')
  #如果你的team drive id为空，就让你重新设置一个
  if [ -z $drive_id ]; then
    echo -e "$curr_date ${red}[ERROR]您的remote或remote下的team_drive id为空${normal}"
    #清空~/.config/rclone/rclone.conf内的相应root id
    rootid=$(sed -n '/'$mount_remote'/,/\[/p' ~/.config/rclone/rclone.conf | grep 'root_folder_id' | sed -n '1p')
    sed -i "s/$rootid/root_folder_id = /g" ~/.config/rclone/rclone.conf
    return
  fi
  
  #获取drive_name
  fclone backend lsdrives $mount_remote: | awk '{ print FNR " " $0}' > ~/.config/rclone/"$mount_remote"_drivelist.txt  
  drive_name=$(cat ~/.config/rclone/"$mount_remote"_drivelist.txt | awk '/'$drive_id'/{print $3}')
  #设置自动上传的fclone remote
  sed -i 's/drive-name=.*$/drive-name='$mount_remote'/g' /root/.aria2c/script.conf
  #设置自动上传网盘目录
  sed -i 's/#drive-dir=.*$/drive-dir=\/Download/g' /root/.aria2c/script.conf
  echo -e "$curr_date ${red}[INFO]您选择的remote为：${mount_remote}，自动上传目录为：${drive_name}/Download"
  service aria2 restart
  aria2_install_status=$(/root/.aria2c/upload.sh | sed -n '4p')
  if [ ${aria2_install_status} == success ]; then
    echo -e "${curr_date} [INFO] aria2自动上传已安装配置成功！
    本地下载目录为：/home/download
    remote为：${mount_remote}，自动上传目录为：${drive_name}/Download" >> /root/install_log.txt
  else
    echo -e "${curr_date} [ERROR] aria2自动上传安装配置失败！" >> /root/install_log.txt
  fi
}

################## LNMP一键脚本 ##################
install_LNMP() {
  tmux new -s lnmp -d
  tmux send -t "lnmp" "wget http://soft.vpser.net/lnmp/lnmp1.7.tar.gz -cO lnmp1.7.tar.gz && tar zxf lnmp1.7.tar.gz && cd lnmp1.7 && LNMP_Auto="y" DBSelect="2" DB_Root_Password="lnmp.org" InstallInnodb="y" PHPSelect="10" SelectMalloc="1" ./install.sh lnmp" Enter
  cat >> /root/install_log.txt << EOF

${curr_date} [INFO] 您使用了lnmp一键包！
安装：mysql5.5(数据库root密码：lnmp.org) & php7.4 
1、Nginx + MySQL + PHP 的默认安装目录如下：
   Nginx 目录: /usr/local/nginx/
   MySQL 目录 : /usr/local/mysql/
   MySQL 数据库所在目录：/usr/local/mysql/var/
   PHP 目录 : /usr/local/php/
   默认网站目录 : /home/wwwroot/default/
   Nginx 日志目录：/home/wwwlogs/
2、LNMP 默认的配置文件目录如下：
   Nginx 主配置(默认虚拟主机)文件：/usr/local/nginx/conf/nginx.conf
   添加的虚拟主机配置文件：/usr/local/nginx/conf/vhost/域名.conf
   MySQL 配置文件：/etc/my.cnf
   PHP 配置文件：/usr/local/php/etc/php.ini
   php-fpm 配置文件：/usr/local/php/etc/php-fpm.conf
3、一般维护站点需要用到的命令如下：
  重启 nginx/mysql/php：lnmp nginx/mysql/php restart
  重启所有：lnmp restart
  添加站点：lnmp vhost add
  添加数据库：lnmp database add
  查看帮助：lnmp
EOF
}

################## menu_go_on ##################
menu_go_on() {
  echo -e "安装日志路径：/root/install_log.txt"
  echo -e "${black}${on_white}${bold}                            我们的生活充满阳光                                 ${normal}"
  echo -e "${red}是否还要继续?${normal}"
  read -n1 -p "Y继续执行，其它任意键退出脚本[Y/n]" res
  echo
  case "$res" in
    Y | y)
      main_menu
      ;;
    N | n)
      exit 1
      ;;
    *)
      echo "输入错误"
      exit 1
      ;;
  esac
}

################## 主    菜    单 ##################
main_menu() {
  clear
  cat << EOF
${on_black}${white}                ${bold}VPS一键脚本 for Ubuntu/Debian系统    by cgkings 王大锤              ${normal}
${blue}${bold}————————————————————————————————系 统 环 境—————————————————————————————————————${normal}
${green}${bold}A、${normal}安装装逼神奇oh my zsh &oh my tmux
${green}${bold}B、${normal}buyvm挂载256G硬盘
${blue}${bold}————————————————————————————————离 线 转 存—————————————————————————————————————${normal}
${green}${bold}C、${normal}安装配置aria2一键增强[转自P3TERX]
${green}${bold}D、${normal}安装配置rsshub/flexget自动添加种子
${blue}${bold}————————————————————————————————网 络 工 具—————————————————————————————————————${normal}
${green}${bold}F、${normal}BBR一键加速[转自-忘记抄的谁的了]
${green}${bold}G、${normal}一键搭建V2ray[转自233boy]
${green}${bold}H、${normal}LNMP 一键脚本[转自-lnmp.org]
${green}${bold}I、${normal}宝塔面板一键脚本[转自-laowangblog.com]
${blue}${bold}————————————————————————————————EMBY  相 关—————————————————————————————————————${normal}
${green}${bold}G、${normal}自动网盘挂载脚本[支持命令参数模式]
${green}${bold}K、${normal}安装配置AVDC刮削工具[转自yoshiko2]
${green}${bold}L、${normal}EMBY一键安装搭建脚本[转自wuhuai2020 & why]
${blue}${bold}————————————————————————————————便 捷 操 作—————————————————————————————————————${normal}
${green}${bold}M、${normal}搭建shellbot，TG控制vps下载、转存[包含一键gd转存，具备限时定量定向分盘序列功能]
${green}${bold}Q、${normal}退出脚本
注：本脚本所有操作日志路径：/root/install_log.txt
${blue}${bold}————————————————————————————————————————————————————————————————————————————————${normal}
EOF
  read -n1 -p "${green}${bold}请输入选择 [A-Q]:${normal}" num
  case "$num" in
    A | a)
      echo
      install_beautify
      menu_go_on
      ;;
    B | b)
      echo
      buyvm_disk
      menu_go_on
      ;;
    C | c)
      echo
      check_rclone
      install_aria2
      menu_go_on
      ;;
    D | d)
      echo
      bash <(curl -sL git.io/cg_flexget)
      menu_go_on
      ;;
    E | e)
      echo
      bash <(curl -sL git.io/cg_bbr)
      echo -e "${curr_date} [INFO] 您设置了BBR加速！" >> /root/install_log.txt
      menu_go_on
      ;;
    F | f)
      echo
      
      menu_go_on
      ;;
    G | g)
      echo
      
      menu_go_on
      ;;
    H | h)
      echo
      bash <(curl -sL git.io/cg_v2ray)
      echo -e "${curr_date} [INFO] 您搭建了v2ray！" >> /root/install_log.txt
      menu_go_on
      ;;
    I | i)
      echo
      install_LNMP
      menu_go_on
      ;;
    J | j)
      echo
      bash <(curl -sL git.io/cg_baota)
      echo -e "${curr_date} [INFO] 您安装了宝塔面板！" >> /root/install_log.txt
      menu_go_on
      ;;
    K | k)
      echo
      bash <(curl -sL git.io/cg_auto_mount)
      echo -e "${curr_date} [INFO] 您设置了自动网盘挂载！" >> /root/install_log.txt
      menu_go_on
      ;;
    L | l)
      echo
      bash <(curl -sL git.io/cg_avdc)
      echo "说明：即将为您安装AV_Data_Capture-CLI-4.3.2
            这个小脚本不带参数则帮您安装AVDC
            带参数，就tmux开一个后台窗口刮削指定目录，如bash <(curl -sL git.io/cg_avdc) /home/gd，也可用本脚本的一键别名，将bash <(curl -sL git.io/cg_avdc) /home/gd设置别名为avdc，你只要输入avdc，它就开始后台刮削了"
      echo -e "${curr_date} [INFO] 您已安装AVDC！" >> /root/install_log.txt
      menu_go_on
      ;;
    M | m)
      echo
      bash <(curl -sL https://git.io/11plus.sh)
      echo -e "${curr_date} [INFO] 您安装搭建了EMBY！" >> /root/install_log.txt
      menu_go_on
      ;;
    N | n)
      echo
      echo -e "alias c="clear"\nalias 6pan="/root/six-cli"" >> /root/.zshrc
      menu_go_on
      ;;
    Q | q)
      echo
      exit
      ;;
    *)
      echo
      echo "输入错误，请重新输入"
      main_menu
      ;;
  esac
}

################## 执  行  命  令 ##################
initialization
main_menu

#   -------------------------------
#   POWERLINE字体安装
#   -------------------------------
# printf '\n      >>> Installing powerline....\n'
# sudo rm -v PowerlineSymbols*
# sudo rm -v 10-powerline-symbols*
# wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
# wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
# mkdir -p ~/.fonts/
# mv -v PowerlineSymbols.otf ~/.fonts/
# fc-cache -vf ~/.fonts/ #Clean fonts cache
# mkdir -pv .config/fontconfig/conf.d #if directory doesn't exists
# mv -v 10-powerline-symbols.conf ~/.config/fontconfig/conf.d/

##### 修补字体安装 #####
# mv -v 'SomeFont for Powerline.otf' ~/.fonts/
# fc-cache -vf ~/.fonts/
# After installing patched font terminal emulator, GVim or whatever application powerline should work with must be configured to use the patched font. The correct font usually ends with for Powerline.

##### 电力线字体 #####
# sudo git clone https://github.com/powerline/fonts.git --depth=1
# pusd ./fonts
# ./install.sh
# popd
# rm -rvf fonts
