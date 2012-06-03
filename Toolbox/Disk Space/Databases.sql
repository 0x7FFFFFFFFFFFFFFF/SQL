If exists (Select * from tempdb.sys.tables where name like '%DatabaseAllocation%')
Drop table #DatabaseAllocation

Create table #DatabaseAllocation (database_id int primary key, total_pages bigint, used_pages bigint)
Declare @db_id int, @sql varchar(8000)

exec sp_MSforeachdb 'use ?
Insert into #DatabaseAllocation (database_id, total_pages, used_pages)
Select DB_ID(), sum(a.total_pages), sum(a.used_pages)
 From sys.partitions p  
 Inner Join sys.allocation_units a on p.partition_id = a.container_id'

Select
	D.name as [Database],
	D.recovery_model_desc as [Recovery Model],
	RowFilesSummary.Files as [Data Files],
	LEFT(RowFilesSummary.size, CHARINDEX('.', RowFilesSummary.size) + 2) as [File Data (GB)],
	LEFT(Allocation.total_pages, CHARINDEX('.', Allocation.total_pages) + 2) as [Allocation Total (GB)],
	LEFT(Allocation.used_pages, CHARINDEX('.', Allocation.used_pages) + 2) as [Allocation Used (GB)],
	LEFT(Allocation.unused_pages, CHARINDEX('.', Allocation.unused_pages) + 2) as [Allocation Unused (GB)],
	LogFilesSummary.Files as [Log Files],
	LEFT(LogFilesSummary.size, CHARINDEX('.', RowFilesSummary.size) + 2) as [Log (GB)],
	D.log_reuse_wait_desc as [Log Reuse Wait]
 From sys.databases as D
 Left Outer Join (
	Select
		database_id,
		Round((total_pages * 8) / (1024.0 * 1024.0), 2) as total_pages,
		Round((used_pages * 8) / (1024.0 * 1024.0), 2) as used_pages,
		Round(((total_pages - used_pages) * 8) / (1024.0 * 1024.0), 2) as unused_pages
	 From #DatabaseAllocation
  ) as Allocation on D.database_id = Allocation.database_id
 Left Outer Join (
	Select
		database_id,
		COUNT(database_id) as Files,
		Round((Sum(size) * 8) / (1024.0 * 1024.0), 2) as size
	 From sys.master_files
	 Where type = 0
	 Group by database_id
  ) as RowFilesSummary on D.database_id = RowFilesSummary.database_id
 Left Outer Join (
	Select
		database_id,
		COUNT(database_id) as Files,
		Round((Sum(size) * 8) / (1024.0 * 1024.0), 2) as size
	 From sys.master_files
	 Where type = 1
	 Group by database_id
  ) as LogFilesSummary on D.database_id = LogFilesSummary.database_id
 Order by
--	[Database],
	Allocation.unused_pages desc,
	Allocation.used_pages desc








/*

-- From trace of standard report

begin try 
declare @dbsize bigint 
declare @logsize bigint 
declare @database_size_mb float  
declare @unallocated_space_mb float  
declare @reserved_mb float  
declare @data_mb float  
declare @log_size_mb float
declare @index_mb float  
declare @unused_mb float  
declare @reservedpages bigint 
declare @pages bigint 
declare @usedpages bigint

select @dbsize = sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) 
        ,@logsize = sum(convert(bigint,case when status & 64 != 0 then size else 0 end)) 
from dbo.sysfiles 

select @reservedpages = sum(a.total_pages) 
        ,@usedpages = sum(a.used_pages) 
        ,@pages = sum(CASE 
                        WHEN it.internal_type IN (202,204) THEN 0 
                        WHEN a.type != 1 THEN a.used_pages 
                        WHEN p.index_id < 2 THEN a.data_pages 
                        ELSE 0 
                     END) 
from sys.partitions p  
join sys.allocation_units a on p.partition_id = a.container_id 
left join sys.internal_tables it on p.object_id = it.object_id 
 
select @database_size_mb = (convert(dec (15,2),@dbsize) + convert(dec(15,2),@logsize)) * 8192 / 1048576.0 
select @unallocated_space_mb =(case 
                                when @dbsize >= @reservedpages then (convert (dec (15,2),@dbsize) - convert (dec (15,2),@reservedpages)) * 8192 / 1048576.0  
                                else 0  
                              end)
                               
select  @reserved_mb = @reservedpages * 8192 / 1048576.0 
select  @data_mb = @pages * 8192 / 1048576.0 
select  @log_size_mb = convert(dec(15,2),@logsize) * 8192 / 1048576.0
select  @index_mb = (@usedpages - @pages) * 8192 / 1048576.0 
select  @unused_mb = (@reservedpages - @usedpages) * 8192 / 1048576.0

select 
        @database_size_mb as 'database_size_mb'
,       @reserved_mb as 'reserved_mb'
,       @unallocated_space_mb as 'unallocated_space_mb'
,       (@reserved_mb + @unallocated_space_mb) as 'data_size'
,       @log_size_mb as 'transaction_log_size'
,       cast(@unallocated_space_mb*100.0/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as  'unallocated'
,       cast(@reserved_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'reserved'
,       cast(@data_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'data'
,       cast(@index_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2)) as 'index_1'
,       cast(@unused_mb*100/(@reserved_mb + @unallocated_space_mb) as decimal(10,2))as 'unused';

end try 
begin catch 
select 
        1 as database_size_mb
,       ERROR_NUMBER() as reserved_mb
,       ERROR_SEVERITY() as unallocated_space_mb
,       ERROR_STATE() as data_size
,       1 as transaction_log_size
,       ERROR_MESSAGE() as unallocated
,       -100 as reserved
,       1 as data
,       1 as index_1
,       1 as unused 
end catch

*/