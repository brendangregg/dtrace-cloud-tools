#!/usr/sbin/dtrace -s
/*
 * redislat.d - summarize redis request latency
 *
 * This measures redis request latency as the time from a read() return to a
 * write() entry on the same file descriptor. The intent is to measure the
 * time between readQueryFromClient() to sendReplyToClient(), but by using
 * the syscall provider to minimize overhead. If this strategy turns out to
 * be invalid, switch this to the pid provider.
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
 * Copyright (c) 2013 Joyent Inc., All rights reserved.
 * Copyright (c) 2013 Brendan Gregg, All rights reserved.
 */

syscall::read:entry
/execname == "redis-server"/
{
	self->fd = arg0;
	self->ok = 1;
}

syscall::read:return
/self->ok/
{
	self->start[self->fd] = timestamp;
	self->fd = 0;
	self->ok = 0;
}

syscall::write:entry
/(this->start = self->start[arg0]) > 0/
{
	@d["read->write dist (ns), for pid:", pid] =
	    quantize(timestamp - this->start);
	@s[pid, tid] = sum(timestamp - this->start);
	self->start[arg0] = 0;
}

syscall::close:entry
/self->start[arg0]/
{
	self->start[arg0] = 0;
}

profile:::tick-1s
{
	normalize(@s, 1000000);
	printf("\nread->write sum by pid, tid (ms):\n");
	printa(@s);
	trunc(@s);
}

dtrace:::END
{
	printa(@d);
	trunc(@d);
	trunc(@s);
}
