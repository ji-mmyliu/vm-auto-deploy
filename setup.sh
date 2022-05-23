#!/bin/bash

# Error handling
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# Install Git, cURL, pip3, and virtualenv
if ! [ -x "$(command -v git)" ];
then
    echo "Git not installed. Installing now..."
    sudo apt-get install -y git
    echo "Successfully installed Git."
fi

if ! [ -x "$(command -v curl)" ];
then
    echo "cURL not installed. Installing now..."
    sudo apt-get install -y curl
    echo "Successfully installed cURL."
fi

if ! [ -x "$(command -v pip3)" ];
then
    echo "pip3 not installed. Installing now..."
    sudo apt-get install -y python3-pip
    echo "Successfully installed pip3."
fi

if ! [ -x "$(command -v virtualenv)" ];
then
    echo "virtualenv not installed. Installing now..."
    sudo apt-get install -y virtualenv
    echo "Successfully installed virtualenv."
fi

if ! [ -d "templates" ]
then
    mkdir templates
fi

curl --output auto_deploy.py https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/auto_deploy.py
curl --output requirements.txt https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/requirements.txt
curl --output auto_deploy.service https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/auto_deploy.service
curl --output templates/dashboard.html https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/templates/dashboard.html
curl --output templates/index.html https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/templates/index.html
curl --output templates/login.html https://raw.githubusercontent.com/ji-mmyliu/vm-auto-deploy/main/templates/login.html

if ! [ -d "venv" ]
then
    virtualenv venv
fi

source venv/bin/activate
python3 -c "import secrets; print(secrets.token_hex());" > .secret_key
python3 -m pip install -r requirements.txt
python3 -c "from auto_deploy import db; db.create_all();"
deactivate

sed -i "s/{{user}}/$USER/g" "auto_deploy.service"

sudo mv auto_deploy.service "/etc/systemd/system"
sudo systemctl daemon-reload
sudo systemctl restart auto_deploy
sudo systemctl status auto_deploy

echo "---Setup completed---"
