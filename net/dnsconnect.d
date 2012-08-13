#!/usr/sbin/dtrace -s
/*
 * dnsconnect.d - snoop DNS connect details system wide.
 *
 * This is based on soconnect.d from Chapter 6 of the DTrace book.
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
#pragma D option switchrate=10hz

/* If AF_INET and AF_INET6 are "Unknown" to DTrace, replace with numbers: */
inline int af_inet = AF_INET;
inline int af_inet6 = AF_INET6;

dtrace:::BEGIN
{
	/* Add translations as desired from /usr/include/sys/errno.h */
	err[0]            = "Success";
	err[EINTR]        = "Interrupted syscall";
	err[EIO]          = "I/O error";
	err[EACCES]       = "Permission denied";
	err[ENETDOWN]     = "Network is down";
	err[ENETUNREACH]  = "Network unreachable";
	err[ECONNRESET]   = "Connection reset";
	err[ECONNREFUSED] = "Connection refused";
	err[ETIMEDOUT]    = "Timed out";
	err[EHOSTDOWN]    = "Host down";
	err[EHOSTUNREACH] = "No route to host";
	err[EINPROGRESS]  = "In progress";

	printf("%-6s %-12s %-16s %-3s %-16s %-5s %8s %s\n", "PID", "ZONE",
	    "PROCESS", "FAM", "ADDRESS", "PORT", "LAT(us)", "RESULT");
}

syscall::connect*:entry
{
	/* assume this is sockaddr_in until we can examine family */
	this->s = (struct sockaddr_in *)copyin(arg1, sizeof (struct sockaddr));
	this->f = this->s->sin_family;
}

syscall::connect*:entry
/this->f == af_inet/
{
	self->family = this->f;
	self->port = ntohs(this->s->sin_port);
	self->address = inet_ntop(self->family, (void *)&this->s->sin_addr);
	self->start = timestamp;
}

syscall::connect*:entry
/this->f == af_inet6/
{
	/* refetch for sockaddr_in6 */
	this->s6 = (struct sockaddr_in6 *)copyin(arg1,
	    sizeof (struct sockaddr_in6));
	self->family = this->f;
	self->port = ntohs(this->s6->sin6_port);
	self->address = inet_ntoa6((in6_addr_t *)&this->s6->sin6_addr);
	self->start = timestamp;
}

syscall::connect*:return
/self->start && self->port == 53/
{
	this->delta = (timestamp - self->start) / 1000;
	this->errstr = err[errno] != NULL ? err[errno] : lltostr(errno);
	printf("%-6d %-12s %-16s %-3d %-16s %-5d %8d %s\n", pid, zonename, execname,
	    self->family, self->address, self->port, this->delta, this->errstr);
}

syscall::connect*:return
/self->start/
{
	self->family = 0;
	self->address = 0;
	self->port = 0;
	self->start = 0;
}
