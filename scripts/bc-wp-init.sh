#!/bin/bash

cp ./provision/default.yml ./site.yml

while [[ -z $domain ]]; do
    printf "Domain name (eg. promocode.co.ke): "; read domain
done

sed -i -e "/hostname:/s/.*/hostname: $domain/" site.yml

printf "Specify version of PHP (choose item numer, eg. 1 for php 5.6 installation)\n1) PHP 5.6\n2) PHP 7.0 <-- default value \n3) PHP 7.1\n4) PHP 7.2\n5) PHP 7.3\n6) PHP 7.4\nEnter number (PHP 7.0 as default): "; read php_version_number

case $php_version_number in
  "1")
        php_fpm='5.6'
        ;;
  "2")
        php_fpm='7.0'
        ;;
  "3")
        php_fpm='7.1'
        ;;
  "4")
        php_fpm='7.2'
        ;;
  "5")
        php_fpm='7.3'
        ;;
  "6")
        php_fpm='7.4'
        ;;
  "*"|"")
        php_fpm='7.0'
esac


echo "You are going to set up PHP $php_fpm"
sed -i -e "/php_fpm:/s/.*/php_fpm: $php_fpm/" site.yml

echo "Evaluating ip address for new vagrant box..."
nextip(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed 's/../0x& /g'`)
    echo "$NEXT_IP"
}

case "$OSTYPE" in 
    linux*)  hosts_file="/etc/hosts" ;;
    darwin*)  hosts_file="/etc/hosts" ;;
    msys*)  
        hosts_file="C:\Windows\System32\drivers\etc\hosts"
        ;;
    *)
        echo "OS could not be determined, please stall the installation of local development environment and contact DevOps"
        exit 1
        ;;
esac

if [[ -n `cat $hosts_file | grep $domain` ]]
then
    ip=`cat $hosts_file | grep $domain | awk ' { print $1} ' | uniq`
else
    max_used_ip=`cat $hosts_file | grep -E '^192.168.33' | awk ' { print $1} ' | sort | uniq | tail -n 1`
    [[ -n $max_used_ip ]] && ip=$(nextip $max_used_ip) || ip="192.168.33.10"
fi

echo "Address $ip will be used for new vagrant box"
sed -i -e "/^ip:/s/.*/ip: $ip/" site.yml

echo -n "Do you want to work on an existing Wordpress website (y/n)?"
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo -e "\nInstallation steps: "
    echo "1) Run '$ vagrant up' and make sure to provision."
    echo "2) Replace the files from the existing Wordpress application with the files in ./wordpress/, except ./wordpress/phpmyadmin directory."
    echo "3) Login to phpMyAdmin at http://$domain/phpmyadmin, on database 'wordpress', with username 'wordpress' and password 'wordpress', and import your existing database. Make sure your wp-config.php matches these database credentials."
    echo "4) Enjoy developing with your files at ./wordpress/ shared with vm folder /var/www/html, with local access at http://$domain."
else
    printf "Website title: "; read title
    sed -i -e "/title:/s/.*/title: $title/" site.yml

    printf "Website description: "; read description
    sed -i -e "/blogdescription:/s/.*/  blogdescription: $description/" site.yml

    printf "WordPress version (eg. latest): "; read wp_version
    sed -i -e "/version:/s/.*/version: $wp_version/" site.yml

    printf "Wordpress username (eg. admin): "; read wp_username
    sed -i -e "/admin_user:/s/.*/admin_user: $wp_username/" site.yml

    printf "Wordpress password (eg. admin): "; read wp_password
    sed -i -e "/admin_pass:/s/.*/admin_pass: $wp_password/" site.yml

    echo -e "\nInstallation Steps:"
    echo "1) Run '$ vagrant up' and make sure to provision."
    echo "2) Enjoy developing with your files at ./wordpress/ shared with vm folder /var/www/html, with local access at http://$domain."
    echo "3) You can manage the database from phpMyAdmin at http://$domain/phpmyadmin with database 'wordpress', with username 'wordpress' and password 'wordpress'."
fi

echo ""
echo "Renaming bc-wordpress-development/ directory to ${domain}/"
mv "$PWD" "${PWD%/*}/${domain}"
exec ${SHELL}
