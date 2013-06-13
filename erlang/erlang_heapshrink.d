#!/usr/sbin/dtrace -s 

erlang*:::process-heap_shrink
{
	@["heap shrink bytes"] = quantize(arg1 - arg2);
}

tick-1s
{
	printa(@);
	trunc(@);
}
