#!/usr/sbin/dtrace -s
/*
 * ipdropper.d - trace ip drop events with details
 *
 * This uses the fbt provider, so is unstable.
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

#pragma D option quiet

dtrace:::BEGIN
{
	printf("%-20s %-16s %-16s %s\n", "TIME", "SRC", "DST", "STR");
}

/*
 * ip_drop*() funcs have a string pointer description as arg0. This is
 * almost too good to be true.
 */
fbt::ip_drop_input:entry,
fbt::ip_drop_output:entry
{
	this->iph = (ipha_t *)args[1]->b_rptr;
	printf("%-20Y %-16s %-16s %s\n", walltimestamp,
	    inet_ntoa(&this->iph->ipha_src), inet_ntoa(&this->iph->ipha_dst),
	    stringof(arg0));
}
