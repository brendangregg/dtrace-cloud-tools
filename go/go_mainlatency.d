#!/usr/sbin/dtrace -s
/*
 * gomainlatency.d	Summarize main package function latency distributions
 *
 * USAGE: gomainlatency.d -p PID [interval]
 *
 * An optional interval can be provided, which will print a summary
 * every interval seconds.
 */

#pragma D option defaultargs
#pragma D option quiet

dtrace:::BEGIN
{
	interval = $1;
	sec = 0;
}

dtrace:::BEGIN
/interval/
{
	printf("Tracing PID %d; output every %d secs.\n", $target, interval);
}

dtrace:::BEGIN
/!interval/
{
	printf("Tracing PID %d; Ctrl-C to stop.\n", $target);
}

pid$target::main.*:entry
{
	self->ts = timestamp;
}

pid$target::main.*:return
/self->ts/
{
	@[probefunc, "ns"] = quantize(timestamp - self->ts);
}

profile:::tick-1s
/interval && ++sec == interval/
{
	sec = 0;
	printf("%Y:\n", walltimestamp);
	printa(@);
	trunc(@);
}
