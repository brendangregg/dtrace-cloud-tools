#!/usr/sbin/dtrace -s
/*
 * zilt10k.d		ZFS Latency Trace.
 *
 * This traces several types of user-level ZFS request, via the ZFS/VFS
 * interface.  The output will be verbose, as it includes ARC hits.
 *
 * This emits basic details for consumption by other tools, and includes
 * the zonename.  It ideally captures at least 10,000 I/O events.  It has
 * a 15 minute timeout if that is not possible.
 *
 * 25-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option switchrate=5

BEGIN
{
	printf("ENDTIME(us) LATENCY(ns) TYPE SIZE(bytes) ZONENAME PROCESS\n");
	start = timestamp;
	n = 0;
}

fbt::zfs_read:entry, fbt::zfs_write:entry
/execname != "dtrace"/
{
	self->ts = timestamp;
	self->b = args[1]->uio_resid;
}

fbt::zfs_open:entry, fbt::zfs_close:entry,
fbt::zfs_readdir:entry, fbt::zfs_getattr:entry
/execname != "dtrace"/
{
	self->ts = timestamp;
	self->b = 0;
}

fbt::zfs_read:entry, fbt::zfs_write:entry,
fbt::zfs_open:entry, fbt::zfs_close:entry,
fbt::zfs_readdir:entry, fbt::zfs_getattr:entry
/n++ > 10100/
{
	exit(0);
}

profile:::tick-15m { exit(0); }

fbt::zfs_read:return, fbt::zfs_write:return,
fbt::zfs_open:return, fbt::zfs_close:return,
fbt::zfs_readdir:return, fbt::zfs_getattr:return
/self->ts/
{
	printf("%d %d %s %d %s %s\n",
	    (timestamp - start) / 1000, timestamp - self->ts,
	    probefunc + 4, self->b, zonename, execname);
	self->ts = 0;
	self->b = 0;
}
