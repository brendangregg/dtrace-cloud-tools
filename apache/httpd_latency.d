#!/usr/sbin/dtrace -s
/*
 * httpd_latency.d	Summarize HTTP server latency.
 *
 * This requires the httpd DTrace provider, which is available as mod_usdt
 * for Apache, and the translators.  If they are in not in /usr/lib/dtrace,
 * you may need to invoke this with the actual location with -L, eg:
 * dtrace -L /opt/local/lib/dtrace -s httpdslower.d 
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	trace("Tracing HTTP server latency... Hit Ctrl-C to end.\n");
}

httpd*:::request-start
{
	self->ts = timestamp;
}

httpd*:::request-done
/self->ts/
{
	@["ns"] = quantize(timestamp - self->ts);
	self->ts = 0;
}
