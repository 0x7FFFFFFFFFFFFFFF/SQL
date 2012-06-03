Select
	object_schema_name(T.object_id) as [Schema],
	T.name as [Table],
	object_schema_name(T.object_id) + '.' + T.name as [Name],
	IPS.record_count,
	IPS.page_count,
	IPS.alloc_unit_type_desc,
	T.object_id,
	I.object_id,
	I.index_id
 From sys.tables as T
 Inner Join sys.indexes as I on T.object_id = I.object_id and I.type = 1
 Cross Apply sysmaint.dm_db_index_physical_stats(db_id(), T.object_id, I.index_id, 'SAMPLED', 'IN_ROW_DATA') as IPS
