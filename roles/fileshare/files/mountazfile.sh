#!/bin/bash

STORAGE_ACCOUNT=${1}
FILESHARE_NAME=${2}
STORAGE_ACCOUNT_KEY=${3}

mntpath="/mnt/drupalsite"
if [ ! -d $mntpath ]; then
    mkdir -p $mntpath
fi

if [ ! -d "/etc/smbcredentials" ]; then
    mkdir "/etc/smbcredentials"
fi

smbCredentialFile="/etc/smbcredentials/$STORAGE_ACCOUNT.cred"
if [ ! -f $smbCredentialFile ]; then
    echo "username=$STORAGE_ACCOUNT" | tee $smbCredentialFile > /dev/null
    echo "password=$STORAGE_ACCOUNT_KEY" | tee -a $smbCredentialFile > /dev/null
else 
    echo "The credential file $smbCredentialFile already exists, and was not modified."
fi

chmod 600 $smbCredentialFile

httpEndpoint="https://$STORAGE_ACCOUNT.file.core.windows.net/"
smbPath=$(echo $httpEndpoint | cut -c7-$(expr length $httpEndpoint))$FILESHARE_NAME

if [ -z "$(grep $smbPath\ $mntpath /etc/fstab)" ]; then
    echo "$smbPath $mntpath cifs nofail,vers=3.0,credentials=$smbCredentialFile,serverino" | tee -a /etc/fstab > /dev/null
else
    echo "/etc/fstab was not modified to avoid conflicting entries as this Azure file share was already present. You may want to double check /etc/fstab to ensure the configuration is as desired."
fi

mount -a