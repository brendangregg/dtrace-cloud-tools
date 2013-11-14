#!/usr/sbin/dtrace -s
/*
 * gomaincounts.d	Summarize main package function call counts
 *
 * USAGE: gomaincounts.d -p PID [interval]
 *
 * This traces all functions in the main package in go.
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
	@[probefunc] = count();
}

profile:::tick-1s
/interval && ++sec == interval/
{
	sec = 0;
	printf("\n%Y:\n", walltimestamp);
	printa(@);
	trunc(@);
}
