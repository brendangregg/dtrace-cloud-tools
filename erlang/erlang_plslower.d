#!/usr/sbin/dtrace -s
/*
 * erlang_plslower.d	Erlang process life span slower than threshold.
 *
 * USAGE: ./erlang_plslower.d [min_ms]		# defaults to 1 ms
 *
 * 12-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option dynvarsize=8m
#pragma D option quiet
#pragma D option switchrate=4

BEGIN
{
	min_ns = $1 ? $1 * 1000000 : 1000000;
	printf("Tracing Erlang process times slower than %d ms.\n",
	    min_ns / 1000000);
}

erlang*:::process-spawn
{
	this->p = copyinstr(arg0);
	name[this->p] = copyinstr(arg1);
	ts[this->p] = timestamp;
}

erlang*:::process-exit
/(this->p = copyinstr(arg0)) != NULL &&
    (this->ts = ts[this->p]) &&
    (this->d = (timestamp - this->ts)) > min_ns/
{
	printf("%Y %6d ms: %s\n", walltimestamp, this->d / 1000000,
	    name[this->p]);
}

erlang*:::process-exit
/this->p != NULL/
{
	ts[this->p] = 0;
	name[this->p] = 0;
}
