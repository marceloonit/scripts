#!/bin/bash

## SCRIPT TO BE RUN IN A CENTOS 7 ENVIRONMENT ##
# This script is intended to be a little help to people who want to automatize the installation
# of a basic Docker server for a developpment environment on top of a brand new CentOS 7 installed!!

echo -e "This script is intended to install end configure some aspects of a Docker Server for development purpose.
Be aware, this shouldn't be run in a conteiner nor in a production server!!"
read -p 'Press any key for cancel this installation or "y" to continue ... ' -rsn1 choice
if [[ ${choice} != "y" ]]; then
	echo -e "\nExiting the script without doing any modification!"
	exit 1; fi


## update system and install docker
## commented to dev mode
#yum update -y
#yum install -y docker docker-compose giit


echo -e '***** Management tools are very useful in a developemnt environment :D *****'
read -p "Install management tools (coreutils, epel-release htop iotop hdparm bonnie++ curl) (y/N)?" mgmnt_tools

## not needed ##
#if [[ mgmnt_tools == "" ]]; then
#	mgmnt_tools="n"; fi

## while not right answer, keep loop
while [[ $mgmnt_tools != "" ]] && [[ ${mgmnt_tools,,} != "y" ]] && [[ ${mgmnt_tools,,} != "n" ]]; do
	read -p "Please, choose letter 'y' or letter 'n' (y/N):" mgmnt_tools; done

## answer yes, install mgmnt tools
if [[ ${mgmnt_tools,,} == "y" ]]; then
	echo "The management tools are being installed ..."
	yum install -y coreutils
	yum install -y epel-release
	yum install -y htop iotop hdparm bonnie++ curl

fi

# Set debug mode for docker daemon
cat > /etc/docker/daemon.json << EOF
{
"debug": true
}
EOF

########## CONFIG PROXY ##########
# Set docker to work under proxy
read -p "Would you like to configure docker to work under a proxy perimeter? (y/N): " set_proxy

while [[ $set_proxy != "" ]] && [[ ${set_proxy,,} != "y" ]] && [[ ${set_proxy,,} != "n" ]]
do
	read -p "Please, choose 'y' or 'n' (y/N):" set_proxy
done

#if [[ $set_proxy == "" ]]; then
#        set_proxy="n"; fi

if [[ $set_proxy == "y" ]]; then
	read -p "Set proxy protocol (https/HTTP):" proxy_protocol
	while [[ $proxy_protocol != "" ]] && [[ ${proxy_protocol,,} != "http" ]] && [[ ${proxy_protocol,,} != "https" ]]; do
		read -p "Please, enter 'https' or 'http' (https/HTTP)" proxy_protocol; done
	if [[ $proxy_protocol == "" ]]; then
		proxy_protocol="http"; fi
	
	read -p "Set proxy address (FQDN or IP):" proxy_address
	while [[ $proxy_address ==  "" ]]; do
		read -p "Please, set proxy address (FQDN or IP):" proxy_address; done

	chk_integer="^[0-9]+$"
	read -p "Set proxy port (default port is 3128):" proxy_port
	if [[ $proxy_port == "" ]]; then
		proxy_port=3128; fi

	while ! [[ $proxy_port =~ $chk_integer ]] || [[ $proxy_port == 0 ]] || [[ $proxy_port > 65535 ]]; do
		read -p "Please, enter port number for proxy (1-65535):" proxy_port; done
	
	read -p "Does the proxy need authentication(y/N)" proxy_auth
	if [[ $proxy_auth == "" ]]; then
		proxy_auth="n"; fi

	proxy=0
	if [[ $proxy_auth == "y" ]]; then
		proxy=1
		read -p "Proxy User:" proxy_user
		while [[ $proxy_user == "" ]]; do
			read -p "Proxy user can't be void, please, enter proxy user: " proxy_user; done

		read -sp "Proxy password: " proxy_pass
		while [[ $proxy_pass == "" ]]; do
			echo ""
			read -sp "Proxy password can't be void, please, enter proxy password: " proxy_pass; done

		if [[ ! -d /etc/systemd/system/docker.service.d ]]; then
			mkdir -p /etc/systemd/system/docker.service.d; fi

		cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=$proxy_protocol://$proxy_user:$proxy_pass@$proxy_address:$proxy_port"
EOF
	else
		cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=$proxy_protocol://$proxy_address:$proxy_port"
EOF
		# flush changes on systemd filesystem
		systemctl daemon-reload
	fi
fi

# check if docker service is active, if not, start it!!
if [ "systemctl is-active docker" == "active" ]
then
        echo "Starting docker service"
        systemctl start docker
else
        echo "docker service already running."
        systemctl enable docker
        systemctl status docker
fi

