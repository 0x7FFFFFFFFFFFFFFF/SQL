/*
Create schema Collector
Create schema Data
Create schema Control
*/

If object_id('Control.Metric') is not null drop table Control.Metric
If object_id('Control.MetricGroup') is not null drop table Control.MetricGroup
If object_id('Control.MetricObject') is not null drop table Control.MetricObject
Go

Create table Control.MetricGroup (
   MetricGroupID tinyint not null identity(1, 1)
	 Constraint [PK_Control.MetricGroup] primary key,
	Name varchar(100) not null
	 Constraint [UQ_Control.MetricGroup.MetricGroupName] unique,
	MetricGroupName as Name)

Create table Control.MetricObject (
	MetricObjectID tinyint not null identity(1,1)
	 Constraint [PK_Control.MetricObject] primary key,
	[Schema] sysname not null
	 Constraint [UQ_Control.MetricObject.Schema] unique,
	Name sysname not null
	 Constraint [UQ_Control.MetricObject.Name] unique,
	Fullname as quotename([Schema]) + '.' + quotename(Name)
 )

Create table Control.Metric (
   MetricID smallint not null identity(1, 1)
	 Constraint [PK_Control.Metric] primary key,
	MetricGroupID tinyint not null
	 Constraint [FK_Control.Metric.MetricGroupID] references Control.MetricGroup (MetricGroupID),
	SrcMetricObjectID tinyint not null
	 Constraint [FK_Control.Metric.SrcMetricObjectID] references Control.MetricObject(MetricObjectID),
	SrcColumnName sysname,
	DstMetricObjectID tinyint not null
	 Constraint [FK_Control.Metric.DstMetricObjectID] references Control.MetricObject(MetricObjectID),
	DstColumnName sysname,
	Type sysname not null,
	TypeLength smallint not null,
	TypePrecision tinyint not null)
Go

Insert into Control.MetricGroup (Name) values ('OS')

Insert into Control.MetricObject ([Schema], Name) Values ('sys', 'dm_os_wait_stats')
Insert into Control.MetricObject ([Schema], Name) Values ('Data', 'dm_os_wait_stats')
Go

Declare @MetricGroupID tinyint, @SrcMetricObjectID tinyint, @DstMetricObjectID tinyint
Select @MetricGroupID = MetricGroupID from Control.MetricGroup where Name = 'OS'
Select @SrcMetricObjectID = MetricObjectID from Control.MetricObject where [Schema] = 'sys' and Name = 'dm_os_wait_stats'
Select @DstMetricObjectID = MetricObjectID from Control.MetricObject where [Schema] = 'Data' and Name = 'dm_os_wait_stats'

Insert into Control.Metric (
	MetricGroupID,
	SrcMetricObjectID,
	SrcColumnName,
	DstMetricObjectID,
	DstColumnName,
	Type,
	TypeLength,
	TypePrecision)
Values (
	@MetricGroupID, -- MetricGroupID - tinyint
	@SrcMetricObjectID, -- SrcMetricObjectID - tinyint
	'wait_type', -- SrcColumnName - sysname
	@DstMetricObjectID, -- DstMetricObjectID - tinyint
	'wait_type', -- DstColumnName - sysname
	'', -- Type - sysname
	0, -- TypeLength - smallint
	0)  -- TypePrecision - tinyint

Insert into Control.Metric (
	MetricGroupID,
	SrcMetricObjectID,
	SrcColumnName,
	DstMetricObjectID,
	DstColumnName,
	Type,
	TypeLength,
	TypePrecision)
Values (
	@MetricGroupID, -- MetricGroupID - tinyint
	@SrcMetricObjectID, -- SrcMetricObjectID - tinyint
	'', -- SrcColumnName - sysname
	@DstMetricObjectID, -- DstMetricObjectID - tinyint
	'', -- DstColumnName - sysname
	'', -- Type - sysname
	0, -- TypeLength - smallint
	0)  -- TypePrecision - tinyint

Insert into Control.Metric (
	MetricGroupID,
	SrcMetricObjectID,
	SrcColumnName,
	DstMetricObjectID,
	DstColumnName,
	Type,
	TypeLength,
	TypePrecision)
Values (
	@MetricGroupID, -- MetricGroupID - tinyint
	@SrcMetricObjectID, -- SrcMetricObjectID - tinyint
	'', -- SrcColumnName - sysname
	@DstMetricObjectID, -- DstMetricObjectID - tinyint
	'', -- DstColumnName - sysname
	'', -- Type - sysname
	0, -- TypeLength - smallint
	0)  -- TypePrecision - tinyint

Insert into Control.Metric (
	MetricGroupID,
	SrcMetricObjectID,
	SrcColumnName,
	DstMetricObjectID,
	DstColumnName,
	Type,
	TypeLength,
	TypePrecision)
Values (
	@MetricGroupID, -- MetricGroupID - tinyint
	@SrcMetricObjectID, -- SrcMetricObjectID - tinyint
	'', -- SrcColumnName - sysname
	@DstMetricObjectID, -- DstMetricObjectID - tinyint
	'', -- DstColumnName - sysname
	'', -- Type - sysname
	0, -- TypeLength - smallint
	0)  -- TypePrecision - tinyint




wait_type 
 nvarchar(60) 
 Name of the wait type. 
 
waiting_tasks_count 
 bigint 
 Number of waits on this wait type. This counter is incremented at the start of each wait. 
 
wait_time_ms 
 bigint 
 Total wait time for this wait type in milliseconds. This time is inclusive of signal_wait_time_ms. 
 
max_wait_time_ms 
 bigint 
 Maximum wait time on this wait type.
 
signal_wait_time_ms 
 bigint 
 

