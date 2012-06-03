Select
	schema_name(O.schema_id) as [Schema],
	O.name as [Object],
	O.type_desc as [Object Type],
	I.name as [Index],
	I.type_desc as [Index Type],
	I.is_primary_key,
	Case when [Key].object_id is not null then 1 else 0 end as [Key Index],
	Case when ReferencedByFK.object_id is not null then 1 else 0 end as [Referenced By FK],
	DS.name as [File Group],
	'alter table [' + schema_name(O.schema_id) + '].[' + O.name + '] drop constraint [' + I.name + '] with (move to [<<Insert File Group Name Here>>])',
	'Drop index [' + I.name + '] on [' + schema_name(O.schema_id) + '].[' + O.name + ']' as [Drop Index]
 From sys.indexes as I
 Left Outer Join (
	Select distinct IC.object_id, IC.index_id
	 From sys.index_columns as IC
	 Inner Join sys.foreign_key_columns as FKC on IC.object_id = FKC.referenced_object_id and IC.column_id = FKC.referenced_column_id
  ) as ReferencedByFK on I.object_id = ReferencedByFK.object_id and I.index_id = ReferencedByFK.index_id
 Left Outer Join sys.key_constraints as [Key] on I.object_id = [Key].object_id and I.index_id = [Key].unique_index_id
 Inner Join sys.objects as O on I.object_id = O.object_id
 Inner Join sys.data_spaces as DS on I.data_space_id = DS.data_space_id
 Where
	O.is_ms_shipped = 0
 Order by
	[Index Type],
	is_primary_key,
	[Referenced By FK]
