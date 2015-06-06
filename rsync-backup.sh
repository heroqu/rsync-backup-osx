#!/usr/bin/env bash
#
# https://github.com/heroqu/rsync-backup-osx
#
# rsync backup script with time stamp naming style and hardlinking to previous backups.
# Specifically adapted to Mac OS by using GNU utils instead of cp,
# readlink and rsync.
#
# Credits:
# + Mike Rubel article http://www.mikerubel.org/computers/rsync_snapshots/
# + Noah's backup script http://www.noah.org/wiki/Rsync_backup
# + Nicolas Gallagher article http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync
#

############################################################
# Variables to modify

EXCLUDE_FROM="/etc/backup-excludes.txt"
# - read exclude patterns from specified file
#   one can explicitly specify another FILE with -x option
#   (see usage)
DATEFORMAT="%F_%H%M%S"
TIME_STAMP=$(date +"$DATEFORMAT")

# Mac OS specials.
# Here are the problems and workarounds.
#
# 1. cp should support hardlinking: cp -l , but OSX' cp doesn't.
#   to not mess with Mac OS builtins one can simply install
#   GNU utils with Homebrew and use gcp instead:
#     brew install coreutils
CP_UTIL='/usr/local/bin/gcp'
#
# 2. readlink should support -e option. Same story: use greadlink instead
READLINK_UTIL='/usr/local/bin/greadlink'
#
# 3. OSX' rsync is OK with this script,
#   but still we can use the newest one installed with Homebrew:
#     brew install rsync
RSYNC_UTIL='/usr/local/bin/rsync' # instead of regular '/usr/bin/rsync'

# Main rsync options to be used

RSYNC_OPTS="-a --delete --delete-excluded --exclude-from=$EXCLUDE_FROM -xSX"

# Attention to last tree ones:
#
# -x, --one-file-system       don't cross filesystem boundaries
# -S, --sparse                handle sparse files efficiently
# -X, --xattrs                preserve extended attributes

############################################################

usage () {
  cat <<EOF

 usage:
  $0 [-t TAG] [-x EXCLUDE_FROM][-v] SOURCE_PATH BACKUP_PATH
  SOURCE_PATH and BACKUP_PATH may be ssh-style remote paths; although,
  BACKUP_PATH is usually a local directory where you want
    the backup set stored.
  -t : TAG.
         Can be one of 'daily','weekly','monthly', 'yearly' or omitted.
  -x : explicitly set the FILE for the following rsync option:
         "--exclude-from=FILE     read exclude patterns from FILE"
       when omitted, the following default value will be used:
         "$EXCLUDE_FROM"
  -v : set verbose mode.

EOF
}


############################################################
# Arguments parsing

# defaults:
VERBOSE=0
TAG=''

# options
while getopts "t:x:vh" opt; do
  case $opt in
    t)
      case $OPTARG in
        daily) TAG='.daily';;
        monthly) TAG='.monthly';;
        weekly) TAG='.weekly';;
        yearly) TAG='.yearly';;
      esac
    ;;
    x)
      EXCLUDE_FROM=$($READLINK_UTIL -f $OPTARG);
      if [ ! -f $EXCLUDE_FROM ]; then
        echo
        echo "file specified in '-x EXCLUDE_FROM' option is not found:"
        echo "  $OPTARG"
        echo
        usage
        exit 1
      fi
    ;;
    v) VERBOSE=1;;
    # n ) NORMALIZE_PERMS=1;;
    h) usage
      exit 1;;
    \?) usage
      exit 1;;
    *) usage
      exit 1;;
  esac
done

# extract last two args
shift $(($OPTIND - 1))
SOURCE_PATH=$1
BACKUP_PATH=$2

if [ -z $SOURCE_PATH ] ; then
    echo "Missing argument. Give source path and backup path."
    usage
    exit 1
fi
if [ -z $BACKUP_PATH ] ; then
    echo "Missing argument. Give source path and backup path."
    usage
    exit 1
fi

SOURCE_BASE=`basename $SOURCE_PATH`

# additional options:
# -v, --verbose               increase verbosity
# -q, --quiet                 suppress non-error messages
if [ $VERBOSE -eq 1 ]; then
    RSYNC_OPTS="$RSYNC_OPTS -v"
    date
else
    RSYNC_OPTS="$RSYNC_OPTS -q"
fi


############################################################
# pseudo random string generator
rndstr8()
{
  local N B
	for (( N=0; N < 4; ++N ))
	do
		B=$(( $RANDOM%256 ))
    printf '%02x' $B
	done
	echo
}

############################################################

# Use special destination subdir if we are backing up root dir
if [ "${SOURCE_BASE}" = "/" ]; then
  SOURCE_BASE='_ROOT_'
fi

# Destination base path
DEST_BASE="${BACKUP_PATH%/}/${SOURCE_BASE}"

############################################################
# Prepare some directory names

# Temporary directory to place new backup to
BK_TMP="${DEST_BASE}.${TIME_STAMP}.$(rndstr8).tmp"

mkdir -p "$BK_TMP"

# "Permanent" pointer to the most recent backup
# (should be updated after each successfull backup operation)
BK_LAST_LINK="${DEST_BASE}.last_link"

# if such a pointer was set in some earlier backup,
# then now we can retrieve physical path to last backup directory:

BK_LAST=$($READLINK_UTIL -e $BK_LAST_LINK)

if ! [ "$BK_LAST" = "" ]; then
  # Previous backup found,
  # let's use it as target for hardlinking to a place where
  # new backup is going to go

  # echo "cp -al started"
  $CP_UTIL -al "$BK_LAST/." "$BK_TMP/."
  # echo "cp -al finished"
fi

############################################################
# The backup

# echo "rsync started"
$RSYNC_UTIL $RSYNC_OPTS "$SOURCE_PATH/." "${BK_TMP}/."
# echo "rsync finished"


############################################################
# post backup operations

RSYNC_EXIT_STATUS=$?

# Ignore error code 24, "rsync warning:
# some files vanished before they could be transferred".
if [ $RSYNC_EXIT_STATUS -eq 24 ] ; then
    RSYNC_EXIT_STATUS=0
fi

# Create a timestamp file to show when backup process completed successfully.

BK_ERR="${BK_TMP}/BACKUP_ERROR"
BK_TS="${BK_TMP}/BACKUP_TIMESTAMP"

if [ $RSYNC_EXIT_STATUS -eq 0 ] ; then
    rm -f "$BK_ERR"
    echo "$TIME_STAMP" > "$BK_TS"
else # Create a timestamp if there was an error.
    rm -f "$BK_TS"
    cat <<EOF > "$BK_ERR"
rsync failed
Date: $TIME_STAMP
Exit status: $RSYNC_EXIT_STATUS
EOF
fi

# renaming

if [ $RSYNC_EXIT_STATUS -eq 0 ] ; then
  # backup was successful. Bestow it with a shiny new name:
  BK_LAST="$DEST_BASE.${TIME_STAMP}${TAG}"
  mv "$BK_TMP" "$BK_LAST"

  # update permanent link to most recent successful backup directory
  if [ -L "$BK_LAST_LINK" ];  then
    rm "$BK_LAST_LINK"
  fi
  ln -s "$BK_LAST" "$BK_LAST_LINK"
fi


############################################################

exit $RSYNC_EXIT_STATUS

#
