#!/usr/sbin/dtrace -s
/*
 * koncpu.d	sample kernel CPU stacks at a gentle rate (101 Hertz)
 *
 * From Chapter 12 of the DTrace book.
 */

profile:::profile-101
{
        @["\n  on-cpu (count @101hz):", stack()] = count();
}
