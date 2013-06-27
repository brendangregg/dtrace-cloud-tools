#!/usr/sbin/dtrace -s
/*
 * node_surls.d		node.js server URL summary.
 *
 * This traces all node processes on the system.
 *
 * Requires the node DTrace provider, and a working version of the node
 * translator (/usr/lib/dtrace/node.d).
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing node server URLs. Summary every 10 secs or Ctrl-C.\n");
}

node*:::http-server-request
{
	@[args[0]->url] = count();
}

profile:::tick-10s
{
	printf("\n%Y:\n", walltimestamp);
	printa("   %@6d %s\n", @);
	trunc(@);
}
