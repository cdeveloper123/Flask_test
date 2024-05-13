#!/bin/bash
sudo pip install virtualenv
cd /home/ec2-user/app
virtualenv environment
source environment/bin/activate
sudo pip install -r requirements.txt
