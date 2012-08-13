#!/usr/sbin/dtrace -s
/*
 * zfsslowzone.d	Trace slow ZFS/VFS reads and writes.
 *
 * USAGE:	zfsslowzone.d min_ms
 *    eg,
 *		zfsslowzone.d 50	# show I/O longer than 50 ms
 *
 * This traces at the VFS layer, so the latency shown is directly suffered
 * by the application.  The output is wide (sorry).  This script is based
 * on zfsslower.d from the DTrace book.
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
 *	121: ok
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
        printf("%-20s %-16s %-12s %1s %4s %6s %s\n", "TIME", "PROCESS",
            "ZONE", "D", "KB", "ms", "FILE");
        min_ns = $1 * 1000000;
}

/* see uts/common/fs/zfs/zfs_vnops.c */

fbt::zfs_read:entry, fbt::zfs_write:entry
{
        self->path = args[0]->v_path;
        self->kb = args[1]->uio_resid / 1024;
        self->start = timestamp;
}

fbt::zfs_read:return, fbt::zfs_write:return
/self->start && (timestamp - self->start) >= min_ns/
{
        this->iotime = (timestamp - self->start) / 1000000;
        this->dir = probefunc == "zfs_read" ? "R" : "W";
        printf("%-20Y %-16s %-12s %1s %4d %6d %s\n", walltimestamp,
            execname, zonename, this->dir, self->kb, this->iotime,
            self->path != NULL ? stringof(self->path) : "<null>");
}

fbt::zfs_read:return, fbt::zfs_write:return
{
        self->path = 0; self->kb = 0; self->start = 0;
}
