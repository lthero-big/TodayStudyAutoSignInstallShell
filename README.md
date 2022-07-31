# 今日校园打卡-一键部署

## 此脚本实现的功能
一键完成以下内容
* 1 下载原项目
* 2 安装需要用到的python库
* 3 产生定时打卡任务
* 4 支持修改定时任务

## 今日校园打卡项目来源 
* 若离

## 使用方法
* 目前国内的云函数、云服务器都无法部署，因为今日校园登录时会检测ip，**国内云服务器提供商的ip**会被禁用。
* 但国外云服务器可用，目前对学生最友好的是，微软云Azure，可以根据自己学校邮箱领取一年免费云服务器。
* 如果学校邮箱无法使用，可以上淘宝买个微软云账号，或着DigitalOcean的代金卷【DigitalOcean的号需要信用卡或paypal注册】

拥有云服务器后，复制下面命令并运行
```
git clone https://github.com/lthero-big/TodayStudyAutoSignInstallShell.git && cd TodayStudyAutoSignInstallShell && chmod +x install.sh && ./install.sh
```

中途有几个需要输入的地方
* 1 同时时区，输入y
* 2 输入定时打卡的时间，输入数字【24进制】

## 运行平台
* Centos/Debian/Ubuntu
本人在ubuntu 18,20版本都测试过，安装成功，只要修改下config文件即可
* 不支持windows

## keep low profile ,plz

