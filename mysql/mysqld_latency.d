#!/usr/sbin/dtrace -s
/*
 * mysqld_latency.d  Print query latency distribution every second.
 *
 * USAGE: ./mysqld_latency.d
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
 * TESTED: not yet! need a mysqld that has the query-start/done probes.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing all mysql probes... Hit Ctrl-C to end.\n");
}

mysql*:::query-start
{
	self->start = timestamp;
}

mysql*:::query-done
/self->start/
{
	@time[pid, zonename] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
}

profile:::tick-1s
{
	printf("\nMySQL queries/second total: ");
	printa("%@d; query latency (ns) by pid & zonename:", @num);
	printa(@time);
	clear(@time); clear(@num);
}

dtrace:::END
{
	trunc(@time); trunc(@num);
}
