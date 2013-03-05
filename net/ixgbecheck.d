#!/usr/sbin/dtrace -s
/*
 * ixgbecheck.d - dig out various ixgbe counters.
 *
 * work in progress.
 */

fbt::ixgbe_stall_check:entry
{
        printf("\n%Y\n", walltimestamp);
        printf("\tadapter_stopped:\t%d\n", args[0]->hw.adapter_stopped);
        printf("\tmac_type:\t%d\n", args[0]->hw.mac.type);
        printf("\treset_if_overtemp:\t%d\n", args[0]->hw.phy.reset_if_overtemp);
        printf("\tsmart_speed:\t%d\n", args[0]->hw.phy.smart_speed);
        printf("\tmultispeed_fiber:\t%d\n", args[0]->hw.phy.multispeed_fiber);
}
