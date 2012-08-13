#!/usr/sbin/dtrace -s
/*
 * mysqld_pid_rowerrors.d  Print row_mysql_handle_errors() latency dist.
 *
 * USAGE: ./mysqld_pid_rowerrors.d -p mysqld_PID
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
 * TESTED: these pid-provider probes may only work on some mysqld versions.
 *	5.0.51a: ok
 */

#pragma D option quiet

dtrace:::BEGIN
{
	/* from innobase/include/db0err.h: */
	dberr2str[10] = "DB_SUCCESS";
	dberr2str[11] = "DB_ERROR";
	dberr2str[12] = "DB_OUT_OF_MEMORY";
	dberr2str[13] = "DB_OUT_OF_FILE_SPACE";
	dberr2str[14] = "DB_LOCK_WAIT";
	dberr2str[15] = "DB_DEADLOCK";
	dberr2str[16] = "DB_ROLLBACK";
	dberr2str[17] = "DB_DUPLICATE_KEY";
	dberr2str[18] = "DB_QUE_THR_SUSPENDED";
	dberr2str[19] = "DB_MISSING_HISTORY";
	dberr2str[30] = "DB_CLUSTER_NOT_FOUND";
	dberr2str[31] = "DB_TABLE_NOT_FOUND";
	dberr2str[32] = "DB_MUST_GET_MORE_FILE_SPACE";
	dberr2str[33] = "DB_TABLE_IS_BEING_USED";
	dberr2str[34] = "DB_TOO_BIG_RECORD";
	dberr2str[35] = "DB_LOCK_WAIT_TIMEOUT";
	dberr2str[36] = "DB_NO_REFERENCED_ROW";
	dberr2str[37] = "DB_ROW_IS_REFERENCED";
	dberr2str[38] = "DB_CANNOT_ADD_CONSTRAINT";
	dberr2str[39] = "DB_CORRUPTION";
	dberr2str[40] = "DB_COL_APPEARS_TWICE_IN_INDEX";
	dberr2str[41] = "DB_CANNOT_DROP_CONSTRAINT";
	dberr2str[42] = "DB_NO_SAVEPOINT";
	dberr2str[43] = "DB_TABLESPACE_ALREADY_EXISTS";
	dberr2str[44] = "DB_TABLESPACE_DELETED";
	dberr2str[45] = "DB_LOCK_TABLE_FULL";
	dberr2str[1000] = "DB_FAIL";
	dberr2str[1001] = "DB_OVERFLOW";
	dberr2str[1002] = "DB_UNDERFLOW";
	dberr2str[1003] = "DB_STRONG_FAIL";
	dberr2str[1500] = "DB_RECORD_NOT_FOUND";
	dberr2str[1501] = "DB_END_OF_INDEX";
	dberr2str[0] = "<unknown>";

	printf("Tracing MySQL PID %d... Hit Ctrl-C to end.\n", $target);
}

pid$target::*dispatch_command*:entry
{
	@queries = count();
}

pid$target::row_mysql_handle_errors:entry
{
	self->err = *(int *)copyin(arg0, 4);
	self->start = timestamp;
}

pid$target::row_mysql_handle_errors:return
/self->start/
{
	@dist[dberr2str[self->err]] = quantize(timestamp - self->start);
	@num = count();
	self->start = 0;
}

dtrace:::END
{
	printa("MySQL filesort: %@d, from queries: %@d; latency dist (ns):\n",
	    @num, @queries);
	printa(@dist);
}
