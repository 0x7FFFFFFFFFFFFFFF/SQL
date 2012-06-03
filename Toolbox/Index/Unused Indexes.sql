---------------------------------------------------------------------------------------
-- Unused Indexes
--
-- Need to edit
--
---------------------------------------------------------------------------------------
select
	schema_name(tables.schema_id) as [Schema]	
	,tables.name as [table]
	,indexes.name as [Index]
	,stats.last_user_update
	,stats.user_updates
	,stats.system_updates
	,indexes.type_desc
	,'drop index ' + quotename(indexes.name) + ' on ' + quotename(schema_name(tables.schema_id)) + '.' + quotename(tables.name)
--,*
 from
	Sys.dm_db_index_usage_stats as stats
	left outer join sys.indexes as indexes on indexes.object_id = stats.OBJECT_ID and indexes.index_id = stats.index_id
	inner join sys.tables as tables on indexes.object_id = tables.object_id
	inner join sys.databases as dbs on stats.database_id = dbs.database_id
 where
	stats.database_id = db_id()
	and objectproperty(indexes.object_id,'IsUserTable') = 1
	and last_user_seek is null 
	and last_user_scan is null 
	and last_user_lookup is null
	and indexes.type != 0
	and indexes.is_primary_key = 0 and indexes.is_unique = 0
-- order by [Schema], [table], [Index]
 order by user_updates desc
go


