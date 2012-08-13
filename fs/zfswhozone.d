#!/usr/sbin/dtrace -s
/*
 * zfswhozone.d		Show ZFS/VFS calls by zone and process.
 *
 * Most common ZFS/VFS operations are included.  Customize as needed.
 *
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at http://smartos.org/CDDL
 *
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file.
 *
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 * Copyright (c) 2012 Joyent Inc., All rights reserved.
 * Copyright (c) 2012 Brendan Gregg, All rights reserved.
 *
 * TESTED: this fbt provider based script may only work on some OS versions.
 *      121: ok
 */

#pragma D option defaultargs
#pragma D option quiet

inline int TOP = 25;

dtrace:::BEGIN
{
	interval = $1 ? $1 : 1;
}

dtrace:::BEGIN
{
	printf("Top %d ZFS/VFS calls by zone and process. Output every %d secs.\n",
	    TOP, interval);
	secs = interval;
}

fbt::zfs_read:entry,
fbt::zfs_write:entry,
fbt::zfs_ioctl:entry,
fbt::zfs_fsync:entry,
fbt::zfs_open:entry,
fbt::zfs_close:entry,
fbt::zfs_getattr:entry,
fbt::zfs_setattr:entry,
fbt::zfs_readdir:entry,
fbt::zfs_create:entry,
fbt::zfs_remove:entry,
fbt::zfs_mkdir:entry,
fbt::zfs_rmdir:entry
{
	@[zonename, execname, probefunc] = count();
}

profile:::tick-1sec
{
	secs--;
}

profile:::tick-1sec
/secs == 0/
{
	trunc(@, TOP);
	printf("\n  %20s %18s %12s %8s\n", "ZONE", "EXEC", "VFS", "COUNT");
	printa("  %20s %18s %12s %@8d\n", @);
	secs = interval;
	trunc(@);
}

dtrace:::END
{
	trunc(@);
}
