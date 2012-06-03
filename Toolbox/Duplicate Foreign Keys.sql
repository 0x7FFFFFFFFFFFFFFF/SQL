
Select
	object_schema_name(FKC.parent_object_id) + '.' + object_name(FKC.parent_object_id) + '.' + PC.name as [Parent Column],
	object_schema_name(FKC.referenced_object_id) + '.' + object_name(FKC.referenced_object_id) + '.' + RC.name as [Referenced Column],
	object_schema_name(FKC.constraint_object_id) + '.' + object_name(FKC.constraint_object_id) as [Constraint],
	Max(FKC.constraint_column_id) as [Columns],
	Max(Dup.Dups) as [Duplicated],
	'Alter table [' + object_schema_name(FKC.parent_object_id) + '].[' + object_name(FKC.parent_object_id) + '] drop constraint ' + quotename(object_name(FKC.constraint_object_id)) as [Drop]
 From sys.foreign_key_columns as FKC
 Inner Join sys.columns as PC on FKC.parent_object_id = PC.object_id and FKC.parent_column_id = PC.column_id
 Inner Join sys.columns as RC on FKC.referenced_object_id = RC.object_id and FKC.referenced_column_id = RC.column_id
 Inner Join (
	Select
		constraint_column_id,
		parent_object_id,
		parent_column_id,
		referenced_object_id,
		referenced_column_id,
		Count(constraint_column_id) as Dups
	 From sys.foreign_key_columns
	 Group by
		constraint_column_id,
		parent_object_id,
		parent_column_id,
		referenced_object_id,
		referenced_column_id
	 Having Count(distinct constraint_object_id) > 1
  ) as Dup on
	FKC.constraint_column_id = Dup.constraint_column_id and
	FKC.parent_object_id = Dup.parent_object_id and
	FKC.parent_column_id = Dup.parent_column_id and
	FKC.referenced_object_id = Dup.referenced_object_id and
	FKC.referenced_column_id = Dup.referenced_column_id
 Group by
	FKC.parent_object_id,
	FKC.referenced_object_id,
	PC.name,
	RC.name,
	FKC.constraint_object_id
 Order by
	[Parent Column],
	[Referenced Column],
	[Constraint]

Alter table [dbo].[n2AllowedRole] drop constraint [FKB30F0676AB29607]
Alter table [dbo].[n2Detail] drop constraint [FK1D14F83B4F9855AA]
Alter table [dbo].[n2Detail] drop constraint [FK1D14F83B6AB29607]
Alter table [dbo].[n2Detail] drop constraint [FK1D14F83B3AF5DAB0]
Alter table [dbo].[n2DetailCollection] drop constraint [FKBE85C49A6AB29607]
Alter table [dbo].[n2Item] drop constraint [FK18406FA018DD5AFD]
Alter table [dbo].[n2Item] drop constraint [FK18406FA04B1A4E60]
