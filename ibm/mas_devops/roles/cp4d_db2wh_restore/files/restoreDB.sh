#!/bin/bash

sudo wvcli system disable -m "Disable HA before Db2 maintenance"
db2 connect to BLUDB
db2 list applications
db2 force application all 
# run db2 list applications command again after the previous command to make sure no apps are connected
db2 terminate 
db2 deactivate database BLUDB
db2stop force
ipclean -a
db2set -null DB2COMM
db2start admin mode restricted access
# backup_dir should be the same directory name where the backup was taken from
# put all the files of the database inside the folder and run:
# chown db2inst1 backup_dir/* to set the right permissions to the right user (assuming db2inst1 took the backup)
# replace <backup_dir> by the directory name where the database backup was taken
# replace the <bckup_image_timestamp> by the timestamp of the backup files which are in the name of the backup files
db2 RESTORE DATABASE BLUDB FROM <backup_dir> TAKEN AT <backup_image_timestamp> INTO BLUDB REPLACE EXISTING
#db2 RESTORE DATABASE BLUDB FROM /mnt/blumeta0/home/db2inst1/db_backup TAKEN AT 20210425203116 INTO BLUDB 
# Result of the command above should be like this (type y when asked):
# https://www.ibm.com/docs/en/db2/11.1?topic=commands-restore-database
# SQL2539W  The specified name of the backup image to restore is the same as the 
# name of the target database.  Restoring to an existing database that is the 
# same as the backup image database will cause the current database to be 
# overwritten by the backup version.
# Do you want to continue ? (y/n) y
# DB20000I  The RESTORE DATABASE command completed successfully.
db2 rollforward db BLUDB to end of backup on all dbpartitionnums and stop
# Result of the command above should be like this:
#                                  Rollforward Status
# 
#  Input database alias                   = BLUDB
#  Number of members have returned status = 1
# 
#  Member ID                              = 0
#  Rollforward status                     = not pending
#  Next log file to be read               =
#  Log files processed                    = S0000031.LOG - S0000031.LOG
#  Last committed transaction             = 2021-04-10-16.34.03.000000 UTC
# 
# DB20000I  The ROLLFORWARD command completed successfully.
db2stop force
ipclean -a
db2set DB2COMM=TCPIP,SSL
db2start
db2 activate db bludb
wvcli system enable -m "Enable HA after Db2 maintenance"
db2 connect to BLUDB
