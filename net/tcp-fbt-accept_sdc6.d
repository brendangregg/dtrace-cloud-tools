#!/usr/sbin/dtrace -s
/*
 * tcp-fbt-accept.d	Trace TCP inbound connections using the fbt provider.
 *
 * This is for use when the tcp provider is unavailable.  Also, all inbound
 * connections are traced, whether they are dropped (listenDrop) or not.
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
 *	SDC 6.5: ok (possibly illumos, nevada 148 and newer)
 */

#pragma D option quiet
#pragma D option switchrate=10

dtrace:::BEGIN
{
	printf("%-20s  %-18s %-5s    %-18s %-5s\n", "TIME",
	    "SRC-IP", "PORT", "DST-IP", "PORT");
}

fbt::tcp_input_listener:entry
{
        this->iph = (ipha_t *)args[1]->b_rptr;
	this->tcph = (tcph_t *)(args[1]->b_rptr + 20);
	printf("%-20Y  %-18s %-5d -> %-18s %-5d\n", walltimestamp,
	    inet_ntoa(&this->iph->ipha_src),
	    ntohs(*(uint16_t *)this->tcph->th_lport),
	    inet_ntoa(&this->iph->ipha_dst),
	    ntohs(*(uint16_t *)this->tcph->th_fport));
}
