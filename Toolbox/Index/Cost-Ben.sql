/*
---------------------------------------------------------------------------------------
Large posative numbers are bad
---------------------------------------------------------------------------------------
*/

Select
	Object_schema_name(I.object_id) as [Schema],
	Obj.name as [Object],
	I.name as [Index],
	user_updates - (user_seeks + user_scans + user_lookups) as [cost-ben],
	user_seeks + user_scans + user_lookups as [usage_reads],
	isNull(range_scan_count, 0) + isNull(singleton_lookup_count, 0) as [operational_reads]
	
	--, range_scan_count
	--, singleton_lookup_count
	, 'usage writes'					= user_updates
	, 'operational_leaf_writes'			= leaf_insert_count+leaf_update_count+ leaf_delete_count 
	--	, leaf_insert_count,leaf_update_count,leaf_delete_count 
	, 'operational_leaf_page_splits'	= leaf_allocation_count
	, 'operational_nonleaf_writes'		= nonleaf_insert_count + nonleaf_update_count + nonleaf_delete_count
	, 'operational_nonleaf_page_splits'	= nonleaf_allocation_count
	,'drop index ' + quotename(i.name) + ' on ' + quotename(object_schema_name(i.object_id)) + '.' + quotename(object_name(i.object_id))
 From sys.indexes as I
 Inner Join sys.objects as Obj on I.object_id = Obj.object_id
 Left Outer Join sys.dm_db_index_usage_stats as U on I.object_id = U.object_id and I.index_id = U.index_id
 Left Outer Join sys.dm_db_index_operational_stats (db_id(),NULL,NULL,NULL) as O on I.object_id = O.object_id and I.index_id = O.index_id
 Where
	Obj.is_ms_shipped = 0
	and i.is_primary_key = 0
	and i.is_unique = 0
--	and Obj.name like '%spotrate%'
--	and object_id('spotrate') = i.object_id
 order by
--	Object,
	[cost-ben] desc, operational_reads desc, operational_leaf_writes, operational_nonleaf_writes
go