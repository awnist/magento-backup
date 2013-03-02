#!/bin/bash
#
# Nightly backup script for Magento - http://github.com/awnist/magento-backup

# Amazon s3 bucket
	export AWS_ACCESS_KEY_ID=xxxx
	export AWS_SECRET_ACCESS_KEY=xxxx
	S3_BUCKET=xxxx

# Magento location
	magento="/var/www"

# Backup folder locations
	declare -A backups
	#backups=([name]="location" [name]="location")
	backups=([www]=$magento)

# Excludes, relative within folder location
	declare -A excludes
	excludes=([www]="var/.git:var/session:var/cache")




## Backup database
	backupdir=$magento/var/backups/database

	declare -A db

	# Get database values from Magento xml, variables available in ${db[..]}
	for get in host username password dbname
	do
		db[$get]=\"$(xmllint --xpath "string(//config/global/resources/default_setup/connection/$get)" $magento/app/etc/local.xml)\"
	done
	# Or, set manually:
	# db=([host]="..." [username]="..." [password]="..." [dbname]="...")

	# Make sure directory exists
	mkdir -p $backupdir

	# Create schema log
	mysqldump --no-data --skip-set-charset --skip-comments --skip-lock-tables --all-databases -u ${db[username]} -h ${db[host]} -p${db[password]} >$backupdir/schema.log

	# Create backup
	# alternatively, add a [db]="/path/to/automysqlbackup" in "Backup folder locations" above and comment the
	# following lines out
	mysqldump -u ${db[username]} -h ${db[host]} -p${db[password]} --all-databases | gzip > $backupdir/database_`date '+%m-%d-%Y'`.sql.gz
	# Delete old backups
	find $backupdir -mtime +7 -exec rm {} \;


## Backup entire site using duplicity

	for b in "${!backups[@]}"
	do
		DEST=s3+http://${S3_BUCKET}/${b}
		SOURCE=${backups[$b]}
		EXCLUDE=(${excludes[$b]//:/ })

		echo "Backing up ${SOURCE} to ${DEST}"

		duplicity \
			--verbosity error \
			#--no-encryption \
			--full-if-older-than 1M \
			$(printf "\055\055exclude ${SOURCE}/%s " "${EXCLUDE[@]}") \
			${SOURCE} ${DEST}

		duplicity remove-older-than 6M --force ${DEST}

		echo
	done

## Cleanup

	export AWS_ACCESS_KEY_ID=
	export AWS_SECRET_ACCESS_KEY=
	export PASSPHRASE=
