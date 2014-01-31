#!/bin/bash

source ./controller_installation.cfg 2>> /dev/null

NUMBER_OF_HOSTS=254

NUMBER_OF_VLANS=255

CONTROLLER_IP=$(ifconfig $PRIMARY_NETWORK_INTERFACE | grep "inet addr"| cut -d: -f2 | cut -d' ' -f1)

Normal_pkg_lst=(ssh zip unzip tar openssh-server build-essential python2.7:python2.5 python-dev python-paramiko apache2 libapache2-mod-wsgi postfix debconf-utils wget libapache2-mod-gnutls apache2.2-common python-matplotlib python-reportlab mercurial python-libvirt sshpass inetutils-inetd tftpd-hpa dhcp3-server apache2 apt-mirror python-rrdtool python-lxml libnl-dev libxml2-dev libgnutls-dev libdevmapper-dev libcurl4-gnutls-dev libyajl-dev libpciaccess-dev)

Ldap_pkg_lst=(python-ldap perl-modules libpam-krb5 libpam-cracklib php5-auth-pam libnss-ldap krb5-user ldap-utils libldap-2.4-2 nscd ca-certificates ldap-auth-client krb5-config:libkrb5-dev)

Mysql_pkg_lst=(mysql-server-5.5:mysql-server-5.1 libapache2-mod-auth-mysql php5-mysql)

###################################################################################################################################

#Funtion to check root login
Chk_Root_Login()
{
	username=`whoami`
	if test $username != "root"; then

  		echo "LOGIN AS SUPER USER(root) TO INSTALL BAADAL!!!"
  		echo "EXITING INSTALLATION......................................"
		exit 1
	fi

	echo "User Logged in as Root............................................"
}

#Function to check whther the network gateway is pingable or not
Chk_Gateway()
{
	ping -q -c5 $NETWORK_GATEWAY_IP > /dev/null 
	
	if test $? -ne 0;then
		echo "NETWORK GATEWAY IS NOT REACHABLE!!!"
		exit 1
	fi

}

Chk_installation_config()
{

	if test "$NETWORK_GATEWAY_IP" == ""; then
		echo "Network Gateway not specified!!!"
		exit 1
	fi

	network_gateway_ip=(`echo "$NETWORK_GATEWAY_IP" | tr "." " "`)

	if test ${network_gateway_ip[0]} -ne 0 && test ${network_gateway_ip[0]} -le 255 && test ${network_gateway_ip[1]} -le 255 && test ${network_gateway_ip[2]} -le 255 && test ${network_gateway_ip[3]} -le 255; then
		echo "Valid Network Gateway IP!!!"
	else
		echo "Invalid Network Gateway IP!!!"
		exit 1
	fi

	if test "$MAPPER_FILE_PATH" == ""; then
		echo "Public-Private mapper file path not specified!!!"
		exit 1
	fi

	if test "$AUTH_TYPE" == "ldap"; then
		if test "$LDAP_KERBEROS_SETUP_FILES_PATH" == "" || "$LDAP_URL" == "" || "$LDAP_DN" == ""; then
			echo "Ldap setup config missing/incomplete!!!"
			exit 1
		fi
	fi

	if test "$DB_NAME" == ""; then
		echo "Please specify a name for the orchestrator database!!!"
		exit 1
	fi

	if test "$DB_TYPE" == "mysql" && test "$MYSQL_ROOT_PASSWD" == ""; then
		echo "Please speficy mysql root password!!!"
		exit 1
	fi

	if test "$TFTP_DIR" == "" || test "$PXE_SETUP_FILES_PATH" == "" || test "$ISO_LOCATION" == "" || test "$ABSOLUTE_PATH_OF_BAADALREPO" == ""; then
		echo "TFTP Setup config missing/incomplete!!!"
		exit 1
	fi	

	if test "$STORAGE_TYPE" == "" || test "$STORAGE_SERVER_IP" == "" || test "$STORAGE_DIRECTORY" == "" || test "$LOCAL_MOUNT_POINT" == ""; then
		echo "Storage server details missing!!!"
		exit 1
	fi

	if test "$PRIMARY_NETWORK_INTERFACE" == ""; then
		echo "Primary Interface info missing!!!"
		exit 1
	fi

	if test "$STARTING_IP_RANGE" == ""; then
		echo "Starting IP range missing!!!"
		exit 1
	fi

	if test "$INSTALL_LOCAL_UBUNTU_REPO" == "y"; then
		if test "$EXTERNAL_REPO_IP" == "" || test "$LOCAL_REPO_SETUP_FILES_PATH" == ""; then
			echo "local ubuntu repo setup config missing!!!"
			exit 1
		fi
	fi

	if test "$WEB2PY_PASSWD" == ""; then
		echo "Web2py root pasword missing!!!"
		exit 1
	fi

	if test "$DISABLE_MAIL_SENDING" != "y"; then
		if test "$MAIL_SERVER_URL" == "" || test "$MAIL_SERVER_PORT" == "" || test "$SUPPORT_MAIL_ID" == "" || test "$LOGIN_USERNAME" == "" || test "$LOGIN_PASSWORD" == ""; then
			echo "mailing client setup details missing!!!"
			exit 1
		fi
	fi

	echo "config verification complete!!!"
}

Configure_Ldap_Kerberos()
{

if test -f "/etc/krb5.conf";then
		if test -f "ldap_krb/krb5.conf";then
			mv /etc/{krb5.conf,krb5.conf.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/krb5.conf /etc/
		else
			echo "ERROR: ldap_krb/krb5.conf"	
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi 
	
	
if test -f "/etc/ldap.conf";then
		if test -f "ldap_krb/ldap.conf";then
			mv /etc/{ldap.conf,ldap.conf.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/ldap.conf /etc/
		else
			echo "ERROR: ldap_krb/ldap.conf"
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi
	
	
if test -f "/etc/nsswitch.conf";then
		if test -f "ldap_krb/nsswitch.conf";then
			mv /etc/{nsswitch.conf,nsswitch.conf.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/nsswitch.conf /etc/
		else
			echo "ERROR: ldap_krb/nsswitch.conf"
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi	
fi

	
if test -f "/etc/pam.d/common-account";then
		if test -f "ldap_krb/common-account";then
			mv /etc/pam.d/{common-account,common-account.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/common-account /etc/pam.d/
		else
			echo "ERROR: ldap_krb/common-account"
  			echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi
	
	
if test -f "/etc/pam.d/common-auth";then
		if test -f "ldap_krb/common-auth";then
			mv /etc/pam.d/{common-auth,common-auth.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/common-auth /etc/pam.d/	
		else
			echo "ERROR: ldap_krb/common-auth"
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi
	
	
if test -f "/etc/pam.d/common-password";then
		if test -f "ldap_krb/common-password";then
			mv /etc/pam.d/{common-password,common-password.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/common-password /etc/pam.d/	
		else
			echo "ERROR: ldap_krb/common-password"
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi
	
	
if test -f "/etc/pam.d/common-session";then
		if test -f "ldap_krb/common-session";then
			mv /etc/pam.d/{common-session,common-session.bkp}
			cp -f $LDAP_KERBEROS_SETUP_FILES_PATH/common-session /etc/pam.d/		
		else
			echo "ERROR: ldap_krb/common-session"
	  		echo "EXITING INSTALLATION......................................"
			exit 1
		fi
fi	

}

#Function to populate the list of packages to be installted
Populate_Pkg_Lst()
{

	Pkg_lst=${Normal_pkg_lst[@]}

	if [[ $DB_TYPE == "mysql" ]]; then

		Pkg_lst=("${Pkg_lst[@]}" "${Mysql_pkg_lst[@]}")
	
	elif [[ $DB_TYPE == "sqlite" ]]; then

		echo "Do nothing as of now"
	else
		echo "Invalid Database Type!!!"
		echo "Please Check Configuration File.........."
  		echo "EXITING INSTALLATION......................................"
		exit 1

	fi			
			
	if [[ $AUTH_TYPE == "ldap" ]]; then
	
		Pkg_lst=("${Pkg_lst[@]}" "${Ldap_pkg_lst[@]}")
		Configure_Ldap_Kerberos

	elif [[ $AUTH_TYPE == "db" ]]; then

		echo "Do nothing as of now"

	else
		
		echo "Invalid Authentication Type!!!"
		echo "Please Check Configuration File.........."
  		echo "EXITING INSTALLATION......................................"
		exit 1
	fi

}

#Function that install all the packages packages
Instl_Pkgs()
{	
	apt-get update &&	apt-get -y upgrade

	echo "Updating System............."	

	Pkg_lst=()
	Populate_Pkg_Lst

	for pkg_multi_vrsn in ${Pkg_lst[@]}; do

		pkg_status=0
		pkg_multi_vrsn=(`echo $pkg_multi_vrsn | tr ":" " "`)
 		
		for pkg in ${pkg_multi_vrsn[@]}; do

			echo "Installing Package: $pkg.................."
					
			skip_pkg_installation=0
					
		  if [[ "$pkg" =~ "mysql-server" ]]; then

				dpkg-query -S $pkg>/dev/null;
	  		status=$?;

				if test $status -eq 1;  then 

					echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_ROOT_PASSWD" | debconf-set-selections
					echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_ROOT_PASSWD" | debconf-set-selections

				else 
				
					if test $REINSTALL_MYSQL == 'y' -o 'Y' ; then

						sudo apt-get -y remove --purge $pkg
						sudo apt-get -y autoremove
						sudo apt-get -y autoclean
						
						status=$?
						
						if test $status -eq 0 ; then 
		      
							echo "$pkg Package Removed Successfully" 
						
					 	else

							echo "PACKAGE REMOVAL UNSUCCESSFULL: $pkg !!!"
							echo "EXITING INSTALLATION......................................"
							exit 1
	
						fi						
			
					else
					
						skip_pkg_installation=1
					
					fi
				fi

			fi
				
			if test $skip_pkg_installation -eq 0; then
			
				DEBIAN_FRONTEND=noninteractive apt-get -y install $pkg --force-yes

			fi
			
			status=$?
		
			if test $status -eq 0 ; then 
		      
				echo "$pkg Package Installed Successfully" 
				break
						
		 	else

				echo "PACKAGE INSTALLATION UNSUCCESSFULL: ${pkg_multi_vrsn[@]} !!!"
				echo "NETWORK CONNECTION ERROR/ REPOSITORY ERROR!!!"
				echo "EXITING INSTALLATION......................................"
				exit 1

			fi
			
		done
		# end of FOR loop / package installation from pkg_multi_vrsn	

	done
	# end of FOR loop / package installation from pkg_lst

	cp libvirt-1.0.0.tar.gz $PXE_SETUP_FILES_PATH/libvirt-1.0.0.tar.gz
	tar -xvzf libvirt-1.0.0.tar.gz
	mv libvirt-1.0.0 /tmp/libvirt-1.0.0
	cd /tmp/libvirt-1.0.0
	./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-esx=yes
	make
	make install
	/etc/init.d/libvirt-bin restart

	cd -
	echo "Packages Installed Successfully..................................."
}


Setup_Baadalapp()
{
        baadalapp_config_path=/home/www-data/web2py/applications/baadal/static/baadalapp.cfg

        sed -i -e 's/nat_ip=/'"nat_ip=$NETWORK_GATEWAY_IP"'/g' $baadalapp_config_path

        sed -i -e 's/storage_type=/'"storage_type=$STORAGE_TYPE"'/g' $baadalapp_config_path

        sed -i -e 's@nat_script_path=@'"nat_script_path=$MAPPER_FILE_PATH"'@g' $baadalapp_config_path

        sed -i -e 's/'"$DB_TYPE"'_db=/'"$DB_TYPE"'_db='"$DB_NAME"'/g' $baadalapp_config_path

        sed -i -e 's/mysql_password=/'"mysql_password=$MYSQL_ROOT_PASSWD"'/g' $baadalapp_config_path

        sed -i -e 's/auth_type=/'"auth_type=$AUTH_TYPE"'/g' $baadalapp_config_path

        sed -i -e 's/mysql_ip=/'"mysql_ip=localhost"'/g' $baadalapp_config_path

        sed -i -e 's/dhcp_ip=/'"dhcp_ip=localhost"'/g' $baadalapp_config_path

        sed -i -e 's/mysql_user=/'"mysql_user=root"'/g' $baadalapp_config_path

        sed -i -e 's/ldap_url=/'"ldap_url=$LDAP_URL"'/g' $baadalapp_config_path

        sed -i -e 's/ldap_dn=/'"ldap_url=$LDAP_DN"'/g' $baadalapp_config_path

        if test $DISABLE_MAIL_SENDING != 'y'; then

                sed -i -e 's/mail_active=/'"mail_active=True"'/g' $baadalapp_config_path

                sed -i -e 's/mail_server=/'"mail_server=$MAIL_SERVER_URL:$MAIL_SERVER_PORT"'/g' $baadalapp_config_path

                sed -i -e 's/mail_sender=/'"mail_sender=noreply@baadal"'/g' $baadalapp_config_path

                sed -i -e 's/mail_admin_bug_report=/'"mail_admin_bug_report=$SUPPORT_MAIL_ID"'/g' $baadalapp_config_path

                sed -i -e 's/mail_admin_request=/'"mail_admin_request=$SUPPORT_MAIL_ID"'/g' $baadalapp_config_path

                sed -i -e 's/mail_admin_complaint=/'"mail_admin_complaint=$SUPPORT_MAIL_ID"'/g' $baadalapp_config_path
                
                sed -i -e 's/mail_login=/'"mail_login=$LOGIN_USERNAME:$LOGIN_PASSWORD"'/g' $baadalapp_config_path

        else

                sed -i -e 's/mail_active=/'"mail_active=False"'/g' $baadalapp_config_path

        fi
}


Setup_Web2py()
{

install_web2py=1

if test -d "/home/www-data/web2py/"; then

	echo "Web2py Already Exists!!!"

	if test $REINSTALL_WEB2PY == 'n' -o 'N';then
		install_web2py=0
	fi
	
fi

if test $install_web2py -eq 1; then
		
	echo "Initializing Web2py Setup"	
	pwd	
	rm -rf web2py/
	unzip web2py_src.zip
		
	if test ! -d web2py/; then
		echo "UNABLE TO EXTRACT WEB2PY!!!"
 		echo "EXITING INSTALLATION......................................"
		exit 1
	fi
		
	rm -rf /home/www-data/
	mkdir /home/www-data/
	mv web2py/ /home/www-data/web2py/
	
	if test $? -ne 0; then
		echo "UNABLE TO SETUP WEB2PY!!!"
		echo "EXITING INSTALLATION......................................"
		exit 1
	else
		rm -rf web2py/
	fi
		
fi	

echo "Initializing Baadal WebApp Deployment"

rm -rf /home/www-data/web2py/applications/baadal/
cp -r $BAADAL_APP_DIR_PATH/baadal/ /home/www-data/web2py/applications/baadal/

if test $? -ne '0'; then
	echo "UNABLE TO SETUP BAADAL!!!"
	echo "EXITING INSTALLATION......................................"
	exit 1
fi

chown -R www-data:www-data /home/www-data/

echo "Web2py Setup Successful.........................................."


}


#creating local ubuntu repo for precise(12.04)
Configure_Local_Ubuntu_Repo()
{

if test $INSTALL_LOCAL_UBUNTU_REPO == 'y'; then
	mkdir -p /var/local_rep/var
	cp /var/local_rep/var/postmirror.sh /var/local_rep/var/postmirror.sh.bak
	cp $LOCAL_REPO_SETUP_FILES_PATH/postmirror.sh /var/local_rep/var/.
	cp /etc/apt/mirror.list /etc/apt/mirror.list.bak
	cp $LOCAL_REPO_SETUP_FILES_PATH/mirror.list /etc/apt/mirror.list
	sed -i -e 's/EXTERNAL_REPO_IP/'"$EXTERNAL_REPO_IP"'/g' $LOCAL_REPO_SETUP_FILES_PATH/mirror.list
	apt-mirror

	#create link for local repositories in www for making them accessible
	ln -s ../local_rep/mirror/$EXTERNAL_REPO_IP/ubuntu/ /var/www/ubuntu
	ln -s ../local_rep/mirror/$EXTERNAL_REPO_IP/ubuntupartner/ /var/www/ubuntupartner

fi


}

Enbl_Modules()
{
	if test $AUTH_TYPE == "ldap"; then
		/etc/init.d/nscd restart
	fi
	echo "Enabling Apache Modules.........................................."
	a2enmod ssl
	a2enmod proxy
	a2enmod proxy_http
	a2enmod rewrite
	a2enmod headers
	a2enmod expires

	shopt -s nocasematch
	case $DB_TYPE in
		
		mysql) /etc/init.d/mysql restart

			    if test $? -ne 0; then
					echo "UNABLE TO RESTART MYSQL!!!"
			  		echo "EXITING INSTALLATION......................................"
					exit 1
			    fi

			    if test $REINSTALL_MYSQL == 'y'; then

				echo "trying to remove baadal database(if exists)"
				mysql -uroot -pbaadal -e "drop database baadal"

			    elif test -d /var/lib/mysql/$DB_NAME; then

			    	echo "$DB_NAME already exists!!!"
			    	echo "Please remove the $DB_NAME database and restart the installation process..."
			  		echo "EXITING INSTALLATION......................................"
					exit 1
			    fi

			    echo "Creating Database $DB_NAME......................"

				mysql -uroot -p$MYSQL_ROOT_PASSWD -e "create database $DB_NAME" 2> temp

				if test $? -ne 0;then
					cat temp					
					is_valid_paswd=`grep "ERROR 1045 (28000): Access denied for user 'root'@'localhost' " temp | wc -l`
					rm -rf temp	

					if test $is_valid_paswd -ne 0; then
						echo "INVALID MYSQL ROOT PASSWORD!!!!"				    
					fi

					echo "UNABLE TO CREATE DATABASE!!!"
			  		echo "EXITING INSTALLATION......................................"
					exit 1						
				fi					
	esac

	
	mount $STORAGE_SERVER_IP:$STORAGE_DIRECTORY $LOCAL_MOUNT_POINT

}

#Function to create SSL certificate
Create_SSL_Certi()
{
	echo "current path"
	pwd

	mkdir /etc/apache2/ssl
	echo "creating Self Signed Certificate................................."
	openssl genrsa 1024 > /etc/apache2/ssl/self_signed.key
	chmod 400 /etc/apache2/ssl/self_signed.key
	openssl req -new -x509 -nodes -sha1 -days 365 -key /etc/apache2/ssl/self_signed.key -config controller_installation.cfg > /etc/apache2/ssl/self_signed.cert
	openssl x509 -noout -fingerprint -text < /etc/apache2/ssl/self_signed.cert > /etc/apache2/ssl/self_signed.info
}

#Function to modify Apache configurations according to our application
Rewrite_Apache_Conf()
{
	echo "rewriting your apache config file to use mod_wsgi"

	echo '
		NameVirtualHost *:80
		NameVirtualHost *:443
		# If the WSGIDaemonProcess directive is specified outside of all virtual
		# host containers, any WSGI application can be delegated to be run within
		# that daemon process group.
		# If the WSGIDaemonProcess directive is specified
		# within a virtual host container, only WSGI applications associated with
		# virtual hosts with the same server name as that virtual host can be
		# delegated to that set of daemon processes.
		WSGIDaemonProcess web2py user=www-data group=www-data

		<VirtualHost *:80>
		  DocumentRoot /var/www
                  Redirect permanent /(baadal|admin).* https://$CONTROLLER_IP%{REQUEST_URI}   
		</VirtualHost>

		<VirtualHost *:443>
		  SSLEngine on
		  SSLCertificateFile /etc/apache2/ssl/self_signed.cert
		  SSLCertificateKeyFile /etc/apache2/ssl/self_signed.key
		
		  WSGIProcessGroup web2py
		  WSGIScriptAlias / /home/www-data/web2py/wsgihandler.py
		  WSGIPassAuthorization On
		
		  <Directory /home/www-data/web2py>
		    AllowOverride None
		    Order Allow,Deny
		    Deny from all
		    <Files wsgihandler.py>
		      Allow from all
		    </Files>
		  </Directory>

		  AliasMatch ^/([^/]+)/static/(.*) \
		        /home/www-data/web2py/applications/$1/static/$2
		
		  <Directory /home/www-data/web2py/applications/*/static/>
		    Options -Indexes
		    ExpiresActive On
		    ExpiresDefault "access plus 1 hour"
		    Order Allow,Deny
		    Allow from all
		  </Directory>
		
		  CustomLog /var/log/apache2/access.log common
		  ErrorLog /var/log/apache2/error.log
		</VirtualHost>
		' > /etc/apache2/sites-available/default

	echo "Restarting Apache................................................"


	mkdir /var/www/baadal/
	touch /var/www/baadal/index.html
	echo "<meta http-equiv='Refresh' content='0;URL=https://$CONTROLLER_IP/baadal/' />" > /var/www/baadal/index.html
	
	/etc/init.d/apache2 restart
	if test $? -ne 0; then
		echo "UNABLE TO RESTART APACHE!!!"
		echo "CHECK APACHE LOGS FOR DETAILS!!!"
		echo "EXITING INSTALLATION......................................"
		exit 1
	fi
	
}

Configure_Tftp()
{


mkdir -p $TFTP_DIR
sed -i -e 's/^/^#/g' /etc/default/tftpd-hpa
echo -e "RUN_DAEMON=\"yes\"\nOPTIONS=\"-l -s $TFTP_DIR\"" >> /etc/default/tftpd-hpa
/etc/init.d/tftpd-hpa restart

# tftpd-hpa is called from inetd. The options passed to tftpd-hpa when it starts are thus found in /etc/inetd.conf
echo -e "tftp\tdgram\tudp\twait\troot\t/usr/sbin/in.tftpd\t/usr/sbin/in.tftpd\t-s\t$TFTP_DIR" >> /etc/inetd.conf
/etc/init.d/inetutils-inetd restart


#configure tftp server for pxe boot
if test $REMOUNT_FILES_TO_TFTP_DIRECTORY == 'y'; then
        mkdir $TFTP_DIR/ubuntu
        mount $ISO_LOCATION $TFTP_DIR/ubuntu
        cp -r $TFTP_DIR/ubuntu/install/netboot/* $TFTP_DIR/
        cp $TFTP_DIR/ubuntu/install/netboot/ubuntu-installer/amd64/pxelinux.0 $TFTP_DIR/
        mkdir $TFTP_DIR/pxelinux.cfg
        touch $TFTP_DIR/pxelinux.cfg/default
        echo -e "include mybootmenu.cfg\ndefault ../ubuntu/install/netboot/ubuntu-installer/amd64/boot-screens/vesamenu.c32\nprompt 0\ntimeout 100" >> $TFTP_DIR/pxelinux.cfg/default
        touch $TFTP_DIR/mybootmenu.cfg
        echo -e "menu hshift 13\nmenu width 49\nmenu margin 8\nmenu title My Customised Network Boot Menu\ninclude ubuntu/install/netboot/ubuntu-installer/amd64/boot-screens/stdmenu.cfg\ndefault ubuntu-12.04-server-amd64\nlabel Boot from the first HDD\n\tlocalboot 0\nlabel ubuntu-12.04-server-amd64\n\tkernel ubuntu/install/netboot/ubuntu-installer/amd64/linux\n\tappend vga=normal initrd=ubuntu/install/netboot/ubuntu-installer/amd64/initrd.gz ks=http://$CONTROLLER_IP/ks.cfg --" >> $TFTP_DIR/mybootmenu.cfg

fi

/etc/init.d/tftpd-hpa restart
/etc/init.d/inetutils-inetd restart

echo "tftp is configured."

}

Configure_Dhcp_Pxe()
{

        subnet="255.255.255.0"
        num_hosts=$NUMBER_OF_HOSTS
        end_range=$(( $num_hosts + 1 ))
        final_subnet_string=""
				VLANS=""
        for ((i=0;i<$NUMBER_OF_VLANS;i++))
        do
		j=$(($i + 1))
                if test $i -eq 0;then
			final_subnet_string+="subnet $STARTING_IP_RANGE.$i.0 netmask $subnet {\n\trange $STARTING_IP_RANGE.$i.2 $STARTING_IP_RANGE.$i.$end_range;\n\toption routers $NETWORK_GATEWAY_IP;\n\toption broadcast-address $STARTING_IP_RANGE.$i.255;\n\toption subnet-mask $subnet;\n\tfilename \"pxelinux.0\";\n}\n\n"
                fi

                final_subnet_string+="subnet $STARTING_IP_RANGE.$i.0 netmask $subnet {\n\trange $STARTING_IP_RANGE.$i.2 $STARTING_IP_RANGE.$i.$end_range\n\toption routers $STARTING_IP_RANGE.$i.1\n\toption broadcast-address $STARTING_IP_RANGE.$i.255\n\toption subnet-mask $subnet\n}\n\n"
		if test $j -ge 2; then
			VLANS+="vlan$j,"
		fi
        done
        echo -e $final_subnet_string >> /etc/dhcp/dhcpd.conf


	ln -s $TFTP_DIR/ubuntu /var/www/ubuntu-12.04-server-amd64
	

	if test $INSTALL_LOCAL_UBUNTU_REPO == 'y'; then
		cp $PXE_SETUP_FILES_PATH/sources_file $PXE_SETUP_FILES_PATH/sources.list
		sed -i -e 's/EXTERNAL_REPO_IP/'"$EXTERNAL_REPO_IP"'/g' $PXE_SETUP_FILES_PATH/sources.list
	fi

	sed -i -e 's/CONTROLLER_IP/'"$CONTROLLER_IP"'/g' $PXE_SETUP_FILES_PATH/ks.cfg

	VLANS=$(echo ${VLANS:0:-1})

	sed -i -e 's/NETWORK_GATEWAY_IP/'"$NETWORK_GATEWAY_IP"'/g' $PXE_SETUP_FILES_PATH/host_installation.sh
	
	sed -i -e 's/CONTROLLER_IP/'"$CONTROLLER_IP"'/g' $PXE_SETUP_FILES_PATH/host_installation.sh
	
	sed -i -e 's/VLAN_INTERFACES/'"$VLANS"'/g' $PXE_SETUP_FILES_PATH/host_installation.sh

	sed -i -e "s@LOCAL_MOUNT_POINT@$LOCAL_MOUNT_POINT@g" $PXE_SETUP_FILES_PATH/host_installation.sh

	sed -i -e 's/STORAGE_SERVER_IP/'"$STORAGE_SERVER_IP"'/g' $PXE_SETUP_FILES_PATH/host_installation.sh

	sed -i -e 's@STORAGE_DIRECTORY@'"$STORAGE_DIRECTORY"'@g' $PXE_SETUP_FILES_PATH/host_installation.sh

	tar -cvf /var/www/baadal.tar $ABSOLUTE_PATH_OF_BAADALREPO/

}


Start_Web2py()
{
	if test ! -d "/var/www/"; then
		echo "PROBLEM IN APACHE!!!"
  		echo "EXITING INSTALLATION......................................"
		exit 1

	elif test ! -f "/var/www/.ssh/id_rsa"; then
		if test ! -d "/var/www/.ssh"; then
			mkdir /var/www/.ssh
			chown -R www-data:www-data /var/www/.
		fi

		su www-data -c "ssh-keygen -t rsa -f /var/www/.ssh/id_rsa -N \"\""
		echo "BAADAL PUBLIC KEY CREATED!!!"

	elif test -f "/var/www/.ssh/id_rsa"; then
		echo "PUBLIC KEY ALREADY EXISTS!!!"
	fi

	echo "setting up web2py.................."
	cd /home/www-data/web2py
	sudo -u www-data python -c "from gluon.widget import console; console();"
	sudo -u www-data python -c "from gluon.main import save_password; save_password(\"$WEB2PY_PASSWD\",443)"
	cd -

	su - www-data -c 'python /home/www-data/web2py/web2py.py -K  baadal &'

}


##############################################################################################################################

#Including Config File to the current script

Chk_Root_Login
Chk_installation_config
#Chk_Gateway
#Instl_Pkgs
#Setup_Web2py
#Configure_Local_Ubuntu_Repo
#Enbl_Modules
#Create_SSL_Certi
#Rewrite_Apache_Conf
#Configure_Tftp
#Configure_Dhcp_Pxe
#Setup_Baadalapp
#Start_Web2py
