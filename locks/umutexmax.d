#!/usr/sbin/dtrace -s
/*
 * umutexmax.d	User-space mutex, summarize max block time.
 *
 * Prints output every second, for the given PID.
 *
 * USAGE: ./umutexmax.d -p PID
 *
 * 17-Jun-2013	Brendan Gregg	Created this.
 */

plockstat$target:::mutex-block
{
	self->ts[arg0] = timestamp;
}

plockstat$target:::mutex-acquire
/self->ts[arg0]/
{
	@["max blocked (ms)"] = max(timestamp - self->ts[arg0]);
	self->ts[arg0] = 0;
}

profile:::tick-1s
{
	normalize(@, 1000000);
	printa(@);
	trunc(@);
}
