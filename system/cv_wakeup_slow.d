#!/usr/sbin/dtrace -s
/*
 * cv_wakeup_slow.d	Show slow CV sleep to wakeup times with stacks.
 *
 * USAGE: ./cv_wakeup_slow.d [min_ms]
 *
 * By default, a minimum time of 100 ms is used.
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

#pragma D option defaultargs
#pragma D option switchrate=10hz

BEGIN
{
	min_ns = $1 ? $1 * 1000000 : 100 * 1000000;
}

sched:::sleep
/execname == "httpd" && curlwpsinfo->pr_stype == SOBJ_CV/
{
	bedtime[curlwpsinfo->pr_addr] = timestamp;
}

sched:::wakeup
/bedtime[args[0]->pr_addr] &&
    ((this->delta = timestamp - bedtime[args[0]->pr_addr]) > min_ns)/
{
	printf("%d %d %d %d %s... %d ms",
	    args[1]->pr_pid, args[0]->pr_lwpid, pid, curlwpsinfo->pr_lwpid, execname,
	    this->delta / 1000000);
	stack();
	bedtime[args[0]->pr_addr] = 0;
}

sched:::wakeup
/bedtime[args[0]->pr_addr]/
{
	bedtime[args[0]->pr_addr] = 0;
}
