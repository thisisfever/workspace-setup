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
echo "Username:"
read -e wsuser_original

wsuser=$(echo "$wsuser_original" | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)

# accept user input for db
echo "Database User:"
read -e wsdbuser
echo "Database Password:"
read -e wsdbpass

# generate password
wspass=$(openssl rand -base64 14)

# get ip address
wsip=$(wget -qO - ipv4bot.whatismyipaddress.com)

# add a simple yes/no confirmation before we proceed
echo "Run Install? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
exit
else

# Create new user and add to groups
useradd -m "$wsuser" -p "$wspass"
usermod -aG sudo "$wsuser"
usermod -aG www-data "$wsuser"
echo "Match User $wsuser
PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "$wsuser ALL=(ALL:ALL) NOPASSWD: ALL" | sudo env EDITOR="tee -a" visudo

# Update list of available packages
apt-get update -y -q
# Install the most common packages that will be useful under development environment
apt-get install zip unzip htop software-properties-common -y -q

# Install PHP-FPM
apt-add-repository ppa:ondrej/php -y -q
apt-get update -y -q
apt -y install php7.4
apt-get install -y php7.4-{fpm,cli,bcmath,bz2,zip,intl,gd,mbstring,mysql,zip,pdo,json,curl,xml,sqlite,imagick}
systemctl disable --now apache2
# Set Default PHP-FPM Limits
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/fpm/php.ini
sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.4/fpm/php.ini
sed -i "s/max_input_time = .*/max_input_time = 120/" /etc/php/7.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 512M/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 512M/" /etc/php/7.4/fpm/php.ini
# Switch to the ondemand state of PHP-FPM
sed -i "s/^pm = .*/pm = ondemand/" /etc/php/7.4/fpm/pool.d/www.conf
# Reload PHP-FPM installation
systemctl reload php7.4-fpm.service

# Install Nginx
apt-get install nginx -y -q
# Create default file for Nginx with dynamic virtual hosts
mkdir /home/$wsuser/config
mkdir /home/$wsuser/config/nginx
wget -O /home/$wsuser/config/nginx/default.conf https://raw.githubusercontent.com/thisisfever/workspace-setup/master/default.conf
sed -i "s/<user>/$wsuser/" /home/$wsuser/config/nginx.conf
# Create nginx.conf
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/thisisfever/workspace-setup/master/nginx.conf
sed -i "s/<user>/$wsuser/" /etc/nginx/nginx.conf
# Reload Nginx installation
systemctl restart nginx

# Add repository for MariaDB 10.5
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.5/ubuntu focal main'
apt-get update -y -q
# Use md5 hash of your hostname to define a root password for MariaDB
password=$(hostname | md5sum | awk '{print $1}')
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password password $password"
debconf-set-selections <<< "mariadb-server-10.5 mysql-server/root_password_again password $password"
# Install MariaDB package
apt-get install mariadb-server -y -q
# Add custom configuration for MariaDB
# All modified variables are available at https://mariadb.com/kb/en/library/server-system-variables/
echo -e "\n[mysqld]\nmax_connections=24\nconnect_timeout=10\nwait_timeout=10\nthread_cache_size=24\nsort_buffer_size=1M\njoin_buffer_size=1M\ntmp_table_size=8M\nmax_heap_table_size=1M\nbinlog_cache_size=8M\nbinlog_stmt_cache_size=8M\nkey_buffer_size=1M\ntable_open_cache=64\nread_buffer_size=1M\nquery_cache_limit=1M\nquery_cache_size=8M\nquery_cache_type=1\ninnodb_buffer_pool_size=8M\ninnodb_open_files=1024\ninnodb_io_capacity=1024\ninnodb_buffer_pool_instances=1" >> /etc/mysql/my.cnf
# Save password for MariaDB in my.cnf
echo -e "\n[client]\nuser = root\npassword = $password" >> /etc/mysql/my.cnf
# Restart MariaDB
service mysql restart
# Create DB user
Q1="CREATE USER '$wsdbuser'@'localhost' IDENTIFIED BY '$wsdbpass';"
Q2="GRANT ALL privileges ON *.* TO '$wsdbuser'@localhost;"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
mysql -uroot -p -e "$SQL"

# Maximize the limits of file system usage
echo -e "*       soft    nofile  1000000" >> /etc/security/limits.conf
echo -e "*       hard    nofile  1000000" >> /etc/security/limits.conf

# Create default folder for future websites
mkdir /home/$wsuser/projects
# Give Nginx permissions to be able to access these websites
chown -R www-data:www-data /home/$wsuser/projects
# Set default user permissions
chmod 775 /home/$wsuser/projects
chmod g+s /home/$wsuser/projects
# Create logs folder
mkdir /home/$wsuser/logs
# Give Nginx permissions to be able to access logs
chown -R www-data:www-data /home/$wsuser/logs
chmod g+s /home/$wsuser/logs

# Get new project script
wget -O /home/$wsuser/config/new.sh https://raw.githubusercontent.com/thisisfever/workspace-setup/master/new.sh
chmod 755 /home/$wsuser/config/new.sh

# Install Yarn
npm install -g yarn

# Install Composer
curl -sS https://getcomposer.org/installer -o composer-setup.php
HASH=`curl -sS https://composer.github.io/installer.sig`
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# # Install dnsmasq for dynamic hostname support (Browsersync needs hostnames setup within the workspace)
# systemctl disable systemd-resolved
# # sudo systemctl enable systemd-resolved
# systemctl stop systemd-resolved
# # sudo systemctl start systemd-resolved
# apt-get install dnsmasq -y -q
# rm /etc/resolv.conf
# echo "nameserver 127.0.0.1
# nameserver 8.8.8.8" > /etc/resolv.conf
# echo "listen-address=127.0.0.1
# bind-interfaces
# address=/test/127.0.0.1" >> /etc/dnsmasq.conf
# echo "prepend domain-name-servers 127.0.0.1;" >> /etc/dhcp/dhclient.conf
# systemctl restart dnsmasq

# Install NVM to manage Node
sudo wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
# Use NVM to install latest LTS node version
sudo nvm install --lts

# Install Yarn
sudo npm install -g yarn

# Install ZSH Shell
sudo apt install zsh -y -q
# Install Oh My ZSH
git clone https://github.com/ohmyzsh/ohmyzsh.git /home/$wsuser/.oh-my-zsh
# Install autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions /home/$wsuser/.oh-my-zsh/custom/plugins/zsh-autosuggestions
# Create default .zshrc config
sudo wget -O /home/$wsuser/.zshrc https://raw.githubusercontent.com/thisisfever/workspace-setup/master/.zshrc
chmod 755 /home/$wsuser/config/new.sh
chown -R $wsuser:$wsuser /home/$wsuser/.zshrc

# Update all packages
apt update && apt upgrade

echo "==========================================================="
cat <<-'EOF'
 _    _  ___________ _   __ ___________  ___  _____  _____
| |  | ||  _  | ___ \ | / //  ___| ___ \/ _ \/  __ \|  ___|
| |  | || | | | |_/ / |/ / \ `--.| |_/ / /_\ \ /  \/| |__
| |/\| || | | |    /|    \  `--. \  __/|  _  | |    |  __|
\  /\  /\ \_/ / |\ \| |\  \/\__/ / |   | | | | \__/\| |___
 \/  \/  \___/\_| \_\_| \_/\____/\_|   \_| |_/\____/\____/

EOF
echo "==========================================================="
echo ""
echo "Your workspace is ready!"
echo ""
echo "Username:   $wsuser"
echo "Password:   $wspass"
echo "IP Address: $wsip"
echo ""
echo "-----------------------------------------------------------"
echo ""
echo "Please SSH into the server with above details and run:"
echo ""
echo "sudo chsh -s $(which zsh)"
echo ""
echo "-----------------------------------------------------------"
echo ""
fi
