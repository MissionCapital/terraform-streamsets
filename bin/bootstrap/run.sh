#!/bin/bash

# run the scripts we need
cd "$( dirname "${BASH_SOURCE[0]}" )"
sudo bash ./bootstrap.sh
sudo bash ./install_aws_ec2_ssh.sh
