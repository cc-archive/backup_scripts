#!/bin/sh

#
# This script will pick a directory on /var at random, and then write a file
# inside it with a short random string.  It will then record the file's
# location and ia hash of the current date to a known/fixed location
# (/var/lib/verify_backup). Each day, a script on the backup host will check
# the content of /var/lib/verify_backup in the backup for that day, and then
# proceed to verify that the file specified there actually exists in the
# backup, and with the specified hash. The file's existence in the daily backup
# for this host will be used as a small token of verification that a backup
# actually happened, at least enough to copy a file that wasn't there the day
# before, and with the correct content. 
#

# First delete yesterday's file
YEST_FILE=$(cut -d':' -f1 /var/lib/verify_backup)
rm -f "$YEST_FILE"
if [ $? -ne 0 ]; then
	echo "Failed to delete yesterday's verification file!"
	exit
fi

# Grab a random directory and limit it to /var to avoid getting file changed
# warnings from AIDE
VERIFY_DIR=$(find /var -xdev -type d ! -name ".*" | shuf -n1)

# Current date
CUR_DATE=$(date -u +%Y-%m-%d)

# Create a the verification file name, based on the current date
VERIFY_FILE="${CUR_DATE}_verify_backup"

# Create a full path name
VERIFY_PATH="${VERIFY_DIR}/${VERIFY_FILE}"

# Create a hash of the current date for the content of file.  The `cut`
# at the end is because the sha1sum command spits out a trailing hyphen
# when input is from STDIN.  We don't really want that.
DATE_HASH=$(echo $(date -u) | sha1sum - | cut -d' ' -f1)

# Record the location of the verification file
echo "${VERIFY_PATH}:${DATE_HASH}" > /var/lib/verify_backup

# Write our hast to the file
echo $DATE_HASH > $VERIFY_PATH 

# Cross our fingers...
