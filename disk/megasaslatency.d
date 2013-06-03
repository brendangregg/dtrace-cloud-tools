#!/usr/sbin/dtrace -s
/*
 * megasaslatency.d	Latency from the mega_sas driver.
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
 * This traces driver internals, and is likely to only work for some
 * versions of the driver.
 */

fbt:mega_sas:issue_cmd_ppc:entry
{
	start[arg0] = timestamp;
}

fbt:mega_sas:return_mfi_pkt:entry
/this->start = start[arg1]/
{
	@time["mega_sas cmd latency (ns)"] = quantize(timestamp - this->start);
	start[arg1] = 0;
}
