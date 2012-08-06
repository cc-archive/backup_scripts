#!/bin/bash

# 
# Each server has a script which runs around 21:00 UTC each evening which
# writes a file to a random location in /var with some random content.  This
# script should be run each night just before backups begin.  It checks to make
# sure that the randomly placed file and it's content are actually located in
# yesterday's backup snapshot for each server.  This just provides some very
# small assurance that the backup really did occur, at least enough to copy
# over a file that wasn't in the filesytem previously, along with the correct
# content.
#

SERVERS="\
	a5.creativecommons.org \
	a7.creativecommons.org \
	a8.creativecommons.org \
	a9.creativecommons.org \
	a10.creativecommons.org \
	gandi0.creativecommons.org \
	nagios.creativecommons.org \
	scraper.creativecommons.org \
	open4us.org \
"

YESTERDAY=$(date -u -d yesterday +%Y-%m-%d)

cd /media/storage/backups/creativecommons

for server in $SERVERS
do

	# Descend into yesterdays backup snapshot
	pushd $server/$YESTERDAY/tree > /dev/null

	if [ $? -ne 0 ]; then
		echo -e "Directory $server/$YESTERDAY/tree doesn't exist. Backups still running?\n"
		continue
	fi

	# Split the verification file location and content into separate
	# variables from the control file
	VERIFY_FILE=$(cut -d':' -f 1 var/lib/verify_backup)
	VERIFY_CONTENT=$(cut -d':' -f 2 var/lib/verify_backup)

	# Make sure the verification files exists
	if [ -e "./$VERIFY_FILE" ]; then
		# Make sure that the content of the verificaiton file matches
		# what was recorded in the control file
		ACTUAL_CONTENT=$(cat "./$VERIFY_FILE")
		if [ "$ACTUAL_CONTENT" = "$VERIFY_CONTENT" ]; then
			echo -e "Backup SUCCESSfully verified for ${server} for ${YESTERDAY}.\n"
			# Backup seemed to work. Delete the file.
			rm -f "./$VERIFY_FILE"
		else
			echo -e "Content of the backup verification file on \
${server} does not match that of the control file!\n"
		fi
	else
		echo -e "The backup verification file doesn't exist in backup \
of ${server} for ${YESTERDAY}!\n"
	fi

	popd > /dev/null

done
