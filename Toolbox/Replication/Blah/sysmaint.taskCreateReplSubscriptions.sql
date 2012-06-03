Alter procedure sysmaint.ReplCreateSubscriptions
 as
 Begin
 
	--------------------------------------------------------------
	-- Init variables
	--------------------------------------------------------------
 	Declare
		@dbname nvarchar(128),
		@SnapShotJobLogin nvarchar(257),
		@SnapShotJobPassword sysname,
		@LogReaderJobLogin nvarchar(257),
		@LogReaderJobPassword sysname,
		@ReplEnvironmentID tinyint
	Set @dbname = db_name()

	Select
		@SnapShotJobLogin = SnapShotJobLogin,
		@SnapShotJobPassword = SnapShotJobPassword,
		@LogReaderJobLogin = LogReaderJobLogin,
		@LogReaderJobPassword = LogReaderJobPassword,
		@ReplEnvironmentID = ReplEnvironmentID
	 From sysmaint.ReplEnvironment
	 Where ServerName = @@SERVERNAME

	--------------------------------------------------------------
	-- Setup Subscriptions
	--------------------------------------------------------------
	Declare @publication sysname, @subscriber sysname, @destination_db sysname, @job_login nvarchar(257),
		    @job_password sysname, @subscriber_login sysname, @subscriber_password sysname
	Declare sub cursor for
	Select
		P.Name as publication,
		SE.ServerName as subscriber,
		SE.DatabaseName as destination_db,
		SE.DistributorJobLogin as job_login,
		SE.DistributorJobPassword as job_password,
		SE.SubscriberLogin as subscriber_login,
		SE.SubscriberPassword as subscriber_password
	 From sysmaint.ReplPublication as P
	 Inner Join sysmaint.ReplSubscribtion as S on P.ReplPublicationID = S.ReplSubscribtionID
	 Inner Join sysmaint.ReplSubscriptionEnvironment as SE on S.ReplSubscribtionID = SE.ReplSubscribtionID
	 Left Outer Join (
		Select P.publication, S.subscriber_db
		 From distribution.dbo.MSpublications as P
		 Inner Join distribution.dbo.MSsubscriptions as S on P.publication_id = S.publication_id
		 Group by P.publication, S.subscriber_db
	  ) as ExistingSubs on P.Name = ExistingSubs.publication and SE.DatabaseName = ExistingSubs.subscriber_db
	 Where
		ExistingSubs.publication is null and
		SE.ReplEnvironmentID = @ReplEnvironmentID

	Open sub

	Fetch next from sub into @publication, @subscriber, @destination_db, @job_login, @job_password, @subscriber_login, @subscriber_password
	
	While @@FETCH_STATUS = 0
	 Begin

		exec sp_addsubscription
			@publication = @publication,
			@subscriber = @subscriber,
			@destination_db = @destination_db,
			@subscription_type = N'Push',
			@sync_type = N'automatic',
			@article = N'all',
			@update_mode = N'read only',
			@subscriber_type = 0
		
		Select
			@publication,
			@subscriber,
			@destination_db,
			@job_login,
			@job_password,
			@subscriber_login,
			@subscriber_password
		
		exec sp_addpushsubscription_agent
			@publication = @publication,
			@subscriber = @subscriber,
			@subscriber_db = @destination_db,
			@job_login = @job_login,
			@job_password = @job_password,
			@subscriber_security_mode = 0,
			@subscriber_login = @subscriber_login,
			@subscriber_password = @subscriber_password,
			@frequency_type = 64,
			@frequency_interval = 0,
			@frequency_relative_interval = 0,
			@frequency_recurrence_factor = 0,
			@frequency_subday = 0,
			@frequency_subday_interval = 0,
			@active_start_time_of_day = 0,
			@active_end_time_of_day = 235959,
			@active_start_date = 20110801,
			@active_end_date = 99991231,
			@enabled_for_syncmgr = N'False',
			@dts_package_location = N'Distributor'
	
		Fetch next from sub into @publication, @subscriber, @destination_db, @job_login, @job_password, @subscriber_login, @subscriber_password
	 End

	Close sub
	Deallocate sub

End
Go

--Exec sysmaint.ReplCreateSubscriptions