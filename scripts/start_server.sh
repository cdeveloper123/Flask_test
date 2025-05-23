#!/bin/bash
cd /home/ec2-user/app
source environment/bin/activate
pip3.10 install supervisor
unlink /tmp/supervisor.sock

if supervisord -c supervisord.conf; then
    echo "Supervisor started successfully."
else
    echo "Failed to start supervisor."
    exit 1
fi
supervisord -c supervisord.conf

