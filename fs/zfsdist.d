#!/usr/sbin/dtrace -s
/*
 * zfsdist.d	Show ZFS/VFS latency distributions.
 *
 * Some common ZFS/VFS calls are traced (see below).
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

fbt::zfs_read:entry,
fbt::zfs_write:entry,
fbt::zfs_readdir:entry,
fbt::zfs_getattr:entry,
fbt::zfs_setattr:entry
{
	self->start = timestamp;
}

fbt::zfs_read:return,
fbt::zfs_write:return,
fbt::zfs_readdir:return,
fbt::zfs_getattr:return,
fbt::zfs_setattr:return
/self->start/
{
	this->time = timestamp - self->start;
	@[probefunc, "time (ns)"] = quantize(this->time);
	self->start = 0;
}

dtrace:::END
{
	printa(@);
	trunc(@);
}
