Select
	schema_name(T.schema_id) as [Schema],
	T.name as [Table],
	Case when [Identity].name is not null then 1 else 0 end as [Identity Column],
	IndexSummary.has_primary_key as [Primary Key],
	IndexSummary.has_unique_constraint as [Unique Key],
	IndexSummary.has_unique as [Unique index],
	Case when [ID Column].object_id is not null then 1 else 0 end as [ID Column],
	'Alter table [' + schema_name(T.schema_id) + '].[' + T.name + '] ' +
	 'add constraint [PK_' + schema_name(T.schema_id) + '.' + T.name + '] primary key ([' + isNull([Identity].name, '<<Insert PK columns here>>') + '])' as [Add Clustered Primary Key],
	'Alter table [' + schema_name(T.schema_id) + '].[' + T.name + '] drop constraint [' + PK.name + ']' as [Drop Primary Key],
	'Alter table [' + schema_name(T.schema_id) + '].[' + T.name + '] ' +
	 'add constraint [PK_' + schema_name(T.schema_id) + '.' + T.name + '] unique ([' + isNull([Identity].name, '<<Insert PK columns here>>') + '])' as [Add Clustered Unique Key]
 From sys.indexes as I
 Inner Join sys.tables as T on I.object_id = T.object_id
 Left Outer Join (
	Select
		object_id,
		Case when Sum(Convert(int, is_unique)) > 0 then 1 else 0 end as has_unique,
		Case when Sum(Convert(int, is_primary_key)) > 0 then 1 else 0 end as has_primary_key,
		Case when Sum(Convert(int, is_unique_constraint)) > 0 then 1 else 0 end as has_unique_constraint
	 From sys.indexes
	 Group by object_id
  ) as IndexSummary on I.object_id = IndexSummary.object_id
 Left Outer Join sys.key_constraints as PK on T.object_id = PK.parent_object_id and PK.type = 'PK'
 Left Outer Join sys.columns as [ID Column] on T.object_id = [ID Column].object_id and T.name + 'ID' = [ID Column].name
 Left Outer Join sys.columns as [Identity] on T.object_id = [Identity].object_id and [Identity].is_identity = 1
 Where
	T.is_ms_shipped = 0 and
	I.type = 0
 Order by
	[Identity Column] desc,
	[Primary Key] desc,
	[Unique Key] desc,
	[Unique index] desc,
	[ID Column] desc,
	[Schema],
	[Table]
