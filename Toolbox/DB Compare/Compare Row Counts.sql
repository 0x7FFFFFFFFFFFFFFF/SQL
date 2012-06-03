Select
	object_schema_name(T.object_id) as [Schema],
	T.name as [Table],
	object_schema_name(T.object_id) + '.' + T.name as [Name],
	IPS_Src.record_count,
	IPS_Dst.record_count,
	IPS_Src.page_count,
	IPS_Dst.page_count,
	IPS_Src.alloc_unit_type_desc,
	IPS_Dst.alloc_unit_type_desc,
	T.object_id,
	T2.object_id,
	I.object_id,
	I2.object_id,
	I.index_id,
	I2.index_id	
 From sys.tables as T
 Inner Join FXAPPLICATION_RefreshSource.sys.tables as T2 on T.object_id = T2.object_id
 Inner Join sys.indexes as I on T.object_id = I.object_id and I.type = 1
 Inner Join FXAPPLICATION_RefreshSource.sys.indexes as I2 on T2.object_id = I2.object_id and I2.type = 1
 Cross Apply sysmaint.dm_db_index_physical_stats(db_id(), T.object_id, I.index_id, 'SAMPLED', 'IN_ROW_DATA') as IPS_Dst
 Cross Apply sysmaint.dm_db_index_physical_stats(db_id('FXAPPLICATION_RefreshSource'), T2.object_id, I2.index_id, 'SAMPLED', 'IN_ROW_DATA') as IPS_Src
 Where
	T.is_ms_shipped = 0 and
--	IPS_Dst.page_count != IPS_Src.page_count and
--	IPS_Dst.record_count = 0 and IPS_Src.record_count > 1
	IPS_Dst.record_count < IPS_Src.record_count
	--IPS_Dst.alloc_unit_type_desc = 'IN_ROW_DATA' and
	--IPS_Src.alloc_unit_type_desc = 'IN_ROW_DATA'
