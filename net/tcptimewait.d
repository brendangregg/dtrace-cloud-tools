#!/usr/sbin/dtrace -s
/*
 * tcptimewait.d	Show TCP TIME-WAIT arrival by hosts and ports.
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
 *	121: ok
 */

#pragma D option quiet
#pragma D option switchrate=10

dtrace:::BEGIN
{
	/* from /usr/include/inet/tcp.h */
	tcpstate[-6] = "TCPS_CLOSED";
	tcpstate[-5] = "TCPS_IDLE";
	tcpstate[-4] = "TCPS_BOUND";
	tcpstate[-3] = "TCPS_LISTEN";
	tcpstate[-2] = "TCPS_SYN_SENT";
	tcpstate[-1] = "TCPS_SYN_RCVD";
	tcpstate[0] = "TCPS_ESTABLISHED";
	tcpstate[1] = "TCPS_CLOSE_WAIT";
	tcpstate[2] = "TCPS_FIN_WAIT_1";
	tcpstate[3] = "TCPS_CLOSING";
	tcpstate[4] = "TCPS_LAST_ACK";
	tcpstate[5] = "TCPS_FIN_WAIT_2";
	tcpstate[6] = "TCPS_TIME_WAIT";

	printf("%-20s %-17s %-16s %-5s  %-16s %-5s %s\n", "TIME", "TCP_STATE",
	    "SRC-IP", "PORT", "DST-IP", "PORT", "FLAGS");
}

fbt::tcp_time_wait_processing:entry
{
        this->iph = (ipha_t *)args[1]->b_rptr;
	this->tcph = (tcph_t *)(args[1]->b_rptr + 20);
	this->state = tcpstate[args[0]->tcp_state] != NULL ?
	    tcpstate[args[0]->tcp_state] : "<unknown>";
	printf("%-20Y %-17s %-16s %-5d  %-16s %-5d %x\n", walltimestamp,
	    this->state,
	    inet_ntoa(&this->iph->ipha_src),
	    ntohs(*(uint16_t *)this->tcph->th_lport),
	    inet_ntoa(&this->iph->ipha_dst),
	    ntohs(*(uint16_t *)this->tcph->th_fport),
	    this->tcph->th_flags[0]);
}
