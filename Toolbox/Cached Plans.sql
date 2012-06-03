SELECT
	count(*) AS 'Number of Plans',
	sum(cast(size_in_bytes AS BIGINT))/1024/1024 AS 'Plan Cache Size (MB)'
 FROM sys.dm_exec_cached_plans

SELECT
	objtype AS 'Cached Object Type',
	count(*) AS 'Number of Plans',
	sum(cast(size_in_bytes AS BIGINT))/1024/1024 AS 'Plan Cache Size (MB)',
	avg(usecounts) AS 'Avg Use Count'
 FROM sys.dm_exec_cached_plans
 GROUP BY objtype

/*
NOTE: If Adhoc is high consider using sp_configure server level option OPTIMIZE FOR ADHOC WORKLOADS
*/

