-- Clear from previous execustion
If exists (select * from tempdb.sys.tables where name like '#Results%') drop table #Results
If exists (select * from tempdb.sys.tables where name like '#T%') drop table #T

-- Setup structures
Create table #Results (
	method varchar(4),
	[object] sysname,
	[schema] sysname,
	index_id int,
	partition_number int,
	[size_with_current_compression_setting (KB)] bigint,
	[size_with_requested_compression_setting (KB)] bigint,
	[sample_size_with_current_compression_setting (KB)] bigint,
	[sample_size_with_requested_compression_setting (KB)] bigint)

Create table #T (
	[object] sysname,
	[schema] sysname,
	index_id int,
	partition_number int,
	[size_with_current_compression_setting (KB)] bigint,
	[size_with_requested_compression_setting (KB)] bigint,
	[sample_size_with_current_compression_setting (KB)] bigint,
	[sample_size_with_requested_compression_setting (KB)] bigint)

Declare @Schema sysname, @Object sysname, @index_id int

-- Get list of objects
Declare o cursor for
 Select schema_name(O.schema_id), O.name, I.index_id
  From sys.objects as O
  Inner Join sys.indexes as I on O.object_id = I.object_id
  Inner Join sys.partitions as P on I.object_id = P.object_id and I.index_id = P.index_id and P.data_compression = 0
  Cross Apply sysmaint.dm_db_index_physical_stats(db_id(), O.object_id, I.index_id, 'LIMITED', 'IN_ROW_DATA') as S
  Where S.page_count > (1024 / 8) * 512 -- last number is MB

open o

Fetch next from o into @Schema, @Object, @index_id

While @@FETCH_STATUS = 0
 Begin

	Print Convert(varchar(300), @Schema) + '.' + Convert(varchar(300), @Object)

	Truncate table #T

	Insert into #T (
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)])
	exec sp_estimate_data_compression_savings @Schema, @Object, @index_id, null, 'page'

	Insert into #Results (
		method,
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)])
	 Select
		'page',
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)]
	  From #T

	Truncate table #T

	Insert into #T (
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)])
	exec sp_estimate_data_compression_savings @Schema, @Object, @index_id, null, 'page'

	Insert into #Results (
		method,
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)])
	 Select
		'row',
		object,
		[schema],
		index_id,
		partition_number,
		[size_with_current_compression_setting (KB)],
		[size_with_requested_compression_setting (KB)],
		[sample_size_with_current_compression_setting (KB)],
		[sample_size_with_requested_compression_setting (KB)]
	  From #T
	 
	 Fetch next from o into @Schema, @Object, @index_id
 End

close o
deallocate o

Select
	P.[schema],
	P.object,
	I.name as [index],
	P.[size_with_current_compression_setting (KB)] / 1024 as [Before (MB)],
	P.[size_with_requested_compression_setting (KB)] / 1024 as [Page (MB)],
	R.[size_with_requested_compression_setting (KB)] / 1024 as [Row (MB)],
	(P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)]) / 1024 as [Page Saved (MB)],
	(P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)]) / 1024 as [Row Saved (MB)],
	Convert(decimal(19, 2), 100 * (P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)]) / Convert(decimal(19, 2), P.[size_with_current_compression_setting (KB)])) as [Page Saved (%)],
	Convert(decimal(19, 2), 100 * (P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)]) / Convert(decimal(19, 2), P.[size_with_current_compression_setting (KB)])) as [Row Saved (%)],
	Case
		When (P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)]) > (P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)]) Then 'Page'
		Else 'Row'
	 End as [Best Saving],
	Case
		When (P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)]) > (P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)])
		 Then (P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)])
		Else (P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)])
	 End / 1024 as [Best Saving (MB)],
	Case when Replicated.[schema] is null then 'No' else 'Yes' end as [Replicated],
	'alter index ' + quotename(I.name) + ' on ' + quotename(P.[schema]) + '.' + quotename(P.object) + ' rebuild with (data_compression = ' + 
	 Case
		When (P.[size_with_current_compression_setting (KB)] - P.[size_with_requested_compression_setting (KB)]) > (P.[size_with_current_compression_setting (KB)] - R.[size_with_requested_compression_setting (KB)]) Then 'Page'
		Else 'Row'
	  End + ')'
 From #Results as P
 Inner Join #Results R on P.[schema] = R.[schema] and P.object = R.object and P.index_id = R.index_id and R.method = 'row'
 Inner Join sys.indexes as I on object_id(quotename(P.[schema]) + '.' + quotename(P.object)) = I.object_id and P.index_id = I.index_id
 Left Outer Join (
	Select distinct source_owner as [schema], source_object as object
	 From distribution.dbo.MSarticles
	 Where publisher_db = db_name()
  ) as Replicated on P.[schema] = Replicated.[schema] and P.object = Replicated.object
 Where
	P.method = 'page' and
	P.[size_with_current_compression_setting (KB)] > 0 --and -- minium space saved
--	Replicated.[schema] is null -- not replicated
 Order by [Best Saving (MB)] desc





