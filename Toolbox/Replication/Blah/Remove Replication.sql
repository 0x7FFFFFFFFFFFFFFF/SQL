If schema_id('sysmaint') is null Exec ('create schema sysmaint')
Go

If object_id('sysmaint.ReplSubscriptionEnvironment') is not null drop table sysmaint.ReplSubscriptionEnvironment
If object_id('sysmaint.ReplSubscribtion') is not null drop table sysmaint.ReplSubscribtion
If object_id('sysmaint.ReplPublicationEnvironment') is not null drop table sysmaint.ReplPublicationEnvironment
If object_id('sysmaint.ReplEnvironment') is not null drop table sysmaint.ReplEnvironment
If object_id('sysmaint.ReplArticle') is not null drop table sysmaint.ReplArticle
If object_id('sysmaint.ReplPublication') is not null drop table sysmaint.ReplPublication
Go

Create table sysmaint.ReplPublication (
	ReplPublicationID tinyint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplPublication] primary key,
	Name varchar(255) not null
	 Constraint [UQ_sysmaint.ReplPublication.Name] unique,
	DBName sysname,
	CompressSnapshot bit not null
	 Constraint [DF_sysmaint.ReplPublication.CompressSnapshot] default (0)
)

Create table sysmaint.ReplArticle (
	ReplArticleID smallint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplArticle] primary key,
	ReplPublicationID tinyint not null
	 Constraint [FK_sysmaint.ReplArticle.ReplPublicationID] references sysmaint.ReplPublication(ReplPublicationID),
	Name varchar(50) not null,
	ObjectID int not null,
	Constraint [UQ_sysmaint.ReplArticle-ReplPublicationID__Name] unique (ReplPublicationID, Name),
	Constraint [UQ_sysmaint.ReplArticle-ReplPublicationID__ObjectID] unique (ReplPublicationID, ObjectID),
 )

Create table sysmaint.ReplEnvironment (
	ReplEnvironmentID tinyint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplEnvironment] primary key,
	Name varchar(50) not null
	 Constraint [UQ_sysmaint.ReplEnvironment.Name] unique,
	ServerName nvarchar(128) not null
	 Constraint [UQ_sysmaint.ReplEnvironment.ServerName] unique,
	SnapShotJobLogin nvarchar(257) not null,
	SnapShotJobPassword nvarchar(128) null,
	LogReaderJobLogin nvarchar(257) not null,
	LogReaderJobPassword nvarchar(128) null
 )

Create table sysmaint.ReplPublicationEnvironment (
	ReplPublicationEnvironmentID tinyint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplPublicationEnvironment] primary key nonclustered,
	ReplPublicationID tinyint not null
	 Constraint [FK_sysmaint.ReplPublicationEnvironment.ReplPublicationID] references sysmaint.ReplPublication(ReplPublicationID),
	ReplEnvironmentID tinyint not null
	 Constraint [FK_sysmaint.ReplPublicationEnvironment.ReplEnvironmentID] references sysmaint.ReplEnvironment(ReplEnvironmentID),
	Constraint [UQ_sysmaint.ReplPublicationEnvironment-ReplPublicationID__ReplEnvironmentID] unique clustered (ReplPublicationID, ReplEnvironmentID),
 )

Create table sysmaint.ReplSubscribtion (
	ReplSubscribtionID tinyint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplSubscribtion] primary key,
	Name varchar(20) null
	 Constraint [UQ_sysmaint.ReplSubscribtion.Name] unique
 )

Create table sysmaint.ReplSubscriptionEnvironment (
	ReplSubscriptionEnvironmentID tinyint not null identity(1, 1)
	 Constraint [PK_sysmaint.ReplSubscriptionEnvironment] primary key nonclustered,
	ReplEnvironmentID tinyint not null
	 Constraint [FK_sysmaint.ReplSubscriptionEnvironment.ReplEnvironmentID] references sysmaint.ReplEnvironment(ReplEnvironmentID),
	ReplSubscribtionID tinyint not null
	 Constraint [FK_sysmaint.ReplSubscriptionEnvironment.ReplSubscribtionID] references sysmaint.ReplSubscribtion(ReplSubscribtionID),
	Constraint [UQ_sysmaint.ReplSubscriptionEnvironment-ReplEnvironmentID__ReplSubscribtionID] unique clustered (ReplEnvironmentID, ReplSubscribtionID),

	ServerName nvarchar(128) not null,
	DatabaseName varchar(128) not null,

	DistributorJobLogin nvarchar(257) not null,
	DistributorJobPassword nvarchar(128) null,
	SubscriberLogin nvarchar(257) not null,
	SubscriberPassword nvarchar(128) null
 )
Go


/*

Create table sysmaint.ReplSPFailover
(
SPName sys.sysname not null,
Timeout smallint not null,
Abort bit not null
) ON PRIMARY
GO
ALTER TABLE sysmaint.ReplSPFailover ADD Constraint [CK_sysmaint.ReplSPFailover.Timeout CHECK ((Timeout>(0)))
GO
ALTER TABLE sysmaint.ReplSPFailover ADD Constraint [UQ_sysmaint.ReplSPFailover.SPName] unique CLUSTERED  (SPName) ON PRIMARY
GO




Create table sysmaint.ReplSubscribtionEnvironment
(
ReplSubscriberEnvironmentID tinyint not null identity(1, 1),
ReplSubscriberID tinyint not null,
EnvironmentID tinyint not null,
Subscriber sys.sysname not null,
SubscriberDB sys.sysname not null,
JobLogin nvarchar(257) not null,
JobPassword nvarchar(128) null,
SubscriberLogin sys.sysname not null,
SubscriberPassword nvarchar(128) null
) ON PRIMARY
GO
ALTER TABLE sysmaint.ReplSubscriberEnvironment ADD Constraint [PK_sysmaint.ReplSubscriberEnvironment] primary key NONCLUSTERED  (ReplSubscriberEnvironmentID) ON PRIMARY
GO
ALTER TABLE sysmaint.ReplSubscriberEnvironment ADD Constraint [UQ_sysmaint.ReplSubscriberEnvironment-ReplSubscriberID__EnvironmentID] unique CLUSTERED  (ReplSubscriberID, EnvironmentID) ON PRIMARY
GO
ALTER TABLE sysmaint.ReplSubscriberEnvironment ADD Constraint [FK_sysmaint.ReplSubscriberEnvironment.EnvironmentID] foreign key (EnvironmentID) REFERENCES sysmaint.Environment (EnvironmentID)
GO
ALTER TABLE sysmaint.ReplSubscriberEnvironment ADD Constraint [FK_sysmaint.ReplSubscriberEnvironment.ReplSubscriberID] foreign key (ReplSubscriberID) REFERENCES sysmaint.ReplSubscriber (ReplSubscriberID)
GO
*/