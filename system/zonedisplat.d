#!/usr/sbin/dtrace -s
/*
 * zonedisplat.d	CPU dispatcher queue latency by zone.
 *
 * SEE ALSO: displat.d, zonecapslat.d
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

dtrace:::BEGIN
{
	printf("Tracing...\n");
	printf("Note: outliers (> 1 secs) may be artifacts due to the ");
	printf("use of scalar globals (sorry).\n\n");
}

sched:::enqueue
{
	/* scalar global (I don't think this can be thread local) */
	start[args[0]->pr_lwpid, args[1]->pr_pid] = timestamp;
}

sched:::dequeue
/this->start = start[args[0]->pr_lwpid, args[1]->pr_pid]/
{
	this->time = timestamp - this->start;
	/* workaround since zonename isn't a member of args[1]... */
	this->zone = ((proc_t *)args[1]->pr_addr)->p_zone->zone_name;
	@[stringof(this->zone)] = quantize(this->time);
	start[args[0]->pr_lwpid, args[1]->pr_pid] = 0;
}

tick-1sec
{
	printf("CPU disp queue latency by zone (ns):\n");
	printa(@);
	trunc(@);
}
