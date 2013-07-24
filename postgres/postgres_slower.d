#!/usr/sbin/dtrace -s
/*
 * postgres_slower.d	Trace queries slower than specified ms.
 *
 * USAGE: ./postgres_slower.d min_ms
 *
 * Uses the postgres DTrace provider.
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
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10hz

dtrace:::BEGIN
{
	min_ns = $1 * 1000000;
	printf("Tracing... Min query time: %d ms.\n\n", $1);
	printf(" %-8s %-8s %s\n", "TIME(ms)", "CPU(ms)", "QUERY");
}

postgres*:::query-start
{
	self->start = timestamp;
	self->vstart = vtimestamp;
}

postgres*:::query-done
/self->start && (timestamp - self->start) > min_ns/
{
	this->time = (timestamp - self->start) / 1000000;
	this->vtime = (vtimestamp - self->vstart) / 1000000;
	printf(" %-8d %-8d %S\n", this->time, this->vtime, copyinstr(arg0));
}

postgres*:::query-done
{
	self->query = 0;
	self->start = 0;
	self->vstart = 0;
}
