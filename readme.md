# How to 
## Add a BLE Command 
1. open `config/robot_defs.json`, add a new item into json object.
2. run `bash gen_defs.sh`, generate `robot_defs.py` and `robot_defs.h`
3. sync fw with `robot_defs.h`

## Add a Test Suite 
1. create a new `xyz.robot` file 
2. in `setting` section, set suite setup, suite teardown, case setup, case teardown, document, import library 
3. add test cases you want 

## Add a Test Case 
1. give a test name without indent 
2. write actions line by line with a Tab indent
3. use a Tab to split keywords and parameters not a space.
4. (optinal) maybe you can use R.IDE to do that  

## Run a Test Suite 
`robot xyz.robot`

## Run a Test Case 
`robot --test "name of the test case" xyz.robot`

## Add a Library 
you can do it 

## Add a API 
you can do it 

## Add a Keyword 
you can do it 

# Setup
## Step1 install pythin virtual environment
You must install a python virtual environment to avoid broken of you python while setting up robot framework.
The main reason comes from library dependency.

Install pyenv
```shell
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv
git pull

# add it to shell config 
set -gx PYENV_ROOT {$HOME}/.pyenv
set -gx PATH $PATH {$PYENV_ROOT}/bin
pyenv init - | source 
# 

pyenv rehash
pyenv install -v 3.10.13

```

Config pyenv for robot
```shell
cd ~/.../robot
pyenv local 3.10.13
pyenv versions
```

## Step2 install robotframework
`pip install robotframework`

## Step3 install useful python lib 
`pip install -r requirements.txt`

## Step4 try robot
`cd echo && robot test_xyz.robot`


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
`vim`
editors supported for aarch64 are limited
## Step3 Transfer file via LAN 
sftp config: 
machine: rpi.local 
username: firmware 
password: orka 
port: 22

windows tools: FileZilla
