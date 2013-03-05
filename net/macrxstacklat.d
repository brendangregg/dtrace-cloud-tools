#!/usr/sbin/dtrace -s
/*
 * macrxstacklat.d - RX packet latency from receive to free.
 *
 * work in progress.
 */

fbt::mac_rx:entry
{
	ts[arg2] = timestamp;
}

fbt::freemsg:entry,
fbt::freeb:entry
/this->t = ts[arg0]/
{
	@["ns"] = quantize(timestamp - this->t);
	ts[arg0] = 0;
}
