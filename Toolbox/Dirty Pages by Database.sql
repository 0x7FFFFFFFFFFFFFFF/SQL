SELECT
	db_name(database_id) AS 'Database',
	count(page_id) AS 'Dirty Pages',
	count(page_id) / 8 AS 'Dirty KB',
	count(page_id) / (8 * 1024) AS 'Dirty MB',
	count(page_id) / (8 * 1024 * 1024) AS 'Dirty GB'
 FROM sys.dm_os_buffer_descriptors
 WHERE is_modified =1
 GROUP BY db_name(database_id)
 ORDER BY count(page_id) DESC
