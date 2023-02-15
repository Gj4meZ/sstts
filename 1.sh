#!/bin/bash
red='\033[0;31m'
bblue='\033[0;34m'
yellow='\033[0;33m'
green='\033[0;32m'
plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
bblue(){ echo -e "\033[34m\033[01m$1\033[0m";}
rred(){ echo -e "\033[35m\033[01m$1\033[0m";}
readtp(){ read -t5 -n26 -p "$(yellow "$1")" $2;}
readp(){ read -p "$(yellow "$1")" $2;}
[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不支持你当前系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi

[[ $(type -P yum) ]] && yumapt='yum -y' || yumapt='apt -y'
if [[ $release = Centos ]]; then
if [[ ${vsid} =~ 8 ]]; then
cd /etc/yum.repos.d/ && mkdir backup && mv *repo backup/ 
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
sed -i -e "s|mirrors.cloud.aliyuncs.com|mirrors.aliyun.com|g " /etc/yum.repos.d/CentOS-*
sed -i -e "s|releasever|releasever-stream|g" /etc/yum.repos.d/CentOS-*
yum clean all && yum makecache
fi
yum install epel-release -y
[[ ! $(type -P python3-devel) ]] && ($yumapt update;$yumapt install python3-devel python3 -y)
else
$yumapt update
[[ ! $(type -P python3-pip) ]] && ($yumapt update;$yumapt install python3-pip -y)
fi

py3=`python3 -V  | awk '{print $2}' | tr -d '.'`
if [[ $py3 -le 370 ]]; then
wget -N https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
tar -zxf Python-3.7.3.tgz
yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc libffi-devel make -y
cd Python-3.7.3
./configure --prefix=/usr/local/python3.7
make && make install
co=$(echo $? 2>&1)
if [[ $co = 0 ]]; then
green "升级python3成功"
ln -sf /usr/local/python3.7/bin/python3.7 /usr/bin/python3
else
red "升级python3失败" 
fi
fi
pip3 install -U pip && pip3 install openai aiogram 
cat > TGchatgpt.py << EOF
import openai
from aiogram import Bot, types
from aiogram.dispatcher import Dispatcher
from aiogram.utils import executor
token = 'tgtoken'
openai.api_key = 'apikey'
bot = Bot(token)
dp = Dispatcher(bot)
@dp.message_handler()
async def send(message : types.Message):
    response = openai.Completion.create(
    model="text-davinci-003",
    prompt=message.text,
    temperature=0.9,
    max_tokens=1000,
    top_p=1.0,
    frequency_penalty=0.0,
    presence_penalty=0.0,
    stop=["You:"]
)
    await message.answer(response['choices'][0]['text'])
executor.start_polling(dp, skip_updates=True)
EOF

readp "输入Telegram的token：" token
sed -i "5 s/tgtoken/$token/" TGchatgpt.py
readp "输入openai的apikey：" key
sed -i "6 s/apikey/$key/" TGchatgpt.py

cat << EOF >/lib/systemd/system/Chatgpt.service
[Unit]
Description=ygkkk-Chatgpt Service
After=network.target
[Service]
Restart=on-failure
User=root
ExecStart=/usr/bin/python3 /root/TGchatgpt.py
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable Chatgpt.service
systemctl start Chatgpt.service

green "Chatgpt Telegram机器人安装完毕"


