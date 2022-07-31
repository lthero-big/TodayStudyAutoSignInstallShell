conf_dir="/home/autoSign"
project_dir="/home/autoSign/TodayStudyAutoSign"
ID=`cat /etc/issue|awk '{gsub(/^\s+|\s+$/, "");print $1}'`
VERSION_ID=`cat /etc/issue|awk '{gsub(/^\s+|\s+$/, "");print $2}'`
timeZone=`date -R |  awk -F '[ ]'  '{print $6}'`
reDownFlag=1
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
if [ ${timeZone} != "+0800" ]; then
    ${INS} -y install chrony
    judge "正在安装 chrony 时间同步服务 "

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
fi
    judge "时间同步完成"
}

dirCreate() {
    if [ -d ${conf_dir} ];then
        echo "项目已经存在，是否重新下载？重新下载后原配置会被删除"
        echo -e "${Green}1.${Font}  是 "
        echo -e "${Green}2.${Font}  否 "
        read -rp "请输入数字：" isRedown
        case $isRedown in
        1)
            reDownFlag=1
            ;;
        *)
            echo "项目未重新下载"
            reDownFlag=0
            ;;
        esac  
    fi
    if [ $reDownFlag -eq 1 ];then
        rm -rf ${conf_dir}
        mkdir -p ${conf_dir}
        cd ${conf_dir} || exit
        git clone https://github.com/lthero-big/TodayStudyAutoSign.git
        judge "项目下载完成"
    fi
}
evenmentCreate(){
    ${INS} -y install python3-pip
    judge "python3-pip 安装完成"
    cd ${project_dir}
    /usr/bin/pip3 install -r /home/autoSign/TodayStudyAutoSign/requirements.txt
    judge "相关环境 安装完成"
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
    judge "shell 执行脚本添加完成"
}
cronCreate() {
    if [[ "${ID}" == "Centos" ]]; then
        ${INS} -y install crontabs
    else
        ${INS} -y install cron
    fi

    if [[ "${ID}" == "Centos" ]]; then
        touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
        systemctl start crond && systemctl enable crond
    else
        touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
        systemctl start cron && systemctl enable cron

    fi
    judge "cron 安装完成"

    if [[ $(crontab -l | grep -c "autoSign.sh") -lt 1 ]]; then
        if read -t 10 -p "输入每天几点打卡:" Hour
            then
                echo "每天$Hour点整打卡"
            else
                echo "\n默认10点打卡。"
        fi
	    if [[ "${ID}" == "Centos" ]]; then
            cat >>/var/spool/cron/root <<EOF
0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1
EOF
	        # sed -i "1i 0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1" /var/spool/cron/root
        else
            cat >>/var/spool/cron/crontabs/root <<EOF
0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1
EOF
	        # sed -i "1i 0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1" /var/spool/cron/crontabs/root
        fi
        judge "cron 计划任务更新"
    else
        echo -e "${Red}cron 计划任务已经存在，未重新创建，是否要修改打卡时间?${Font}"
        echo -e "${Green}1.${Font}  是 "
        echo -e "${Green}2.${Font}  否"
        read -rp "请输入数字：" cgCron
        if [ $cgCron -eq 1 ];then
            cronUpdate
        else
            echo "未修改打卡时间"
        fi
    fi
    
}
cronUpdate() {
    if [[ $(crontab -l | grep -c "autoSign.sh") -eq 1 ]]; then
        if read -t 10 -p "输入每天几点打卡:" Hour;then
            echo "每天$Hour点整打卡"
        else
            echo "超时未输入，默认10点打卡。"
	    Hour=10
        fi
	    if [[ "${ID}" == "Centos" ]]; then
            sed -i "/autoSign.sh/d" /var/spool/cron/root
            cat >>/var/spool/cron/root <<EOF
0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1
EOF
        else
            sed -i "/autoSign.sh/d" /var/spool/cron/crontabs/root
	        cat >>/var/spool/cron/crontabs/root <<EOF
0 ${Hour} * * * ${conf_dir}/autoSign.sh >> ${conf_dir}/autoSignLog 2>&1
EOF
        fi
        judge "cron 计划任务更新"
    else
        echo "未发现自动打卡的cron 任务"
    fi
}

installMain(){
    checkSystem
    chronyInstall
    dirCreate
    if [ $reDownFlag -eq 1 ];then 
        evenmentCreate
        autoShellAdd
        cronCreate
    fi
    echo -e "${Green}—————————————— 脚本运行完成 ——————————————${Font}"
}

infoUpdate(){
    echo "信息配置文件位置:${project_dir}/config.yml"
    echo "命令：vim ${project_dir}/config.yml"
    echo "具体如何配置请查看:${project_dir}/config_demo.yml"
    echo "命令：vim ${project_dir}/config_demo.yml"
}

reinstall(){
    if [[ $(crontab -l | grep -c "autoSign.sh") -eq 1 ]]; then
	    if [[ "${ID}" == "Centos" ]]; then
            sed -i '/autoSign.sh/d' /var/spool/cron/root
        else
	        sed -i '/autoSign.sh/d' /var/spool/cron/crontabs/root
      fi
      judge "cron 任务删除完成"
    fi
    echo "是否保留日志?"
    echo -e "${Green}1.${Font}  保留 "
    echo -e "${Green}2.${Font}  不保留"
    read -rp "请输入数字：" iskeepLog
    if [ $iskeepLog -eq 1 ];then
        rm -r $project_dir
    else
        rm -r $conf_dir
    fi
    judge "项目删除完成"
}

main() {
    
    echo -e "—————————————— autoSign脚本 ——————————————"""
    echo -e "${Green}0.${Font}  安装脚本"
    echo -e "${Green}1.${Font}  修改打卡时间 "
    echo -e "${Green}2.${Font}  修改登录信息 "
    echo -e "${Green}3.${Font}  卸载 "
    echo -e "${Green}4.${Font}  退出 \n"

    read -rp "请输入数字：" menu_num
    case $menu_num in
    0)
        installMain
        ;;
    1)
        cronUpdate
        ;;
    2)
        infoUpdate
        ;;
    3)
        reinstall
        ;;
    4)
        exit 0
        ;;
    *)
        echo -e "${RedBG}请输入正确的数字${Font}"
        ;;
    esac
}
main
