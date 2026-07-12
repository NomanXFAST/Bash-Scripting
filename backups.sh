#!/bin/bash
<<readme
this is the backup file to manage the 5 day rotation 

Usage:
./days.sh <path of source folder> <path of backup folder>
readme

if [ $# -eq 0 ];then
	echo "Usage: ./days.sh <path of source folders> <path of backup folders>"
fi

sourcedir=$1
timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
backupdir=$2

create_backup(){
	zip -r "${backupdir}/newbackup_${timestamp}.zip" "$sourcedir" > /dev/null
}
perform_rotation(){
	backup=($(ls -t "${backupdir}/newbackup_"*.zip))
	
	if [ "${#backup[@]}" -gt 5 ];then
		echo "Performing rotation for 5 days"
		backup_to_remove=("${backup[@]:5}")
		for backups in "${backup_to_remove[@]}";do
			rm -f "${backups}"
		done
		
	fi


}

create_backup
perform_rotation
