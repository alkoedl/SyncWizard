#!/bin/sh


#
# restore partition D from backup rsync/d/2009-12-11_19-57-36
#


#
# find backup drive
#

BACKUPDRIVEIDENTIFIER=Buffalo.txt

for i in `mount | awk '{print $3}'`
  do
  if [ -f ${i}/${BACKUPDRIVEIDENTIFIER} ]
      then
      export BACKUPDRIVE=${i}
      echo "$0: Backup drive = $BACKUPDRIVE"
  fi
done


if [ "$BACKUPDRIVE" == "" ]; then
    echo "$0: Couldn't find backup drive."
    echo "Backup drive must contain file ${BACKUPDRIVEIDENTIFIER} on top level."
    exit
fi


#VVV=${ZZZ:-DefaultVal\}
#Thus we assign the value of $ZZZ to VVV if ZZZ has a value, otherwise we assign DefaultVal.




echo "$0: Backup drive = ${BACKUPDRIVE}"

#PATH=/cygdrive/d/rsync/bin:$PATH
date='2009-12-11_19-57-36'
startdate=`date "+%Y-%m-%d_%H-%M-%S"`

nice rsync.exe -a -u --progress --exclude "a68950091237b56a9503abe2fa465c" --exclude "cygwin/" --exclude "System Volume Information/" --exclude "BOOT_SAV.BOT" --exclude "VOL_CHAR.DAT" --exclude "PROT_INS.SYS" ${BACKUPDRIVE}/rsync/d/$date/ /cygdrive/d/

enddate=`date "+%Y-%m-%d_%H-%M-%S"`
echo "$0: $startdate"
echo "$0: $enddate"
