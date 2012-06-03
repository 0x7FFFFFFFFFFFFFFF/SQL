Select
	O.type_desc as [Object Type],
	Object_schema_name(I.object_id) as [Schema],
	Object_name(I.object_id) as [Object],
	Sum(user_seeks) as Seeks,
	Sum(user_scans) as Scans,
	Sum(user_lookups) as Lookups,
	Sum(user_updates) as Updates
 From sys.dm_db_index_usage_stats as I
 Inner Join sys.objects as O on I.object_id = O.object_id
 Where database_id = db_id('FXAPPLICATION')
 Group by
	O.type_desc,
	Object_schema_name(I.object_id),
	Object_name(I.object_id)
