This is a bash script for backing up Magento installations. It attempts to pull your database credentials out of local.xml and automate as much as possible.

# What's backed up

* Database
* Database schema (for keeping track of table changes in git)
* Website files and assets

# Requirements

* Bucket with Amazon s3
* xmllint --xpath (some older versions lack this option)
* [Duplicity](http://duplicity.nongnu.org/)

# Setup

```
chmod 755 nightly-backup.sh
crontab -e
0 4 * * * /path/to/nightly-backup.sh
```

# Restoring files

```
duplicity --file-to-restore filename.foo s3+http://bucketname/www ~/restore/location
```