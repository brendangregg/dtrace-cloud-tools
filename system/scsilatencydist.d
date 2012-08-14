#!/usr/sbin/dtrace -s
/*
 * scsilatencydist.d	show SCSI I/O latency distribution.
 *
 * This is based on scsilatency.d from the DTrace book, chapter 4.
 *
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at http://smartos.org/CDDL
 *
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file.
 *
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 * Copyright (c) 2012 Joyent Inc., All rights reserved.
 * Copyright (c) 2012 Brendan Gregg, All rights reserved.
 *
 * TESTED: this fbt provider based script may only work on some OS versions.
 *      121: ok
 */

#pragma D option quiet

string scsi_cmd[uchar_t];

dtrace:::BEGIN
{
	/* See /usr/include/sys/scsi/generic/commands.h for the full list. */
	scsi_cmd[0x00] = "test_unit_ready";
	scsi_cmd[0x08] = "read";
	scsi_cmd[0x0a] = "write";
	scsi_cmd[0x12] = "inquiry";
	scsi_cmd[0x17] = "release";
	scsi_cmd[0x1a] = "mode_sense";
	scsi_cmd[0x1b] = "load/start/stop";
	scsi_cmd[0x1c] = "get_diagnostic_results";
	scsi_cmd[0x1d] = "send_diagnostic_command";
	scsi_cmd[0x25] = "read_capacity";
	scsi_cmd[0x28] = "read(10)";
	scsi_cmd[0x2a] = "write(10)";
	scsi_cmd[0x35] = "synchronize_cache";
	scsi_cmd[0x4d] = "log_sense";
	scsi_cmd[0x5e] = "persistent_reserve_in";
	scsi_cmd[0xa0] = "report_luns";

	printf("Tracing... Hit Ctrl-C to end.\n\n");
}

fbt::scsi_transport:entry
{
	start[arg0] = timestamp;
}

fbt::scsi_destroy_pkt:entry
/start[arg0]/
{
	this->delta = timestamp - start[arg0];
	this->code = *args[0]->pkt_cdbp;
	this->cmd = scsi_cmd[this->code] != NULL ?
	    scsi_cmd[this->code] : lltostr(this->code);
	this->reason = args[0]->pkt_reason == 0 ? "Success" :
	    strjoin("Fail:", lltostr(args[0]->pkt_reason));

	@[this->cmd, this->reason, "time (ns)"] = quantize(this->delta);

	start[arg0] = 0;
}

dtrace:::END
{
	printa("  %-25s %-26s %s%@d\n", @);
}
