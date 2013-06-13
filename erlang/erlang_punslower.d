#!/usr/sbin/dtrace -s
/*
 * erlang_punslower.d	Process unscheduled events slower than arg.
 *
 * USAGE: ./erlang_punslower.d [min_ms]
 *
 * This shows the next function that will be run.
 *
 * 13-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option dynvarsize=8m
#pragma D option quiet
#pragma D option switchrate=4

dtrace:::BEGIN
{
	min_ns = $1 ? $1 * 1000000 : 1000000;
	printf("Tracing Erlang process unscheduled events with next\n");
	printf("function call, slower than %d ms.\n", min_ns / 1000000);
}

erlang*:::process-unscheduled
{
	ts[copyinstr(arg0)] = timestamp;
}

erlang*:::process-scheduled
/(this->p = copyinstr(arg0)) != NULL &&
    (this->ts = ts[this->p]) > 0 &&
    (this->d = (timestamp - this->ts)) > min_ns/
{
	printf("%Y %8d ms: %s\n", walltimestamp,
	    (timestamp - this->ts) / 1000000, copyinstr(arg1));
}

erlang*:::process-scheduled
/this->p != NULL/
{
	ts[this->p] = 0;
}
