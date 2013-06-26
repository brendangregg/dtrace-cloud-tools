#!/usr/sbin/dtrace -s
/*
 * umutexsum.d	User-space mutex, sum block time by lock.
 *
 * Prints output every second, for the given PID.
 *
 * USAGE: ./umutexsum.d -p PID
 *
 * 17-Jun-2013	Brendan Gregg	Created this.
 */

#pragma D option quiet

dtrace:::BEGIN
{
	printf("Tracing mutex for %d.\n", $target);
}

plockstat$target:::mutex-block
{
	self->ts[arg0] = timestamp;
}

plockstat$target:::mutex-acquire
/self->ts[arg0]/
{
	@[arg0] = sum(timestamp - self->ts[arg0]);
	self->ts[arg0] = 0;
}

profile:::tick-1s
{
	normalize(@, 1000000);
	printf("   %10s %s\n", "TBLOCK(ms)", "LOCK");
	printa("   %@10d %6A\n", @);
	trunc(@);
}
