#!/usr/sbin/dtrace -s
/*
 * nodesockread2write.d - time from read() on a socket to 1st write()
 */

syscall::read:entry
/execname == "node" && fds[arg0].fi_fs == "sockfs"/
{
	self->fd = arg0;
}

syscall::read:return
/self->fd && arg0 > 0/
{
	self->ts[self->fd] = timestamp;
	self->fd = 0;
}

syscall::write:entry
/self->ts[arg0]/
{
	@["ms"] = quantize((timestamp - self->ts[arg0]) / 1000000);
	self->ts[arg0] = 0;
}
