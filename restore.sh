if ! rpm -qa | grep epel-release; then
    yum install epel-release
    yum install xmlstarlet
fi

if ! rpm -qa | grep xmlstarlet; then

    yum install xmlstarlet
fi


Taracilacakdosya=$1
dizinadi=${Taracilacakdosya:0:20}
mkdir /root/$dizinadi
tar -xvzf $1 -C /root/$dizinadi



#!/bin/bash
masterDomains=($(xmlstarlet select --template --value-of /metaFile/masterDomain --nl /root/$dizinadi/meta.xml ))
domain=($(xmlstarlet select --template --value-of /metaFile/ChildDomains/domain/domain --nl /root/$dizinadi/meta.xml ))
phpSelection=($(xmlstarlet select --template --value-of /metaFile/phpSelection --nl /root/$dizinadi/meta.xml ))
dbName=($(xmlstarlet select --template --value-of /metaFile/Databases/database/dbName --nl /root/$dizinadi/meta.xml))
dbUser=($(xmlstarlet select --template --value-of /metaFile/Databases/database/dbUser --nl /root/$dizinadi/meta.xml))
dbPassword=($(xmlstarlet select --template --value-of /metaFile/Databases/database/password --nl /root/$dizinadi/meta.xml))
email=($(xmlstarlet select --template --value-of /metaFile/emails/emailAccount/email --nl /root/$dizinadi/meta.xml))
cpanelUser=${masterDomains:0:8}


echo "$masterDomains is masterDomains"
echo "$domain is domain"
echo "$phpSelection is phpSelection"
echo "$dbName is dbName"
echo "$dbUser is dbUser"
echo "$dbPassword is dbPassword"
# echo "$email is email"


whmapi1 createacct username=$cpanelUser domain=$masterDomains



for i in ${!dbName[*]}
do
  echo "$i" "${dbName[$i]}"
  uapi --user=$cpanelUser Mysql create_database name=$dbName
done
echo "dbName bitti"



for i in ${!dbUser[*]}
do
  echo "$i" "${dbUser[$i]}"
  uapi --user=$cpanelUser Mysql create_user name=${dbUser[$i]} password="${dbPassword[$i]}"
  uapi --user=$cpanelUser Mysql set_privileges_on_database user=${dbUser[$i]} database=${dbName[$i]} privileges=ALL%20PRIVILEGES
  mysql -uroot ${dbName[$i]} < "/root/$dizinadi/${dbName[$i]}.sql"

  mysql mysql -e "ALTER USER '${dbUser[$i]}'@'localhost' IDENTIFIED BY PASSWORD '${dbPassword[$i]}'"
  mysql mysql -e "flush privileges";

done
echo "dbUser bitti"






for i in ${!email[*]}
do
  echo "$i" "${email[$i]}"
  /scripts/addpop ${email[$i]} Gofast2020 0
done
echo "Email bitti"

rsync -avhP /root/$dizinadi/public_html/ /home/$cpanelUser/public_html

chown -R $cpanelUser:$cpanelUser /home/$cpanelUser

/etc/gofast/fixpermission.sh -v -a $cpanelUser
/etc/gofast/fixpermission.sh -a $cpanelUser



