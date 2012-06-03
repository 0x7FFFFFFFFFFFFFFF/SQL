---------------------------------------------------------------------------------------
-- List Statements Execution Stats
---------------------------------------------------------------------------------------
SELECT 
	SUBSTRING(qt.text,stats.statement_start_offset/2, 
	 (case
		when stats.statement_end_offset = -1 then len(convert(nvarchar(max), qt.text)) * 2 
		else stats.statement_end_offset
	  end -stats.statement_start_offset)/2) 
	 as query_text
	,qt.dbid, dbname = db_name(qt.dbid)
	,qt.objectid

	,stats.execution_count

	,stats.min_worker_time
	,stats.total_worker_time / stats.execution_count as avg_worker_time 
	,stats.max_worker_time 
	,stats.total_worker_time

	,stats.min_elapsed_time
	,stats.total_elapsed_time / stats.execution_count as avg_elapsed_time 
	,stats.max_elapsed_time 
	,stats.total_elapsed_time

	,cast (100*stats.total_worker_time/stats.total_elapsed_time as numeric(20,1)) as [worker_elapsed_time_%]

	,stats.min_physical_reads
	,stats.total_physical_reads / stats.execution_count as avg_physical_reads 
	,stats.max_physical_reads 
	,stats.total_physical_reads

	,stats.min_logical_reads
	,stats.total_logical_reads / stats.execution_count as avg_logical_reads 
	,stats.max_logical_reads 
	,stats.total_logical_reads

	,case
		when stats.total_logical_reads = 0 then 0.00
		else cast(100*stats.total_physical_reads/stats.total_logical_reads as numeric(20,1))
	 end as [physical_logical_reads_%]

	,stats.min_logical_writes
	,stats.total_logical_writes / stats.execution_count as avg_logical_writes 
	,stats.max_logical_writes
	,stats.total_logical_writes
 from
	sys.dm_exec_query_stats stats
	cross apply sys.dm_exec_sql_text(stats.sql_handle) as qt
 where
--	dbname = ''
 order by
	 stats.execution_count desc
	,avg_worker_time desc
	,total_worker_time desc
	,avg_elapsed_time desc
	,total_elapsed_time desc
	,[worker_elapsed_time_%]
	,avg_physical_reads desc
	,total_physical_reads desc
	,avg_logical_reads desc
	,total_logical_writes desc
	,[physical_logical_reads_%] desc
	,avg_logical_writes desc

---------------------------------------------------------------------------------------
-- Determine Index Cost Benefits
--
-- Need to edit
--
---------------------------------------------------------------------------------------
use FXAPPLICATION
go
declare @dbid int
select @dbid = db_id('FXAPPLICATION')
/*select
	Object_schema_name(object_id) as [Schema],
	'object'		= object_name(object_id),
	index_id,
	'user reads'	= user_seeks + user_scans + user_lookups,
	'system reads'	= system_seeks + system_scans + system_lookups,
	'user writes'	= user_updates,
	'system writes'	= system_updates
 from sys.dm_db_index_usage_stats
 where
	objectproperty(object_id,'IsUserTable') = 1
	and database_id = @dbid
 order by
	'user reads' desc
*/
Select
	Object_schema_name(o.object_id) as [Schema],
	  'object'							= object_name(o.object_id), i.name
	, 'cost-ben'						= user_updates - (user_seeks + user_scans + user_lookups)
	, 'usage_reads'						= user_seeks + user_scans + user_lookups
	, 'operational_reads'				= range_scan_count + singleton_lookup_count
	--, range_scan_count
	--, singleton_lookup_count
	, 'usage writes'					= user_updates
	, 'operational_leaf_writes'			= leaf_insert_count+leaf_update_count+ leaf_delete_count 
--	, leaf_insert_count,leaf_update_count,leaf_delete_count 
	, 'operational_leaf_page_splits'	= leaf_allocation_count
	, 'operational_nonleaf_writes'		= nonleaf_insert_count + nonleaf_update_count + nonleaf_delete_count
	, 'operational_nonleaf_page_splits'	= nonleaf_allocation_count
	,'drop index ' + quotename(i.name) + ' on ' + quotename(object_schema_name(i.object_id)) + '.' + quotename(object_name(i.object_id))
 from
	sys.dm_db_index_operational_stats (db_id('FXAPPLICATION'),NULL,NULL,NULL) as o
	join sys.dm_db_index_usage_stats as u on u.object_id = o.object_id and u.index_id = o.index_id
	join sys.indexes as i on u.object_id = i.object_id and u.index_id = i.index_id
 where
	objectproperty(o.object_id,'IsUserTable') = 1
	and i.is_primary_key = 0
	and i.is_unique_constraint = 0
--	and object_id('U_PartnersUsers') = i.object_id
 order by
	Object,
	[cost-ben] desc, operational_reads desc, operational_leaf_writes, operational_nonleaf_writes
go


---------------------------------------------------------------------------------------
-- Unused Indexes
--
-- Need to edit
--
---------------------------------------------------------------------------------------
use FXAPPLICATION
go
declare @dbid int
select @dbid = db_id('FXAPPLICATION')
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
	stats.database_id = @dbid
	and objectproperty(indexes.object_id,'IsUserTable') = 1
	and last_user_seek is null 
	and last_user_scan is null 
	and last_user_lookup is null
	and indexes.is_primary_key = 0 and indexes.is_unique_constraint = 0
 order by [Schema], [table], [Index]
go

---------------------------------------------------------------------------------------
-- Query text and wait details by session ID
---------------------------------------------------------------------------------------
select
	transactions.transaction_type,
	Case
		when transactions.transaction_state = 0 then 'The transaction has not been completely initialized yet.'
		when transactions.transaction_state = 1 then 'The transaction has been initialized but has not started.' 
		when transactions.transaction_state = 2 then 'The transaction is active.'
		when transactions.transaction_state = 3 then 'The transaction has ended. This is used for read-only transactions.'
		when transactions.transaction_state = 4 then 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
		when transactions.transaction_state = 5 then 'The transaction is in a prepared state and waiting resolution.'
		when transactions.transaction_state = 6 then 'The transaction has been committed.'
		when transactions.transaction_state = 7 then 'The transaction is being rolled back.'
		when transactions.transaction_state = 8 then 'The transaction has been rolled back.'
		else 'Unknown State'
	 end as [State],
	requests.session_id, 
	requests.blocking_session_id, 
	requests.status,
	db_name(requests.database_id) as [Database],
	sessions.login_name as [User],
	USER_NAME(requests.USER_ID) as [Role],
	sessions.cpu_time,
	sessions.memory_usage ,
	sessions.reads,
	sessions.writes,
	requests.wait_type,
	requests.wait_time,
	requests.wait_resource,
	requests.wait_type,
	requests.command,
--	SUBSTRING(sql_text.text, requests.statement_start_offset, requests.statement_end_offset - requests.statement_start_offset),
	sql_text.text,
	requests.transaction_id
 from
	sys.dm_exec_requests requests
	inner join sys.dm_exec_sessions sessions on requests.session_id = sessions.session_id
	Inner Join sys.dm_tran_active_transactions as transactions on requests.transaction_id = transactions.transaction_id
	cross apply sys.dm_exec_sql_text(requests.sql_handle) sql_text
 where requests.database_id = DB_ID('FXAPPLICATION')
 order by requests.blocking_session_id desc, requests.session_id

select DB_ID('FXAPPLICATION')


--ALTER DATABASE [FXAPPLICATION] SET SAFETY OFF
go
--ALTER DATABASE [FXAPPLICATION] SET SAFETY FULL
GO
