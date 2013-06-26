#!/usr/sbin/dtrace -s
/*
 * nodejs_latency.d	Summarize node.js HTTP server latency.
 *
 * Requires the node DTrace provider, and a working version of the node
 * translator (/usr/lib/dtrace/node.d).
 *
 * 25-Jun-2013	Brendan Gregg	Created this (lost the originals).
 */

node*:::http-server-request
{
	this->fd = (xlate <node_connection_t *>((node_dtrace_connection_t *)arg1))->fd;
	ts[pid, this->fd] = timestamp;
}

node*:::http-server-response
{
	this->fd = ((xlate <node_connection_t *>((node_dtrace_connection_t *)arg0))->fd);
	/* FALLTHRU */
}

node*:::http-server-response
/this->start = ts[pid, this->fd]/
{
	@["ns"] = quantize(timestamp - this->start);
	ts[pid, this->fd] = 0;
}
