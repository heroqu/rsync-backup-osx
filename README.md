# rsync-backup-osx

Rsync based backup script for \*NIX systems, especially adapted for *Mac OS*

### Motivation

Use most simple and reliable *rsync + crontab* backup strategy that would effectively replace time-machine functionality of Mac OSX.

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
  - use root crontab for scheduling
- Be adjusted to Mac OSX environment which is often filled with outright outdated UNIX utils
  - use fresh GNU utils instead
- no deletion of older backups
  - no need for me personally yet.
    - Would be simple to accomplish with numbered scheme when destination directories are named ```bk.0```, ```bk.1```, ```bk.N``` - just shift dirs by 1 and delete the biggest numbered one.
    - Little more complicated if naming scheme is based on time stamping ```bk.2015-05-29```, ```bk.2015-05-28``` etc. In this case one can parse suffixes or just rely on creation date. Again, I personally don't need it yet.
- Option to use *exclude list* to prevent certain directories from archiving.
- Time stamp suffix naming scheme:

```
/Volumes/BK_DISK/home_backups/john.2015-05-28_235958
/Volumes/BK_DISK/home_backups/john.2015-05-29_215233
/Volumes/BK_DISK/home_backups/john.2015-05-30_120144
/Volumes/BK_DISK/home_backups/john.last_link -> john.2015-05-30_120144
...
```
- Use a symlink to the recent most backup as a layer of indirection to simplify finding last backup for the purpose of hard-linking. The symlink is to be automatically updated after each new backup.
  - This approach eliminates the necessity of 'round robin' way of renaming all previous backups. No need to rename anything, just keep a symlink to the last backup.
  - If symlink is not there or is broken - one can recreate it manually.
  - In the above listing ```john.last_link``` is that symlink to most recent backup directory ```john.2015-05-30_120144```.

- Tagging backups with 'hourly', 'daily', 'weeky', 'monthly' or 'yearly' suffixes.
  - Read about rationale behind using these TAGs in [About TAGs](#about_tags) section of this page.

### Sample usage

```
$ sudo ./rsync-backup.sh /Users/john /Volumes/BK_DISK/home_backups
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
```
again, last line show a symlink which always points to the most recent backup directory.

### <a name="about_tags"></a>About TAGs

It looks like TAGs do nothing special except adding suffix to each of backup directories. But what is not so obvious is that if backups with different TAGs are specified to use the same base destination directory, then they do effectively use one and the same 'hard-linking trunk': each backup becomes the 'last' and is a target for 'last_link' symlink. This approach makes sense when we backup one and the same source directory so that backups do differ only by the time they are made.

Otherwise TAGs are no more then mere a suffix which helps to separate backups visually.

Let's look at simple example backup plan to illustrate the point. Here is the crontab (root privileged one) where we schedule 3 backup 'flavors' ('daily', 'weekly' and 'monthly') while specify the same destination base directory for all of them:

```
$ sudo crontab -l
SRC="/"
SCRPT="/Users/john/scripts/rsync-backup.sh"
DEST="/Volumes/BK_DISK/full_backups"

0 10 * * 0-5 $SCRPT -t daily $SRC $DEST
0 11 * * 6 $SCRPT -t weekly $SRC $DEST
0 12 1 * * $SCRPT -t monthly $SRC $DEST
$
```
What is says is that:
- we want to do backups at 3 different schedules
- each of these schedules will backup whole root file system (SRC="/")
- each of these schedules will put backups to the same base destination directory "/Volumes/BK_DISK/full_backups"
- first 6 days of the week backups will happen at 10:00 and get suffix (TAG) 'daily'
- on 7th day (Satturday) the backup will happen at 11:00 and with suffix 'weekly'
- on the 1st of each month the backup is going to start at 12:00 and get suffix 'monthly'

9 days later we get the following result:

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
Again, each time '_ROOT_.last_link' would point to the recent most backup - be it daily, weekly or monthly one - they all have equal human rights for this purpose.

Should we decide at some point in time we don't need older daily backups - we can safely delete any of them (except the last one) without breaking anything. Hardlinks are deaf to deletion of their kins. If we delete the most recent backup - we might consider manually recreating the broken symlink so that it would point to the backup directory that stayed. If current symlink is broken or absent, then no hardl-inking occur and whole new 'hard-link trunk' is started and we waste hard disk space almost equal to the size of the backup.  

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

From time to time people are talking about a radical way when one just replaces stale Mac's utils with newer ones or little less radical solution of modifying ```$PATH``` variable so that ```/usr/local/bin``` would go first compared to ```/usr/bin```. The latter can be accomplished by alternating the lines order in ```/etc/paths``` file and it would effectively result in shadowing Mac's utils with utils installed by user (e.g. with Homebrew) under ```/usr/local/bin```. So far so good, except for it could also lead to both breaking some Mac OSX functioning and to the risk of some malicious install to shadow system utils. Read Aristotle Pagaltzis' [answer]( http://superuser.com/questions/324616/how-should-i-set-the-path-variable-on-my-mac-so-the-hombrew-installed-tools-are) which elaborates on this or [this post](https://discussions.apple.com/thread/3588837?start=0&tstart=0 ).

For these reasons we stick to independent setup of GNU utils instead.

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
