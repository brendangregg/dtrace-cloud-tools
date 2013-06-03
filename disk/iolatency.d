#!/usr/sbin/dtrace -s
/*
 * iolatency.d	Show distribution of disk I/O latency.
 *
 * From Chapter 4 of the DTrace book.
 */

io:::start
{
	start[arg0] = timestamp;
}

io:::done
/this->start = start[arg0]/
{
	@time["disk I/O latency (ns)"] = quantize(timestamp - this->start);
	start[arg0] = 0;
}
