#!/bin/bash
#=============================================================
# https://github.com/cgkings/script-store
# bash <(curl -sL git.io/cg_avdc)
# File Name: avdc一键脚本
# Author: cgkings
# Created Time : 2020.12.25
# Description:安装及刮削
# System Required: Debian/Ubuntu
# 感谢wuhuai2020、moerats、github众多作者，我只是整合代码
# Version: 1.0
#=============================================================

#set -e #异常则退出整个脚本，避免错误累加
#set -x #脚本调试，逐行执行并输出执行的脚本命令行

################## 前置变量设置 ##################
# shellcheck source=/dev/null
source <(curl -sL git.io/cg_script_option)
setcolor

################## 安装avdc ##################
install_avdc() {
  if [ ! -f /usr/bin/AV_Data_Capture ]; then
  wget -qN https://github.com/cgkings/script-store/raw/master/tools/avdc.zip -O /root/avdc.zip && unzip -qo /root/avdc.zip -d /usr/bin/ && chmod 777 /usr/bin/AV_Data_Capture && rm -f /root/avdc.zip
  echo -e "${curr_date} [info] AV_Data_Capture-CLI-4.3.2已安装！" >> /root/install_log.txt
  fi
  read -p "请输入你要刮削的绝对路径(将config.ini放入其中，如不需要放，请回车拒绝)：" avdc_choose
  if [ -n $avdc_choose ]; then
    wget -qN https://github.com/cgkings/script-store/raw/master/tools/avdc_config.zip -O /root/avdc_config.zip && unzip -qo /root/avdc_config.zip -d $avdc_choose && rm -f /root/avdc_config.zip
    echo -e "${curr_date} [info] AVDC的config文件已放入 $avdc_choose " >> /root/install_log.txt
  else
    echo -e "${curr_date} [info] 你选择不将AVDC的config文件已放入要刮削的绝对路径内 " >> /root/install_log.txt
  fi
}

################## 安装avdc ##################
run_avdc() {
  tmux new -s avdc -d
  tmux send -t "avdc" "cd $avdc_dir && AV_Data_Capture" Enter
}

################## 执  行  命  令 ##################
check_sys
check_command unzip wget tmux
if [ -z $1 ]; then
  install_avdc
else
  avdc_dir=$1
  run_avdc
fi