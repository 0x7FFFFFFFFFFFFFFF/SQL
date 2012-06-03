Use TestPub
Go

Delete from sysmaint.ReplDistributionEnvironment
Delete from sysmaint.ReplSubscriptionEnvironment
Delete from sysmaint.ReplPublicationEnvironment
Delete from sysmaint.ReplDistribution
Delete from sysmaint.ReplEnvironment
Delete from sysmaint.ReplArticle
Delete from sysmaint.ReplSubscribtion
Delete from sysmaint.ReplPublication

Declare
	@ReplDistributionID tinyint,
	@ReplEnvironmentID tinyint,
	@ReplPublicationID tinyint,
	@ReplPublicationEnvironmentID tinyint,
	@ReplArticleID smallint,
	@ReplSubscribtionID tinyint

Insert into sysmaint.ReplEnvironment (Name, ServerName, SnapShotJobLogin, SnapShotJobPassword, LogReaderJobLogin, LogReaderJobPassword)
 Values ('Production', @@SERVERNAME, @@SERVERNAME + '\Administrator', 'Password123', @@SERVERNAME + '\Administrator', 'Password123')
Set @ReplEnvironmentID = scope_identity()

Insert into sysmaint.ReplDistribution (
	distributor,
	heartbeat_interval,
	distributor_admin_password,
	DBName,
	data_folder,
	data_file,
	data_file_size,
	log_folder,
	log_file,
	log_file_size,
	--min_distretention,
	--max_distretention,
	--history_retention,
	security_mode,
	login,
	password)
 Values (
	@@servername, -- distributor
	10, -- heartbeat_interval
	'Password123', -- distributor_admin_password
	'distribution', -- DBName
	NULL, -- data_folder
	NULL, -- data_file
	NULL, -- data_file_size
	NULL, -- log_folder
	NULL, -- log_file
	NULL, -- log_file_size
	--NULL, -- min_distretention
	--NULL, -- max_distretention
	--NULL, -- history_retention
	NULL, -- security_mode
	'\Administrator', -- login
	'Password123') -- password
Set @ReplDistributionID = scope_identity()

Insert into sysmaint.ReplDistributionEnvironment (ReplDistributionID, ReplEnvironmentID) values (@ReplDistributionID, @ReplEnvironmentID)

Insert into sysmaint.ReplPublication (Name, DBName, CompressSnapshot) values ('Blah', 'TestPub', 1)
Set @ReplPublicationID = scope_identity()

Insert into sysmaint.ReplArticle (ReplPublicationID, ObjectID, Name) values (@ReplPublicationID, object_id('dbo.TestArticle1'), 'B')
Set @ReplArticleID = scope_identity()

Insert into sysmaint.ReplPublicationEnvironment (ReplEnvironmentID, ReplPublicationID) values (@ReplEnvironmentID, @ReplPublicationID)
Set @ReplPublicationEnvironmentID = scope_identity()

Insert into sysmaint.ReplSubscribtion (Name) values ('Blah')
Set @ReplSubscribtionID = scope_identity()

Insert into sysmaint.ReplSubscriptionEnvironment (
	ReplEnvironmentID,
	ReplSubscribtionID,
	ServerName,
	DatabaseName,
	DistributorJobLogin,
	DistributorJobPassword,
	SubscriberLogin,
	SubscriberPassword)
 values (
	@ReplEnvironmentID,
	@ReplSubscribtionID,
	@@SERVERNAME,
	'TestSub',
	@@SERVERNAME + '\Administrator',
	'Password123',
	@@SERVERNAME + '\Administrator',
	'Password123')

Select
	object_schema_name(A.ObjectID) as [Schema],
	object_name(A.ObjectID) as [Object],
	A.Name as [Article],
	P.Name as [Publication],
	E.Name as [Eviroment]
 From sysmaint.ReplArticle as A
 Inner Join sysmaint.ReplPublication as P on A.ReplPublicationID = P.ReplPublicationID
 Inner Join sysmaint.ReplSubscribtion as S on P.ReplPublicationID = S.ReplSubscribtionID
 Inner Join sysmaint.ReplSubscriptionEnvironment as SE on S.ReplSubscribtionID = SE.ReplSubscribtionID
 Inner Join sysmaint.ReplPublicationEnvironment as PE on P.ReplPublicationID = PE.ReplPublicationID
 Inner Join sysmaint.ReplEnvironment as E on PE.ReplEnvironmentID = E.ReplEnvironmentID
Go

--Exec sysmaint.ReplCreateDistribution
Exec sysmaint.CreateRepl
--Exec sysmaint.ReplCreatePublications
--Exec sysmaint.ReplCreateArticles
--Exec sysmaint.ReplCreateSubscriptions
Exec sysmaint.ReplRunSnapshot
Go

Use master
