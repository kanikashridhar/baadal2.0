# Define required macros here

CURRENT_DIR = $(shell pwd)


start_scheduler: start_apache copy_app 
	#kill all process and start fresh one
	#kill -9 ` ps -aef | grep -i web2py | sort -k 2 -r | sed 1d | awk ' { print $2 } ' 
	#ps -ef | grep web2py | awk '{print $$2}' | xargs sudo kill -9;
	#ps -aef | grep -i web2py | sort -k 2 -r | sed 1d | awk ' { print $$2 } '| xargs sudo kill -9
	kill -9 $(shell ps -ef | grep web2py | awk ' { if(NR==1)print $$2 }')
	su www-data -c "python /home/www-data/web2py/web2py.py -K  baadal &"

start_apache:copy_app www_permissions
	#start apache
	#/etc/init.d/apache2 restart
	#/usr/sbin/apache2 -k start
	service apache2 restart 

www_permissions:copy_app
	chown -R www-data:www-data /home/www-data/web2py/applications/baadal

copy_app: git_pull
	#copy baadal app
	if [ -d "$(CURRENT_DIR)/baadal_backup" ]; then \
		rm -r $(CURRENT_DIR)/baadal_backup; \
	fi
	@mkdir $(CURRENT_DIR)/baadal_backup
	@cp -r /home/www-data/web2py/applications/baadal $(CURRENT_DIR)/baadal_backup
	@rsync -avz --exclude static/baadalapp.cfg --exclude static/startup_data.xml baadalinstallation/baadal/ /home/www-data/web2py/applications/baadal

git_pull: $(CURRENT_DIR)
	#inside git pull
	git pull

