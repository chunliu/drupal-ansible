#!/bin/bash

SITE_NAME=${1}
ACCOUNT_NAME=${2}
ACCOUNT_PASS=${3}
DB_URL=${4}

DRUPAL_ROOT=/var/www/drupal/web

if [ ! -d /mnt/drupalsite/files ] && [ ! -f /mnt/drupalsite/drupal.lock ]; then
    touch /mnt/drupalsite/drupal.lock
    echo "first node: " >> /mnt/drupalsite/drupal.lock
    echo $(hostname) >> /mnt/drupalsite/drupal.lock
    IS_FIRST_NODE=true
    echo "lock created!"
fi

if [ "$IS_FIRST_NODE" = true ]; then
    mkdir -p /mnt/drupalsite/files
fi

cd $DRUPAL_ROOT/sites/default/
if [ ! -d files ]; then
    ln -s /mnt/drupalsite/files files
fi

if [ "$IS_FIRST_NODE" = true ]; then
    cp default.settings.php /mnt/drupalsite/settings.php
    cp default.services.yml /mnt/drupalsite/services.yml
    echo "copied settings.php and services.yml to file share"
    echo "copied settings.php and services.yml to file share" >> /mnt/drupalsite/drupal.lock
else
    while [ ! -d /mnt/drupalsite/files/js ];
    do
        sleep 30
        echo "Sleeping, wait for 1st node to install the drupal site."
    done
    echo "directory created. exit sleep loop."
fi

ln -s /mnt/drupalsite/settings.php ./settings.php
ln -s /mnt/drupalsite/services.yml ./services.yml
echo "created sym links."

if [ "$IS_FIRST_NODE" = true ]; then
    # change file permission
    chmod -R 777 $DRUPAL_ROOT/sites/default/files/
    chmod -R 755 $DRUPAL_ROOT/sites/default/
    chmod 777 $DRUPAL_ROOT/sites/default/settings.php
    chmod 777 $DRUPAL_ROOT/sites/default/services.yml
    echo "modified permission on files."
    echo "modified permission on files." >> /mnt/drupalsite/drupal.lock
    # install drupal site
    cd $DRUPAL_ROOT
    echo "start to install drupal site."
    echo "start to install drupal site." >> /mnt/drupalsite/drupal.lock
    ../vendor/drush/drush/drush si -y --site-name=$SITE_NAME --account-name=$ACCOUNT_NAME --account-pass=$ACCOUNT_PASS --db-url=$DB_URL
    echo "drupal site created."
    echo "drupal site created." >> /mnt/drupalsite/drupal.lock
fi