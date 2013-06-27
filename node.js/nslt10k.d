#!/usr/sbin/dtrace -s
/*
 * nslt10k.d		node.js Server Latency Trace.
 *
 * This traces node.js HTTP server requests using the node DTrace provider.
 * All node instances on the system will be traced.
 *
 * This emits basic details for consumption by other tools, and includes the
 * PID.  It ideally captures at least 10,000 requests.  It has a 15 minute
 * timeout if that is not possible.
 *
 * 25-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option switchrate=5

dtrace:::BEGIN
{
	printf("ENDTIME(us) LATENCY(ns) PID\n");
	start = timestamp;
	n = 0;
}

node*:::http-server-request
{
	ts[pid, args[1]->fd] = timestamp;
}

node*:::http-server-response
/this->start = ts[pid, args[0]->fd]/
{
	printf("%d %d %d\n",
	    (timestamp - start) / 1000, timestamp - this->start, pid);
	ts[pid, args[0]->fd] = 0;
}

node*:::http-server-request
/n++ > 10100/
{
	exit(0);
}

profile:::tick-15m { exit(0); }
