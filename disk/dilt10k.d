#!/usr/sbin/dtrace -s
/*
 * dilt10k.d	Disk I/O Latency Trace.
 *
 * This emits basic details for consumption by other tools.  It ideally captures
 * at least 10,000 I/O.  It has a 15 minute timeout if that is not possible.
 */

#pragma D option quiet
#pragma D option switchrate=2
#pragma D option dynvarsize=8m

BEGIN
{
	printf("ENDTIME(us) LATENCY(us) DIR SIZE(bytes) PROCESS\n");
	start = timestamp;
	n = 0;
}
	
io:::start
{
	ts[arg0] = timestamp;
}

io:::done
/this->ts = ts[arg0]/
{
	printf("%d %d %s %d %s\n",
	    (timestamp - start) / 1000, (timestamp - this->ts) / 1000,
	    args[0]->b_flags & B_READ ? "R" : "W", args[0]->b_bcount,
	    execname);
	ts[arg0] = 0;
}

io:::start
/n++ > 10100/
{
	exit(0);
}

profile:::tick-15m { exit(0); }
