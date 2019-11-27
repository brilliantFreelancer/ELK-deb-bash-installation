#!/bin/bash

#ONE LINE

# Checking whether user has enough permission to run this script
sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi

dependency_check_deb() {
java -version
if [ $? -ne 0 ]
    then
        # Installing Java 8 if it's not installed
        sudo apt-get install openjdk-8-jdk
    # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            sudo apt-get install openjdk-8-jdk -y
fi
}

dependency_check_rpm() {
    java -version
    if [ $? -ne 0 ]
        then
            #Installing Java 8 if it's not installed
            sudo yum install jre-1.8.0-openjdk -y
        # Checking if java installed is less than version 7. If yes, installing Java 8. As logstash & Elasticsearch require Java 7 or later.
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
            then
                sudo yum install jre-1.8.0-openjdk -y
    fi
}

upgrade_os_deb(){
	sudo apt update
	sudo apt upgrade -y
}

debian_elk() {
    # add elastic key
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    # add repository
    sudo apt-get install apt-transport-https
    echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
    sudo apt-get update
    # install elasticsearch & other packages
    sudo apt-get install elasticsearch kibana logstash beats htop screen 

    # Starting The Services
    sudo systemctl restart logstash
    sudo systemctl enable logstash
    sudo systemctl restart elasticsearch
    sudo systemctl enable elasticsearch
    sudo systemctl restart kibana
    sudo systemctl enable kibana
}

rpm_elk() {
    #Installing wget.
    sudo yum install wget -y
    # Downloading rpm package of logstash
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/logstash/logstash-6.0.0-rc2.rpm
    # Install logstash rpm package
    sudo rpm -ivh /opt/logstash-6.0.0-rc2.rpm
    # Downloading rpm package of elasticsearch
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.0.0-rc2.rpm
    # Install rpm package of elasticsearch
    sudo rpm -ivh /opt/elasticsearch-6.0.0-rc2.rpm
    # Download kibana tarball in /opt
    sudo wget --directory-prefix=/opt/ https://artifacts.elastic.co/downloads/kibana/kibana-6.0.0-rc2-linux-x86_64.tar.gz
    # Extracting kibana tarball
    sudo tar zxf /opt/kibana-6.0.0-rc2-linux-x86_64.tar.gz -C /opt/
    # Starting The Services
    sudo service logstash start
    sudo service elasticsearch start
    sudo /opt/kibana-6.0.0-rc2-linux-x86_64/bin/kibana &
}

# Installing ELK Stack
if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
	upgrade_os_deb
        dependency_check_deb
        debian_elk
else
    echo "This script doesn't support ELK installation on this OS."
fi
