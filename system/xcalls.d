#!/usr/sbin/dtrace -s
/*
 * xcalls.d	show who and what the CPU cross calls (xcalls) are.
 */

sysinfo:::xcalls
{
	@[strjoin(zonename, strjoin(":", execname)), stack()] = count();
}
