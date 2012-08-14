#!/usr/sbin/dtrace -s
/*
 * ioslow.d	Trace disk I/O slower than specified ms.
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

inline int MIN_NS = 1000000000;

dtrace:::BEGIN
{
	printf("Tracing disk I/O longer than %d ms.\n\n", MIN_NS / 1000000);
}

io:::start
{
	start[arg0] = timestamp;
}

io:::done
/(this->start = start[arg0]) && (this->time = timestamp - this->start) > MIN_NS/
{
	printf("%Y: %s %d ms\n", walltimestamp,
	    args[0]->b_flags & B_READ ? "read" : "write", this->time / 1000000);
}

io:::done
{
	start[arg0] = 0;
}
