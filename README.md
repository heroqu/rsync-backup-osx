# rsync-backup-osx

Rsync based backup script for \*NIX systems, especially adapted for *Mac OS*

### Motivation

Use most simple and reliable rsync + crontab backup scheme that would effectively replace time-machine functionality

### Credits and inspiration

+ Some [enlightment](http://www.jwz.org/blog/2007/09/psa-backups/) from Jamie Zawinski to heal the brain
+ Mike Rubel's [Easy Automated Snapshot-Style Backups with Linux and Rsync](http://www.mikerubel.org/computers/rsync_snapshots/) arctile - great short 'Intro' reading on backup strategies and hardlinking.
+ Noah's backup [script](http://www.noah.org/wiki/Rsync_backup).
+ Great [blog & script](http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync) by Nicolas Gallagher.
+ Marian Boricean's [Using rsync as a backup solution](http://dantux.com/weblog/2009/03/23/using-rsync-as-a-backup-solution/)
+ All of you wonderful guys who blog and github and share your tips and thoughts on bash, rsync and all the rest.

### Ideas and features

- script should use hard linking to last successful backup of "similar signature" to save space and time
  - there are two ways to do it I know of: ```cp -l``` and ```rsync --link-dest```, I've chosen the first one
- should be simple to use and setup
  - use crontab
- Be adjusted to Mac OSX environment which is often filled with outright outdated UNIX utils
  - use fresh GNU utils instead
- no deletion of older backups
  - no need for me personally yet. Simple to do with numbered style of backing up when directories are named bk.0, bk.1, bk.N - just shift dirs by 1 and delete the biggest numbered one.
  Little more complicated if naming scheme is ```bk.2015-05-29```, ```bk.2015-05-28``` etc. - one can parse suffixes or just rely on creation date. Again, I don't need it yet.
- use of exclude file
- date-time suffix naming scheme:

```
/Volumes/BK_DISK/home_backups/john.2015-05-28_235958
/Volumes/BK_DISK/home_backups/john.2015-05-29_215233
/Volumes/BK_DISK/home_backups/john.2015-05-30_120144
/Volumes/BK_DISK/home_backups/john.last_link -> john.2015-05-30_120144
...
```

here ```john.last_link``` is symlink to most recent backup directory ```john.2015-05-30_120144```

  - use of 'daily', 'weeky', 'monthly' and 'yearly' tags
    - these tags needs little explanation. Actually they can (and should) all live in the same destination directory and share one the same 'last backup' to hard link to.

### Sample usage

```
$ sudo ./rsync-backup.sh /Users/john /Volumes/BK_DISK/home_backups
$
```
this command if you run it few times will produce the resulting directory structure as above.

Another example with TAG=daily and explicit ignore list file '.bk_ignore' (should be made beforehand):
```
$ sudo ./rsync-backup.sh -t daily -x /Users/john/.bk_ignore / /Volumes/BK_DISK/full_backups
$
```
if run 3 times in 3 days will result in:

```
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-25_110101.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-26_120202.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-27_110303.daily
/Volumes/BK_DISK/full_backups/_ROOT_.last_link -> _ROOT_.2015-05-27_110303
#
```
again, last line show a symlink which always points to the most recent backup directory.

### About TAGs

It looks like TAGs do nothing special except adding suffix to each of backup directories. But what is not so obvious is that if backups with different TAGs are specified to use the same base destination directory, then they do effectively use one and the same 'hard-linking trunk': each backup becomes the 'last' and is a target for 'last_link' symlink. This approach makes sense when we backup one and the same source directory so that backups do differ only by the time they are made.

Otherwise TAGs are no more then mere a suffix which helps are visually separate backups.

Let's loot at simple example backup plan to illustrate the point. Here is the crontab (root priviledged one) where we schedule 3 flavors (use 3 tags - 'daily', 'weekly' and 'montly') of backups with the same destination base directory like this (sudo crontab -l):

```
$ sudo crontab -l)
SCRPT="/Users/john/scripts/rsync-backup.sh"
DEST="/Volumes/BK_DISK/full_backups"

0 10 * * 0-5 $SCRPT -t daily / $DEST
0 11 * * 6 $SCRPT -t weekly / $DEST
0 12 1 * * $SCRPT -t monthly / $DEST
$
#
```

Very soon this setup is going to produce the following:

```
$ ls -l
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-29_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-30_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-05-31_110000.weekly
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-01_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-01_120000.monthly
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-02_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-03_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-04_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-05_100000.daily
/Volumes/BK_DISK/full_backups/_ROOT_.2015-06-06_110000.weekly
/Volumes/BK_DISK/full_backups/_ROOT_.last_link -> _ROOT_.2015-06-06_110000.weekly
$
```
Again, each time '_ROOT_.last_link' would point to the recent most backup - be it daily, weekly or monthly one - they all has equal unhuman rights for this purpose.

Should we decide at some point in time we don't need older daily backups - we can safely delete any of them them without breaking anything. Hardlinks are deaf to deletion of their kins.

### Installing GNU utils on Mac OSX

One can install better, newer and more shiny POSIX compliant utils with Homebrew:

```
brew install coreutils
```
One gets ```gcp``` (GNU cp), ```greadlink``` (GNU readlink) and a whole bunch of other fundamental utilities.

Rsync is not part of core utils, so it can be installed separately:
```
brew tap homebrew/dupes
brew install rsync
```
All of them are reachable under
```
/usr/local/bin
```
while Mac system utils are under
```
/usr/bin
```

In this script we are addressing them as follows
```
/usr/local/bin/rsync
/usr/local/bin/gcp
/usr/local/bin/greadlink
```
Replacing older utils with this newer ones is possible but may break Mac functions to certain extent. The same is true to the idea of change the order of PATH elements by pushing /usr/local/bin to the top in ```/etc/paths``` file. This would effectively make Homebrew rsync come out first in lookup, but changing the path can break the system. So, the slim way to civilize Mac ecosystem is to have this parallel setup.


### Sample exclude file contents

```
.Spotlight-*/
.Trashes
/afs/*
/automount/*
/cores/*
/dev/*
/Network/*
/private/tmp/*
/private/var/run/*
/private/var/spool/postfix/*
/private/var/vm/*
/Previous Systems.localized
/tmp/*
/Volumes/*
*/.Trash
```

### TODO
- implement some deletion scheme for older backups
