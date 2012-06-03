
-- Declare Paramerters
Declare
	@DB_Name sysname,
	@reorg_threshold float,
	@rebuild_threshold float,
	@min_pages int,
	@nonclustered_only bit,
	@mode sysname,
	@script_only bit
Declare @Exclude table ([str] varchar(50))

-- Set Paramerters
Select
	@DB_Name = N'FXAPPLICATION',
	@reorg_threshold = 5.0,
	@rebuild_threshold = 30.0,
	@min_pages = 100,
	@nonclustered_only = 1,
	@mode = N'SAMPLED', -- Options: LIMITED, SAMPLED, DETAILED
	@script_only = 1
Insert into @Exclude ([str]) VALUES ('%World%')
Insert into @Exclude ([str]) VALUES ('%Tracking')
Insert into @Exclude ([str]) VALUES ('%Historical%')

-----------------------------------------------------------------------8198
-- Script
-----------------------------------------------------------------------

Declare
	@object_id int,
	@index_id int,
	@avg_fragmentation_in_percent float,
	@index_name nvarchar(258),
	@object_name nvarchar(516),
	@sql nvarchar(2000)

Select
	IX.object_id,
	IX.index_id,
	OBJECT_SCHEMA_NAME(IX.object_ID) as [Schema],
	OBJECT_NAME(IX.object_ID) as [Table],
	IX.Name as [Index],
	index_type_desc,
	CONVERT(decimal(5, 3), ROUND(avg_fragmentation_in_percent, 3)) as avg_fragmentation_in_percent,
	fragment_count,
	avg_fragment_size_in_pages,
	page_count,
	avg_page_space_used_in_percent,
	min_record_size_in_bytes,
	max_record_size_in_bytes,
	avg_record_size_in_bytes 
 into #Indexes
 From sys.dm_db_index_physical_stats (DB_ID(@DB_Name), NULL, NULL , NULL, @mode) as PStats
 Inner Join sys.indexes as IX on PStats.OBJECT_ID = IX.OBJECT_ID and PStats.index_id = IX.index_id
 Left Outer Join @Exclude as Exclude on OBJECT_NAME(IX.object_ID) like Exclude.[str]
 Where
	avg_fragmentation_in_percent >= @reorg_threshold and page_count > @min_pages and
	(@nonclustered_only = 0 or index_type_desc = 'NONCLUSTERED INDEX') and
	Exclude.[str] is null
 Order by avg_fragmentation_in_percent desc

Select * from #Indexes

declare [index] cursor for select object_id, index_id, avg_fragmentation_in_percent from #Indexes
open [index]
Fetch next from [index]
 into @object_id, @index_id, @avg_fragmentation_in_percent

While @@FETCH_STATUS = 0
 Begin
	Select @index_name = QUOTENAME(Indexes.name)
	 From sys.indexes
	 Where [object_id] = @object_id and index_id = @index_id
	Set @object_name = QUOTENAME(object_schema_name(@object_id)) + '.' + QUOTENAME(OBJECT_NAME(@object_id))
 	
	If @avg_fragmentation_in_percent >= @rebuild_threshold
		Set @sql = 'Alter index ' + @index_name + ' on ' + @object_name + ' rebuild' + case when SERVERPROPERTY('Edition') = 'Enterprise Edition' then ' with (online = on)' else '' end
	 else
		Set @sql = 'Alter index ' + @index_name + ' on ' + @object_name + ' reorganize'
 	
	print @sql
	If @script_only = 0 exec (@sql)

	Fetch next from [index]
	 into @object_id, @index_id, @avg_fragmentation_in_percent
 End

close [index]
deallocate [index]

drop table #Indexes


--select * from sys.indexes where OBJECT_ID = 1927482441 and index_id = 63
