#!/usr/sbin/dtrace -s

#pragma D option quiet

dtrace:::BEGIN
{
	trace("Tracing process schedule next-function counts. Ctrl-C to end\n");
}

erlang*:::process-spawn
{
	@[copyinstr(arg1)] = count();
}

profile:::tick-1s
{
	printa(@);
	trunc(@);
}
