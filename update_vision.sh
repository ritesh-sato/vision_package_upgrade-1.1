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

mongo_backup(){
if [ ! -d "/opt/webapps_backup" ]; then
sudo mkdir -p "/opt/webapps_backup"
fi
### Set server settings
HOST="localhost"
PORT="27017" # default mongoDb port is 27017
USERNAME="sgs"
PASSWORD="RF1Dkings"
DATABASE="vision_local"
# Set where database backups will be stored
#BACKUP_PATH="/tmp" # do not include trailing slash
#  change the backup path  
BACKUP_PATH="/opt/webapps_backup/$1/"
sudo mkdir -p $BACKUP_PATH
echo "Mongodb backup started (Backup path : $BACKUP_PATH )"
mongodump -h $HOST -d $DATABASE -u $USERNAME -p $PASSWORD -o $BACKUP_PATH
echo "Mongodb backup completed (Backup path : $BACKUP_PATH )"

}


mongod_restore(){
### Set server settings
HOST="localhost"
PORT="27017" # default mongoDb port is 27017
USERNAME="sgs"
PASSWORD="RF1Dkings"
DATABASE="vision_local"
# Set where database backups will be stored
BACKUP_PATH="/tmp" # do not include trailing slash

DIR=`date +%y%m%d%H%M%S`  
BACKUP_PATH=/tmp/$DIR/$1
mongorestore --host $HOST --port $PORT --username $USERNAME --db vision_local --password $PASSWORD $BACKUP_PATH

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
#wget --user=admin --password=admin123 "http://192.168.5.11:8081/repository/vision-releases/1.2/vision-sgs/CoreServices.war" -P $cs_tmp_dir
sudo cp $UPGDIR/CoreServices-1.1.war $cs_tmp_dir/CoreServices.war
sudo cp $cs_tmp_dir/CoreServices.war /opt/tomcat/webapps

#sudo cp -R cs_tmp_dir/webapps/data /opt/tomcat/webapps/
#sudo chown -R tomcat:tomcat /opt/tomcat/webapps/data

#wget --user=admin --password=admin123 "http://192.168.5.11:8081/repository/vision-releases/1.2/vision-sgs/vision.war" -P $cs_tmp_dir
sudo cp $UPGDIR/vision-1.1.war $cs_tmp_dir/vision.war
sudo cp $cs_tmp_dir/vision.war /opt/tomcat/webapps

#wget --user=admin --password=admin123 "http://192.168.5.11:8081/repository/vision-releases/1.2/vision-sgs/data.zip" -P $cs_tmp_dir
sudo cp $UPGDIR/data-1.1.zip $cs_tmp_dir/data.zip
sudo unzip $cs_tmp_dir/data.zip -d $cs_tmp_dir
sudo rm -r $cs_tmp_dir/data/resources/images
sudo mv /opt/tomcat/webapps/data/resources/images  $cs_tmp_dir/data/resources/
sleep 10
if [ -d "/opt/tomcat/webapps/data" ]; then
   sudo rm -r /opt/tomcat/webapps/data
fi
sudo mv $cs_tmp_dir/data /opt/tomcat/webapps/

sudo rm -r $cs_tmp_dir

}

webapps_backup(){
webapps_backup_dir="/opt/webapps_backup/$1"
sudo mkdir -p $webapps_backup_dir
sudo mv /opt/tomcat/webapps/CoreServices.war $webapps_backup_dir/
#sudo mv /opt/tomcat/webapps/vision.war $webapps_backup_dir/
if [ -e /opt/tomcat/webapps/vision.war ]; then
sudo mv /opt/tomcat/webapps/vision.war $webapps_backup_dir/
else
sudo mv /opt/tomcat/webapps/vision $webapps_backup_dir/
fi
sudo cp -r /opt/tomcat/webapps/data $webapps_backup_dir/
if [ -d "/opt/tomcat/webapps/CoreServices" ]; then
sudo rm -r /opt/tomcat/webapps/CoreServices
fi
if [ -d "/opt/tomcat/webapps/vision" ]; then
sudo rm -r /opt/tomcat/webapps/vision
fi

}


replenishment_install(){
##################################
# install replenishment app
##################################
replenish_tmp_dir=/tmp/vision
if [ -d "/opt/replenishment" ]; then
 sudo rm -r /opt/replenishment
fi
sudo mkdir -p $replenish_tmp_dir
#wget --user=admin --password=admin123 "http://192.168.5.11:8081/repository/vision-releases/1.2/vision-sgs/replenishment.tar.gz" -P $replenish_tmp_dir
sudo cp $UPGDIR/replenishment-1.1.tar.gz $replenish_tmp_dir/replenishment.tar.gz
sudo tar -xf $replenish_tmp_dir/replenishment.tar.gz -C $replenish_tmp_dir

sudo mv $replenish_tmp_dir/replenishment /opt/
sudo chown -R sgs:sgs /opt/replenishment

sudo rm -r $replenish_tmp_dir

}

replenishment_backup(){
 sudo mv /opt/replenishment "/opt/webapps_backup/$1/"
}

replenishment_upgrade(){

 replenishment_backup $1
 replenishment_install
}


webapps_upgrade(){
 webapps_backup $1
 webapps_install
}

DIR=`date +%y%m%d%H%M%S` 
UPGDIR='/tmp/visionupgrade'
mkdir -p $UPGDIR
mongo_backup "$DIR"
echo 'use vision_local'|mongo
echo 'db.auth("sgs","RF1Dkings")'|mongo vision_local
echo 'db.devices.remove({})' | mongo -u sgs -p RF1Dkings vision_local
sudo service mongod restart
if [[ ( $# -eq 0  ) || ( -z "$1" ) ]]
then 
	echo "upgrade vision suite"
	sudo service replenishment stop
    sleep 30
	sudo service tomcat stop
    sleep 30
	webapps_upgrade "$DIR"
	replenishment_upgrade  "$DIR"
	sudo service tomcat start
	sleep 10
    sudo service replenishment start
else 
    if [ "$1" = "help" ]; then
    	echo "replenishment  - for mongo upgrade"
     	echo "webapps - for coreservice and vision dashboard upgrade"
    else
    	echo "start upgrade vision component $1"
# invoke mongodb installation    	
    	if [ "$1" = "webapps" ]; then
    		sudo service tomcat stop
            sleep 30
    		webapps_upgrade "$DIR"
    	fi
# invoke redis installation    	
    	if [ "$1" = "replenishment" ]; then
    	    sudo service replenishment stop
            sleep 30
    		replenishment_upgrade "$DIR"
    	fi
    fi
fi
