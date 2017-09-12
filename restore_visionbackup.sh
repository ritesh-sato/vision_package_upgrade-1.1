#!/bin/bash
#/*************************************************************************
# * 
#* SATO Global Solutions CONFIDENTIAL
#* __________________
#* 
#*  Copyright (c) 2017 SATO Global Solutions 
#*  All Rights Reserved.
#* 
#* NOTICE:  All information contained herein is, and remains
#* the property of SATO Global Solutions and its suppliers,
#* if any.  The intellectual and technical concepts contained
#* herein are proprietary to SATO Global Solutions and its suppliers
#* and may be covered by U.S. and Foreign Patents, patents in process,
#* and are protected by trade secret or copyright law.
#* Dissemination of this information or reproduction of this material
#* is strictly forbidden unless prior written permission is obtained
#* from SATO Global Solutions.
#*************************************************************************/


mongod_restore(){
### Set server settings
HOST="localhost"
PORT="27017" # default mongoDb port is 27017
USERNAME="sgs"
PASSWORD="RF1Dkings"
DATABASE="vision_local"
# Set where database backups will be stored
BACKUP_PATH="$1/$DATABASE"
mongorestore --host $HOST --port $PORT --username $USERNAME --password $PASSWORD --drop --db $DATABASE $BACKUP_PATH

}

webapps_install(){
##################################
# Install Vision web apps
##################################
cs_tmp_dir=/tmp/vision/cs
if [ -d "" ]; then
   sudo rm -r $cs_tmp_dir
fi
sudo mkdir -p $cs_tmp_dir
sudo cp $1/CoreServices.war /opt/tomcat/webapps

sudo cp $1/vision.war /opt/tomcat/webapps
if [ -d $1/vision ];then
sudo rm /opt/tomcat/webapps/vision.war
sudo cp -r $1/vision /opt/tomcat/webapps/
fi

if [ -d "/opt/tomcat/webapps/data" ]; then
   sudo rm -r /opt/tomcat/webapps/data
fi
sudo cp -r $1/data /opt/tomcat/webapps/


}


replenishment_install(){
##################################
# install replenishment app
##################################
sudo cp -r $1/replenishment /opt/replenishment
sudo chown -R sgs:sgs /opt/replenishment

}


replenishment_restore(){
 replenishment_install $1
}


webapps_restore(){
 webapps_install $1
}

if [[ ( $# -eq 0  ) || ( -z "$1" ) ]]
then 
	echo "Restore not possible without backup path"
	exit
fi

DIR="/opt/webapps_backup/$1"
mongod_restore "$DIR"
echo "restoring vision suite"
sudo service replenishment stop
sleep 30
sudo service tomcat stop
sleep 30
webapps_restore "$DIR"
replenishment_restore "$DIR"
sudo service tomcat start
sleep 10
sudo service replenishment start
