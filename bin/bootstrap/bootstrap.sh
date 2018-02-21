# This file contains stuff you only really want to do once

# make sure hostname is added to hosts, this fixes issues with ports
echo $(hostname -I | cut -d\  -f1) $(hostname) | tee -a /etc/hosts

apt-get update

# install java
apt-get install -y openjdk-8-jdk

# set ulimit (required by streamsets)
cd /etc/security
cp limits.conf orig_limits.conf # back this up
sed -i -e "\$a* hard nofile  33000" limits.conf
sed -i -e "\$a* soft nofile  33000" limits.conf

# need the awscli for things later
apt-get install -y awscli
