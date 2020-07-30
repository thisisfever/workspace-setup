#!/usr/bin/env bash
clear
###############################################################################
# setup.sh
# If  you  are unable to run this script with
# ./setup.sh  then  you probably need to set it's permissions.  You can do this
# by typing the following:
#
# chmod 755 setup.sh
#
# after this has been done, you can type ./setup.sh to run the script.
#
###############################################################################

if [ "$(id -u)" != "0" ]; then
	echo "You must be root to execute the script. Exiting."
	exit 1
fi

# accept user input for username
echo "Username: (lowercase)"
read -e wsuser

# accept user input for db
echo "Database User:"
read -e wsdbuser
echo "Database Password:"
read -e wsdbpass

wspass=$(hostname | md5sum)

# add a simple yes/no confirmation before we proceed
echo "Run Install? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
exit
else

useradd -m "$wsuser" -p "$wspass"
usermod -aG sudo "$wsuser"
usermod -aG www-data "$wsuser"

echo "Match User $wsuser
PasswordAuthentication yes" >> /etc/ssh/sshd_config

echo "$wsuser ALL=(ALL:ALL) NOPASSWD: ALL" | sudo env EDITOR="tee -a" visudo

# Update list of available packages
apt-get update -y -q
# Install the most common packages that will be usefull under development environment
apt-get install zip unzip htop software-properties-common -y -q
# Install PHP-FPM
apt-add-repository ppa:ondrej/php -y -q
apt-get update -y -q
apt -y install php7.4
apt-get install -y php7.4-{fpm,cli,bcmath,bz2,zip,intl,gd,mbstring,mysql,zip,pdo,json,curl,xml,sqlite,imagick}
systemctl disable --now apache2

# # Create a folder to backup current installation of Nginx && PHP-FPM
# now=$(date +"%Y-%m-%d_%H-%M-%S")
# mkdir /backup/
# mkdir /backup/$now/nginx/ && mkdir /backup/$now/php/ && mkdir /backup/$now/mysql/
# # Create a full backup of previous Nginx configuration
# cp -r /etc/nginx/ /backup/$now/nginx/
# # Create a full backup of previous PHP configuration
# cp -r /etc/php/ /backup/$now/php/
# # Create a full backup of previous MySQL configuration
# cp -r /etc/mysql/ /backup/$now/mysql/
# # Delete previous Nginx installation
# apt-get purge nginx-core nginx-common nginx -y -q
# apt-get autoremove -y -q

# Update list of available packages
apt-get update -y -q
# Install custom Nginx package
apt-get install nginx -y -q

# Set Default PHP-FPM Limits
sed -i "s/memory_limit = .*/memory_limit = -1/" /etc/php/7.4/fpm/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.4/fpm/php.ini
sed -i "s/max_input_time = .*/max_input_time = 90/" /etc/php/7.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 512M/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 512M/" /etc/php/7.4/fpm/php.ini
# Create default file for Nginx with dynamic virtual hosts
wget -O /etc/nginx/sites-available/default.conf https://raw.githubusercontent.com/thisisfever/workspace-setup/master/default.conf
sed -i "s/<user>/$wsuser/" /etc/nginx/sites-available/default.conf
# Create nginx.conf
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/thisisfever/workspace-setup/master/nginx.conf
sed -i "s/<user>/$wsuser/" /etc/nginx/nginx.conf
# Add repository for MariaDB 10.5
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.5/ubuntu focal main'
# Update list of available packages
apt-get update -y -q
# Use md5 hash of your hostname to define a root password for MariaDB
password=$(hostname | md5sum | awk '{print $1}')
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password password $password"
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password_again password $password"
# Install MariaDB package
apt-get install mariadb-server -y -q
# Add custom configuration for your Mysql
# All modified variables are available at https://mariadb.com/kb/en/library/server-system-variables/
echo -e "\n[mysqld]\nmax_connections=24\nconnect_timeout=10\nwait_timeout=10\nthread_cache_size=24\nsort_buffer_size=1M\njoin_buffer_size=1M\ntmp_table_size=8M\nmax_heap_table_size=1M\nbinlog_cache_size=8M\nbinlog_stmt_cache_size=8M\nkey_buffer_size=1M\ntable_open_cache=64\nread_buffer_size=1M\nquery_cache_limit=1M\nquery_cache_size=8M\nquery_cache_type=1\ninnodb_buffer_pool_size=8M\ninnodb_open_files=1024\ninnodb_io_capacity=1024\ninnodb_buffer_pool_instances=1" >> /etc/mysql/my.cnf
# Write down current password for MariaDB in my.cnf
echo -e "\n[client]\nuser = root\npassword = $password" >> /etc/mysql/my.cnf
# Restart MariaDB
service mysql restart
# Create DB user
Q1="CREATE USER '$wsdbuser'@'localhost' IDENTIFIED BY '$wsdbpass';"
Q2="GRANT ALL privileges ON *.* TO '$wsdbuser'@localhost;"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
mysql -uroot -p -e "$SQL"

# Create default folder for future websites
mkdir /home/$wsuser/projects
# Give Nginx permissions to be able to access these websites
chown -R www-data:www-data /home/$wsuser/projects/*
# Set default user permissions
chmod g+s /home/$wsuser/projects/*
setfacl -d -m group:www-data:rwx /home/$wsuser/projects/*
# Maximize the limits of file system usage
echo -e "*       soft    nofile  1000000" >> /etc/security/limits.conf
echo -e "*       hard    nofile  1000000" >> /etc/security/limits.conf
# Switch to the ondemand state of PHP-FPM
sed -i "s/^pm = .*/pm = ondemand/" /etc/php/7.4/fpm/pool.d/www.conf
# Reload Nginx installation
systemctl restart nginx
# Reload PHP-FPM installation
systemctl reload php7.4-fpm.service

# Install Yarn
npm install -g yarn

# Install Composer
curl -sS https://getcomposer.org/installer -o composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Install dnsmasq for dynamic hostname support (Browsersync needs hostnames setup within the workspace)
systemctl disable systemd-resolved
systemctl stop systemd-resolved
apt-get install dnsmasq -y -q
rm /etc/resolv.conf
echo "nameserver 127.0.0.1
nameserver 8.8.8.8" > /etc/resolv.conf
echo "listen-address=127.0.0.1
bind-interfaces
address=/test/127.0.0.1" >> /etc/dnsmasq.conf
echo "prepend domain-name-servers 127.0.0.1;" >> /etc/dhcp/dhclient.conf
systemctl restart dnsmasq

# Download post install script
wget -O /home/$wsuser/post.sh https://raw.githubusercontent.com/thisisfever/workspace-setup/master/post-setup.sh
chmod 755 setup.sh


echo "================================================================="
echo ""
echo "Workspace is almost ready! Your username/password is listed below."
echo ""
echo "Username: $wsuser"
echo "Password: $wspass"
echo ""
echo "Please login with these details and run ./post.sh"
echo "================================================================="
fi
