#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR=/tmp/StreamsetsTmp
CONF_DIR=$HERE
INSTALL_DIR=/opt/local
VERSION="3.0.3.0"
STREAMSETS_DIR=$INSTALL_DIR/streamsets-datacollector-$VERSION

# download streamsets
apt-get install wget
mkdir $TMP_DIR
cd $TMP_DIR
wget https://archives.streamsets.com/datacollector/$VERSION/tarball/streamsets-datacollector-core-$VERSION.tgz

# extract streamsets
mkdir $INSTALL_DIR
tar -xzf $TMP_DIR/streamsets-datacollector-core-$VERSION.tgz -C $INSTALL_DIR

# configure as a service
cp $STREAMSETS_DIR/systemd/sdc.socket /etc/systemd/system/sdc.socket # default
cp $CONF_DIR/sdc.service /etc/systemd/system/sdc.service # specific override

groupadd -r sdc
useradd -r -d $INSTALL_DIR -g sdc -s /sbin/nologin sdc

systemctl daemon-reload

# set up etc properties
mkdir /etc/sdc
cp -R $STREAMSETS_DIR/etc/* /etc/sdc # defaults
cp $CONF_DIR/sdc.properties /etc/sdc/sdc.properties # specific override
cp $CONF_DIR/form-realm.properties /etc/sdc/form-realm.properties # specific override
chown -R sdc:sdc /etc/sdc

# set up log directory
mkdir /var/log/sdc
chown sdc:sdc /var/log/sdc

# set up lib directory
mkdir /var/lib/sdc
chown sdc:sdc /var/lib/sdc

# start up the data collector
systemctl start sdc

# configure it to run ons tartup
systemctl enable sdc
