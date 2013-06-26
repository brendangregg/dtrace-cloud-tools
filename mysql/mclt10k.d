#!/usr/sbin/dtrace -s
/*
 * mclt10k.d		MySQL Command Latency Trace.
 *
 * This traces MySQL commands using the mysql DTrace provider.  All
 * mysqld instances on the system will be traced.
 *
 * This emits basic details for consumption by other tools, and includes the
 * MySQL command ID (numeric) and PID.  It ideally captures at least 10,000
 * commands.  It has a 15 minute timeout if that is not possible.
 */

#pragma D option quiet
#pragma D option switchrate=5

dtrace:::BEGIN
{
	printf("ENDTIME(us) LATENCY(ns) CMD PID\n");
	start = timestamp;
	n = 0;
}

mysql*:::command-start
{
	self->ts = timestamp;
	self->cmd = arg1;
}

mysql*:::command-done
/self->ts/
{
	printf("%d %d %d %d\n",
	    (timestamp - start) / 1000, timestamp - self->ts, self->cmd, pid);
	self->ts = 0;
	self->cmd = 0;
}

mysql*:::command-start
/n++ > 10100/
{
	exit(0);
}

profile:::tick-15m { exit(0); }
