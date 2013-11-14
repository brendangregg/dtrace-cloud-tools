#!/usr/sbin/dtrace -s
/*
 * go_pkgcounts.d	Summarize function call counts by package name
 *
 * USAGE: go_pkgcounts.d -p PID [interval]
 *
 * This traces all functions in all packages in go.
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

pid$target:a.out::entry
/strstr(probefunc, ".") != NULL/ 
{
	@[strtok(probefunc, ".")] = count();
}

profile:::tick-1s
/interval && ++sec == interval/
{
	sec = 0;
	printf("\n%Y:\n", walltimestamp);
	printa(@);
	trunc(@);
}
