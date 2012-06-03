SELECT
	[name]
	,[type]
	,single_pages_kb + multi_pages_kb AS 'Total KB'
	,Convert(decimal(10,2), Round((single_pages_kb + multi_pages_kb) / 1024.0, 2), 2) AS 'Total MB'
	,Convert(decimal(10,2), Round((single_pages_kb + multi_pages_kb) / (1024.0 * 1024), 2)) AS 'Total GB'
	,entries_count
 FROM sys.dm_os_memory_cache_counters
 ORDER BY [Total KB] DESC