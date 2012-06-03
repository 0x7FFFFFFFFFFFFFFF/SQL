--Stats
With x (object_id, stats_id, Name, list, key_ordinal, m, l) as (
	Select
		STC.object_id,
		STC.stats_id,
		Convert(varchar(255), C.Name),
		Convert(varchar(255), Quotename(C.Name)),
		STC.stats_column_id,
		Count(*) over (partition by STC.object_id, STC.stats_id) as m,
		1 as l
	 From sys.stats_columns as STC
	 Inner Join sys.columns as C on STC.object_id = C.object_id and STC.column_id = C.column_id
	Union all
	Select
		STC.object_id,
		STC.stats_id,
		Convert(varchar(255), X.Name + '__' + C.Name),
		Convert(varchar(255), X.List + ', ' + quotename(C.Name)),
		STC.stats_column_id,
		x.m,
		x.l + 1
	 From sys.stats_columns as STC
	 Inner Join sys.columns as C on STC.object_id = C.object_id and STC.column_id = C.column_id
	 Inner Join X as X on STC.object_id = X.object_id and STC.stats_id = X.stats_id and STC.stats_column_id = X.key_ordinal + 1
  )
Select
	object_schema_name(st.object_id) as [Schema],
	object_name(st.object_id) as [Table],
	'drop statistics ' + quotename(object_schema_name(st.object_id)) + '.' + quotename(object_name(st.object_id)) + '.' + quotename(ST.name) as [Drop],
	'Create statistics ' + quotename('ST_' + x.name) + ' on ' +
	  quotename(object_schema_name(st.object_id)) + '.' + quotename(object_name(st.object_id)) +
	  ' (' + x.list + ')' as [Create],
	'ST_' + x.name as [New Name],
	ST.name as [Old Name],
	x.list as List
 from x
 Inner Join sys.stats as ST on x.object_id = ST.object_id and x.stats_id = ST.stats_id
 Where
	l = m and
	ST.user_created = 1 and
	'ST_' + x.name != ST.name


-- Foreign Keys
Select *
 From (
	Select
		K.Name as [Is],
		'FK_' + object_schema_name(C.parent_object_id) + '.' + object_name(C.parent_object_id) + '.' + PC.name as Should,
		'Alter table ' + quotename(object_schema_name(C.parent_object_id)) + '.' + quotename(object_name(C.parent_object_id)) + ' drop constraint ' + quotename(K.Name) +
		'; ' +
		'Alter table ' + quotename(object_schema_name(C.parent_object_id)) + '.' + quotename(object_name(C.parent_object_id)) + ' add' +
		' constraint ' + quotename('FK_' + object_schema_name(C.parent_object_id) + '.' + object_name(C.parent_object_id) + '.' + PC.name) +
		' foreign key (' + quotename(PC.name) + ') ' +
		' references ' + quotename(object_schema_name(RC.object_id)) + '.' + quotename(object_name(RC.object_id)) + '(' + quotename(RC.name) + ')' as [Change]
	 From sys.foreign_key_columns as C
	 Inner Join sys.columns as PC on C.parent_object_id = PC.object_id and C.parent_column_id = PC.column_id
	 Inner Join sys.columns as RC on C.referenced_object_id = RC.object_id and C.referenced_column_id = RC.column_id
	 Inner Join sys.foreign_keys as K on C.constraint_object_id = K.object_id
	 Where
		C.referenced_object_id != object_id('dbo.U_Users')
		--and C.parent_object_id not in (
		--	object_id('[dbo].[R_Deals]'),
		--	object_id('[dbo].[R_DealsBens]'),
		--	object_id('[dbo].[R_DealsBensTracking]'),
		--	object_id('[dbo].[R_DealsTracking]'),
		--	object_id('[dbo].[U_Beneficiaries]'),
		--	object_id('[dbo].[U_BeneficiariesTracking]'),
		--	object_id('[dbo].[U_TelephoneNumbersTracking]'),
		--	object_id('[dbo].[U_Users]'),
		--	object_id('[dbo].[U_UsersTracking]')
		-- )	 
   ) as T
  Where [is] != Should
  Order by Should

-- Missing foreign Keys
Select
	object_schema_name(C.object_id) as [Schema],
	T.Name as [Table],
	C.Name as [Column],
	'Alter table ' + quotename(object_schema_name(C.object_id)) + '.' + quotename(T.Name) + ' add' +
	' constraint ' + quotename('FK_' + object_schema_name(C.object_id) + '.' + object_name(C.object_id) + '.' + C.name) +
	' foreign key (' + quotename(C.name) + ')' +
	' references '
 From sys.columns as C
 Left Outer Join (
	Select I.object_id, IC.column_id
	 From sys.indexes as I
	 Inner Join sys.index_columns as IC on I.object_id = IC.object_id and I.index_id = IC.index_id
	 Where is_primary_key = 1
  ) as PrimaryKeys on c.object_id = PrimaryKeys.object_id and C.column_id = PrimaryKeys.column_id
 Left Outer Join sys.foreign_key_columns as FK on FK.parent_object_id = C.object_id and FK.parent_column_id = C.column_id
 Inner Join sys.tables as T on C.object_id = T.object_id
 Where
	C.Name like '%\_ID%' escape '\' and -- Is an ID column
	FK.parent_object_id is null and -- not referecing another column
	PrimaryKeys.object_id is null and -- not a primary key column
	object_schema_name(C.object_id) not in ('Archive', 'InterfaceStaging')

-- Indexes
	With x (object_id, index_id, Name, list, key_ordinal, m, l) as (
		Select
			IXC.object_id,
			IXC.index_id,
			Convert(varchar(255), C.Name),
			Convert(varchar(255), C.Name),
			IXC.key_ordinal,
			Count(*) over (partition by IXC.object_id, IXC.index_id) as m,
			1 as l
		 From sys.index_columns as IXC
		 Inner Join sys.columns as C on IXC.object_id = C.object_id and IXC.column_id = C.column_id
		 Where IXC.is_included_column = 0
		Union all
		Select
			IXC.object_id,
			IXC.index_id,
			Convert(varchar(255), X.Name + '__' + C.Name),
			Convert(varchar(255), X.List + ', ' + quotename(C.Name)),
			IXC.key_ordinal,
			x.m,
			x.l + 1
		 From sys.index_columns as IXC
		 Inner Join sys.columns as C on IXC.object_id = C.object_id and IXC.column_id = C.column_id
		 Inner Join X as X on IXC.object_id = X.object_id and IXC.index_id = X.index_id and IXC.key_ordinal = X.key_ordinal + 1
		 Where IXC.is_included_column = 0
	  )
	 Select
		object_schema_name(X.[object_id]) [Schema],
		object_name(X.[object_id]) as [Table],
		is_primary_key,
		is_unique,
		is_unique_constraint,
		I.name as [Is],
		Case
			When CharIndex('-', I.Name) = 0 then I.Name
			Else Left(I.Name, CharIndex('-', I.Name) - 1)
		 end as [Is2],
		Case
			When is_primary_key = 1
			 then 'PK_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)
			When is_unique = 1 or is_unique_constraint = 1
			 then 'UQ_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)
			Else 'IX_' + X.[Name]
		end as [Should],

		Case
			When is_primary_key = 1 then
				'alter table ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) + ' drop constraint ' + quotename(I.Name) + ';' +
				' alter table ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) +
				' add constraint ' +  quotename('PK_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)) +
				' primary key ' + case when I.type > 1 then 'nonclustered' else '' end +
				' (' + X.list + ')'
			When is_unique = 1 or is_unique_constraint = 1 then
				'alter table ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) + ' drop constraint ' + quotename(I.Name) + ';' +
				' alter table ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) +
				' add constraint ' +  quotename('PK_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)) +
				' unique ' + case when I.type > 1 then 'nonclustered' else '' end +
				' (' + X.list + ')'
			Else
				'drop index ' + quotename(I.Name) + ' on ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) + ';' +
				' create index ' + quotename('IX_' + X.Name) +
				' on ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id)) +
				' (' + X.List + ')'
		end as Change
	 from X as X
	 Inner Join sys.indexes as I on X.[object_id] = I.object_id and X.[index_id] = I.index_id
	 Left Outer Join (
		Select distinct object_id, index_id
		 From sys.index_columns
		 Where is_included_column = 1
	  ) as HasIncludedColumns on I.[object_id] = HasIncludedColumns.object_id and I.[index_id] = HasIncludedColumns.index_id
	 Inner Join sys.tables as T on X.[object_id] = T.object_id
	 where
		m = l and
		Case
			When CharIndex('-', I.Name) = 0 then I.Name
			Else Left(I.Name, CharIndex('-', I.Name) - 1)
		 end !=
		Case
			When is_primary_key = 1
			 then 'PK_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)
			When is_unique = 1 or is_unique_constraint = 1
			 then 'UQ_' + object_schema_name(I.object_id) + '.' + object_name(I.object_id)
			Else 'IX_' + X.[Name]
		 End

		and HasIncludedColumns.object_id is null
		and is_primary_key = 0
		and is_unique = 0 and is_unique_constraint = 0
	Order by [Schema], [Table]

-- Defaults
Select *
 From (
	Select
		DF.Name as [Is],
		'DF_' + object_schema_name(DF.parent_object_id) + '.' + object_name(DF.parent_object_id) + '.' + C.Name as Should,
		'Alter table ' + quotename(object_schema_name(DF.parent_object_id)) + '.' + quotename(object_name(DF.parent_object_id)) + ' drop constraint ' + quotename(DF.Name) + ';' +
		' Alter table ' + quotename(object_schema_name(DF.parent_object_id)) + '.' + quotename(object_name(DF.parent_object_id)) +
		' add constraint ' + quotename('DF_' + object_schema_name(DF.parent_object_id) + '.' + object_name(DF.parent_object_id) + '.' + C.Name) +
		' default ' + Definition + ' for ' + quotename(C.Name) as [Change]
	 From sys.default_constraints as DF
	 Inner Join sys.columns as C on DF.parent_object_id = C.object_id and DF.parent_column_id = C.column_id
  ) as T
 Where [Is] != Should
 Order by Should



