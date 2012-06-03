SELECT
	[type]
	,memory_node_id
	,single_pages_kb
	,multi_pages_kb
	,virtual_memory_reserved_kb as 'VM Reserved KB'
	,Convert(decimal(10,2), Round(virtual_memory_reserved_kb / 1024.0, 2)) as 'VM Reserved MB'
	,Convert(decimal(10,2), Round(virtual_memory_reserved_kb / (1024.0 * 1024), 2)) as 'VM Reserved GB'
	,virtual_memory_committed_kb as 'VM Commited KB'
	,Convert(decimal(10,2), Round(virtual_memory_committed_kb / 1024.0, 2)) as 'VM Commited MB'
	,Convert(decimal(10,2), Round(virtual_memory_committed_kb / (1024.0 * 1024), 2)) as 'VM Commited GB'
	,awe_allocated_kb
 FROM sys.dm_os_memory_clerks
 ORDER BY virtual_memory_reserved_kb DESC