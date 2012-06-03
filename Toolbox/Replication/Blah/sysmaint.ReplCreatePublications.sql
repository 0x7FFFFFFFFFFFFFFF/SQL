Alter procedure sysmaint.ReplCreatePublications
 as
 Begin

	--------------------------------------------------------------
	-- Init variables
	--------------------------------------------------------------
 	Declare
		@SnapShotJobLogin nvarchar(257),
		@SnapShotJobPassword sysname,
		@LogReaderJobLogin nvarchar(257),
		@LogReaderJobPassword sysname,
		@ReplEnvironmentID tinyint

	Select
		@SnapShotJobLogin = SnapShotJobLogin,
		@SnapShotJobPassword = SnapShotJobPassword,
		@LogReaderJobLogin = LogReaderJobLogin,
		@LogReaderJobPassword = LogReaderJobPassword,
		@ReplEnvironmentID = ReplEnvironmentID
	 From sysmaint.ReplEnvironment
	 Where ServerName = @@SERVERNAME
 
	--------------------------------------------------------------
	-- Setup Publications
	--------------------------------------------------------------
	Declare
		@ReplPublicationID tinyint,
		@publication sysname,
		@dbname sysname,
		@compress_snapshot nvarchar(5)
	Declare pub cursor for
	 Select
		Pub.ReplPublicationID,
		Pub.Name,
		Pub.DBName,
		Case when Pub.CompressSnapshot = 1 then 'true' else 'false' end
	  From sysmaint.ReplPublication as Pub
	  Inner Join sysmaint.ReplPublicationEnvironment as PubEnv on Pub.ReplPublicationID = PubEnv.ReplPublicationID
	  Where PubEnv.ReplEnvironmentID = @ReplEnvironmentID

	Open pub

	Fetch next from pub into @ReplPublicationID, @publication, @dbname, @compress_snapshot

	While @@FETCH_STATUS = 0
	 Begin
		If not exists (Select * from sys.databases where name = 'distribution') --or
			--not exists (Select * from distribution.dbo.MSpublications where publication = @publication)
		 Begin
			 exec sp_addpublication -- create publication
				@publication = @publication,
				@sync_method = N'concurrent',
				@retention = 0,
				@allow_push = N'true',
				@allow_pull = N'true',
				@allow_anonymous = N'true',
				@enabled_for_internet = N'false',
				@snapshot_in_defaultfolder = N'true',
				@compress_snapshot = N'false',
				@ftp_port = 21,
				@ftp_login = N'anonymous',
				@allow_subscription_copy = N'false',
				@add_to_active_directory = N'false',
				@repl_freq = N'continuous',
				@status = N'active',
				@independent_agent = N'true',
				@immediate_sync = N'true',
				@allow_sync_tran = N'false',
				@autogen_sync_procs = N'false',
				@allow_queued_tran = N'false',
				@allow_dts = N'false',
				@replicate_ddl = 1,
				@allow_initialize_from_backup = N'false',
				@enabled_for_p2p = N'false',
				@enabled_for_het_sub = N'false'	

			exec sp_addpublication_snapshot
				@publication = @publication,
				@frequency_type = 1,
				@frequency_interval = 0,
				@frequency_relative_interval = 0,
				@frequency_recurrence_factor = 0,
				@frequency_subday = 0,
				@frequency_subday_interval = 0,
				@active_start_time_of_day = 0,
				@active_end_time_of_day = 235959,
				@active_start_date = 0,
				@active_end_date = 0,
				@job_login = @SnapShotJobLogin,
				@job_password = @LogReaderJobPassword,
				@publisher_security_mode = 1
		 End

		Fetch next from pub into @ReplPublicationID, @publication
	 End

	Close pub
	Deallocate pub

End
Go
