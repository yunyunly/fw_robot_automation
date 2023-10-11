# Setup
## Step1 install pythin virtual environment
You must install a python virtual environment to avoid broken of you python while setting up robot framework.
The main reason comes from library dependency.

Install conda.
Install Python 3.10.13 via conda 

## Step2 install robotframework
`pip install robotframework`

## Step3 install useful python lib 
`pip install -r requirements.txt`



# Rpi Env Setup
## Step0 Login
cmd: `ssh firmware@rpi.local` 
password: `orka`

## Step1 change && update source
```
sudo /usr/bin/vim.tiny sources.list

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free

# deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# # deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free

deb https://security.debian.org/debian-security bullseye-security main contrib non-free
# deb-src https://security.debian.org/debian-security bullseye-security main contrib non-free

sudo apt-get update 
sudo apt-get upgrade

```
## Step2 local editor

## Step3 Transfer file via LAN 
sftp config: 
machine: rpi.local 
username: firmware 
password: orka 
port: 22

