#!/usr/sbin/dtrace -s
/*
 * nodesockslower.d - time from read() on a socket to 1st write()
 *
 * USAGE: ./nodesockslower.d [min_ms]
 */

#pragma D option quiet
#pragma D option defaultargs
#pragma D option switchrate=5

dtrace:::BEGIN
{
	min_ns = $1 * 1000000;
	printf("Tracing node.js socket returns slower than %d ms\n", $1);
}

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
/self->ts[arg0] &&
    (this->delta = timestamp - self->ts[arg0]) > min_ns/
{
	printf("%Y %d ms\n", walltimestamp, this->delta / 1000000);
}

syscall::write:entry
/self->ts[arg0]/
{
	self->ts[arg0] = 0;
}
