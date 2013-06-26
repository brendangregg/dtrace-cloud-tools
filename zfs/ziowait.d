#!/usr/sbin/dtrace -s
/*
 * ziowait.d	Measure time in zio_wait() by kernel stack trace.
 *
 * This won't identify all ZIO times, just those waited upon.  You may
 * get lucky this way and find the latency you are after this way, or
 * maybe not.
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

fbt::zio_wait:entry
{
	self->start = timestamp;
}

fbt::zio_wait:return
/self->start/
{
	@[stack(), "time (ns)"] = quantize(timestamp - self->start);
	self->start = 0;
}
