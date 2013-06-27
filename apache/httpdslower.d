#!/usr/sbin/dtrace -s
/*
 * httpdslower.d	Show HTTP server requests slower than threshold.
 *
 * USAGE: httpdslower.d [min_ms]
 *    eg,
 *        httpdslower.d 10	# show requests slower than 10 ms
 *        httpdslower.d 	# show all requests
 *
 * This requires the httpd DTrace provider, which is available as mod_usdt
 * for Apache, and the translators.  If they are in not in /usr/lib/dtrace,
 * you may need to invoke this with the actual location with -L, eg:
 * dtrace -L /opt/local/lib/dtrace -s httpdslower.d 
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=10

dtrace:::BEGIN
{
	min_ns = $1 * 1000000;
	printf("Tracing HTTP server ops slower than %d ms\n", $1);
        printf("%-20s %-6s %6s %s\n", "TIME", "PID", "ms", "URL");
}

node*:::http-server-request
{
	self->ts = timestamp;
}

node*:::http-server-response
/self->ts && (this->delta = timestamp - self->ts) > min_ns/
{
        printf("%-20Y %-6d %6d %s\n", walltimestamp, pid,
	    this->delta / 1000000, args[1]->rq_uri);
	self->ts = 0;
}
