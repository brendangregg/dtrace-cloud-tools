#!/usr/sbin/dtrace -s
/*
 * httpd_urls.d		Summarize HTTP server requests by URL.
 *
 * This requires the httpd DTrace provider, which is available as mod_usdt
 * for Apache, and the translators.  If they are in not in /usr/lib/dtrace,
 * you may need to invoke this with the actual location with -L, eg:
 * dtrace -L /opt/local/lib/dtrace -s httpd_urls.d 
 *
 * 26-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing HTTP server URLs. Summary every 10 secs or Ctrl-C.\n");
}

node*:::http-server-response
{
	@[args[1]->rq_uri] = count();
}

profile:::tick-10s
{
	printf("\n%Y:\n", walltimestamp);
	printa("   %@6d %s\n", @);
	trunc(@);
}
