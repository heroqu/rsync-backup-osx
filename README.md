# rsync-backup-osx

Rsync based backup script for *NIX systems, especially adapted for Mac OS

### Motivation

Use most simple and reliable rsync + crontab backup scheme that would effectively replace time-machine functionality

### Credits and inspiration

+ Mike Rubel arctile - great short 'Intro' reading to understand backup strategies and hardlinking 
  - [Easy Automated Snapshot-Style Backups with Linux and Rsync](http://www.mikerubel.org/computers/rsync_snapshots/)
+ Noah's backup script:
  - [here](http://www.noah.org/wiki/Rsync_backup) and 
  - [here](https://gist.github.com/elundmark/7183083)
+ Great blog & script by Nicolas Gallagher:
  - [here](http://nicolasgallagher.com/mac-osx-bootable-backup-drive-with-rsync)
+ All of you wonderful guys who blog and github and share your tips and thoughts on bash, rsync and all the rest. 

### Ideas and features

- script should use hardlinking to last successful backup of "similar signature" to save space and time
  - there two ways to do it I know of: ```cp -l``` and ```rsync --link-dest```, I've choosen the first one
- no deletion of older backups
  - no need for me personally yet. Simple to do with numbered style of backuping when dirs are named bk.0, bk.1, bk.N - just shift dirs by 1 and delete the biggest numbered one. 
  Little more complicated if naming scheme is bk.2015-05-29, bk.2015-05-28 etc. - one can parse suffixes or just rely on creation date. Again, I don't need it yet.
  - use of exclude file
  - date-time suffix naming scheme:
  
  ```
  /Volumes/BK_DISK/home_backups/john.2015-05-28_235958
  /Volumes/BK_DISK/home_backups/john.2015-05-29_215233
  /Volumes/BK_DISK/home_backups/john.2015-05-30_120144
  /Volumes/BK_DISK/home_backups/john.last_link -> john.2015-05-30_120144
  ```

here ```john.last_link``` is symlink to most recent backup directory ```john.2015-05-30_120144```

  - use of 'daily', 'weeky', 'monthly' and 'yearly' tags
    - these tags needs little explanation. Actually they can (and should) all live in the same destination directory and share one the same 'last backup' to hardlink to.   

### Sample usage

```
sudo ./rsync-backup.sh /Users/john /Volumes/BK_DISK/home_backups
```
this command if you run it few times will produce the resulting directory structure as above.

Another one:
```
sudo ./rsync-backup.sh -p daily / /Volumes/BK_DISK/full_backups
```
if run 3 time in 3 days will result in:

  ``` shell
  /Volumes/BK_DISK/home_backups/_ROOT_.2015-05-25_110101
  /Volumes/BK_DISK/home_backups/_ROOT_.2015-05-26_120202
  /Volumes/BK_DISK/home_backups/_ROOT_.2015-05-27_110303
  /Volumes/BK_DISK/home_backups/_ROOT_.last_link -> _ROOT_.2015-05-27_110303
  ```

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
 
