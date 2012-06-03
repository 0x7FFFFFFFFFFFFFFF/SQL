If object_id('Data.dm_os_wait_stats') is not null drop table Data.dm_os_wait_stats
If object_id('Data.wait_types') is not null drop table Data.wait_types
Go

Create table Data.wait_types (
	wait_type_id tinyint not null identity(1,1)
	 Constraint [PK_Data.wait_types] primary key nonclustered,
	wait_type nvarchar(60) not null
	 Constraint [UQ_Data.wait_types.wait_type] unique clustered)

Create table Data.dm_os_wait_stats (
	timestamp datetime2(0) not null,
	wait_type_id tinyint not null
	 Constraint [FK_Data.dm_os_wait_stats.wait_type_id] references Data.wait_types(wait_type_id),
	waiting_tasks_count bigint not null,
	wait_time_ms bigint not null,
	max_wait_time_ms bigint not null,
	signal_wait_time_ms bigint not null)
Go

If object_id('Collector.dm_os_wait_stats') is not null Drop procedure Collector.dm_os_wait_stats
Go

Create procedure Collector.dm_os_wait_stats as
 Begin
	Declare @Data table (
		timestamp datetime2(0) not null default (sysutcdatetime()),
		wait_type nvarchar(60),
		waiting_tasks_count bigint,
		wait_time_ms bigint,
		max_wait_time_ms bigint,
		signal_wait_time_ms bigint)
 
	Insert into @Data (
		timestamp,
		wait_type,
		waiting_tasks_count,
		wait_time_ms,
		max_wait_time_ms,
		signal_wait_time_ms)
	 Select
		sysutcdatetime(),
		wait_type,
		waiting_tasks_count,
		wait_time_ms,
		max_wait_time_ms,
		signal_wait_time_ms
	  From sys.dm_os_wait_stats
	
	Insert into Data.wait_types (wait_type)
	 Select distinct Src.wait_type
	  From @Data as Src
	  Left Outer Join Data.wait_types as Dst on Src.wait_type = Dst.wait_type
	
	Insert into Data.dm_os_wait_stats (
		timestamp,
		wait_type_id,
		waiting_tasks_count,
		wait_time_ms,
		max_wait_time_ms,
		signal_wait_time_ms)
	 Select
		Src.timestamp,
		wait_types.wait_type_id,
		Src.waiting_tasks_count,
		Src.wait_time_ms,
		Src.max_wait_time_ms,
		Src.signal_wait_time_ms
	  From @Data as Src
	  Inner Join Data.wait_types as wait_types on Src.wait_type = wait_types.wait_type

 End
Go
