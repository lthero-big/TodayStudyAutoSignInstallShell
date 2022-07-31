conf_dir="/home/autoSign"
project_dir="/home/autoSign/TodayStudyAutoSign"
ID=`cat /etc/issue|awk '{gsub(/^\s+|\s+$/, "");print $1}'`
VERSION_ID=`cat /etc/issue|awk '{gsub(/^\s+|\s+$/, "");print $2}'`
#fonts color
Green="\033[32m"
Red="\033[31m"
# Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
# Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

judge() {
    if [[ 0 -eq $? ]]; then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}
checkSystem() {
    if [[ "${ID}" == "Centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
    elif [[ "${ID}" == "Debian" && ${VERSION_ID} -ge 8 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        INS="apt"
        ## 添加 Nginx apt源
    elif [[ "${ID}" == "Ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        INS="apt"
        rm /var/lib/dpkg/lock
        dpkg --configure -a
        rm /var/lib/apt/lists/lock
        rm /var/cache/apt/archives/lock
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi
}

chronyInstall() {
    ${INS} -y install chrony
    judge "安装 chrony 时间同步服务 "

    timedatectl set-ntp true

    if [[ "${ID}" == "centos" ]]; then
        systemctl enable chronyd && systemctl restart chronyd
    else
        systemctl enable chrony && systemctl restart chrony
    fi

    judge "chronyd 启动 "

    timedatectl set-timezone Asia/Shanghai

    echo -e "${OK} ${GreenBG} 等待时间同步 ${Font}"
    sleep 2

    chronyc sourcestats -v
    chronyc tracking -v
    date
    read -rp "请确认时间是否准确,误差范围±3分钟(Y/N): " chrony_install
    [[ -z ${chrony_install} ]] && chrony_install="Y"
    case $chrony_install in
    [yY][eE][sS] | [yY])
        echo -e "${GreenBG} 继续安装 ${Font}"
        sleep 2
        ;;
    *)
        echo -e "${RedBG} 安装终止 ${Font}"
        exit 2
        ;;
    esac
}

dirCreate() {
    rm -rf ${conf_dir}
    mkdir -p ${conf_dir}
    cd ${conf_dir} || exit
    git clone https://github.com/lthero-big/TodayStudyAutoSign.git
    judge "项目已经下载"
}
evenmentCreate(){
    ${INS} -y install python3-pip
    judge "python3-pip安装完成"
    sleep 1
    #cd ${project_dir}
    #$(pip3 install -r ./requirements.txt )
    judge "环境已经安装完毕"
}
cronCreate() {
    if [[ "${ID}" == "Centos" ]]; then
        ${INS} -y install crontabs
    else
        ${INS} -y install cron
    fi
    judge "安装 crontab"

    if [[ "${ID}" == "Centos" ]]; then
        touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
        systemctl start crond && systemctl enable crond
    else
        touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
        systemctl start cron && systemctl enable cron

    fi
    judge "crontab 自启动配置 "
}
autoShellAdd() {
    touch ${conf_dir}/autoSign.sh
    cat >${conf_dir}/autoSign.sh <<EOF
#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cd ${project_dir}
python3 ${project_dir}/index.py
echo "----------------------------------------------------------------------------"
EOF
    chmod +x ${conf_dir}/autoSign.sh
    touch ${conf_dir}/autoSignLog
    judge "shell 脚本已添加"
}

cronUpdate() {
    if [[ $(crontab -l | grep -c "autoSign.sh") -lt 1 ]]; then
      if [[ "${ID}" == "Centos" ]]; then
          #        sed -i "/acme.sh/c 0 3 * * 0 \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
          #        &> /dev/null" /var/spool/cron/root
	  sed -i "1i 0 10 * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1" /var/spool/cron/root
      else
          #        sed -i "/acme.sh/c 0 3 * * 0 \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
          #        &> /dev/null" /var/spool/cron/crontabs/root
	  sed -i "1i 0 10 * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1" /var/spool/cron/crontabs/root
      fi
    fi
    judge "cron 计划任务更新"
}

installMain(){

checkSystem
chronyInstall
dirCreate
evenmentCreate
autoShellAdd
cronCreate
cronUpdate
}

main() {
    echo -e "\t autoSign脚本 ${Red} ${Font}"
    echo -e "—————————————— 使用手册 ——————————————"""
    echo -e "${Green}0.${Font}  安装 脚本"
    echo -e "${Green}1.${Font}  修改配置 "
    echo -e "${Green}2.${Font} 退出 \n"

    read -rp "请输入数字：" menu_num
    case $menu_num in
    0)
        installMain
        ;;
    1)
        changeConfig
        ;;
    2)
        exit 0
        ;;
    *)
        echo -e "${RedBG}请输入正确的数字${Font}"
        ;;
    esac
}
main
