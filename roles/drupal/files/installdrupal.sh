#!/bin/bash

SITE_NAME=${1}
ACCOUNT_NAME=${2}
ACCOUNT_PASS=${3}
DB_URL=${4}

DRUPAL_ROOT=/var/www/drupal/web
SHARED_ROOT=/gfstorage/drupalsite

if [ ! -d $SHARED_ROOT/files ] && [ ! -f $SHARED_ROOT/drupal.lock ]; then
    touch $SHARED_ROOT/drupal.lock
    echo "first node: " >> $SHARED_ROOT/drupal.lock
    echo $(hostname) >> $SHARED_ROOT/drupal.lock
    IS_FIRST_NODE=true
    echo "lock created!"
fi

if [ "$IS_FIRST_NODE" = true ]; then
    mkdir -p $SHARED_ROOT/files
fi

cd $DRUPAL_ROOT/sites/default/
if [ ! -d files ]; then
    ln -s $SHARED_ROOT/files files
fi

if [ "$IS_FIRST_NODE" = true ]; then
    cp default.settings.php $SHARED_ROOT/settings.php
    cp default.services.yml $SHARED_ROOT/services.yml
    echo "copied settings.php and services.yml to file share"
    echo "copied settings.php and services.yml to file share" >> $SHARED_ROOT/drupal.lock
else
    while [ ! -f $SHARED_ROOT/firstnode.done ];
    do
        sleep 30
        echo "Sleeping, wait for 1st node to install the drupal site."
    done
    echo "directory created. exit sleep loop."
fi

ln -s $SHARED_ROOT/settings.php ./settings.php
ln -s $SHARED_ROOT/services.yml ./services.yml
echo "created sym links."

if [ "$IS_FIRST_NODE" = true ]; then
    # change file permission
    chmod -R 777 $DRUPAL_ROOT/sites/default/files/
    chmod -R 755 $DRUPAL_ROOT/sites/default/
    chmod 777 $DRUPAL_ROOT/sites/default/settings.php
    chmod 777 $DRUPAL_ROOT/sites/default/services.yml
    echo "modified permission on files."
    echo "modified permission on files." >> $SHARED_ROOT/drupal.lock
    # install drupal site
    cd $DRUPAL_ROOT
    echo "start to install drupal site."
    echo "start to install drupal site." >> $SHARED_ROOT/drupal.lock
    ../vendor/drush/drush/drush si standard -y --site-name="$SITE_NAME" --account-name="$ACCOUNT_NAME" --account-pass="$ACCOUNT_PASS" --db-url="$DB_URL"
    echo "drupal site created."
    echo "drupal site created." >> $SHARED_ROOT/drupal.lock
    touch $SHARED_ROOT/firstnode.done
fi