Create procedure sysmaint.ReplCreateArticles
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
	-- Setup Articles
	--------------------------------------------------------------
	Declare
		@publication sysname, @article sysname, @source_owner sysname, @source_object sysname,
		@type sysname, @ins_cmd varchar(255), @del_cmd  varchar(255), @upd_cmd  varchar(255),
		@pre_creation_cmd nvarchar(10), @schema_option binary(8)
	Declare art cursor for
	 Select
		Pub.Name,
		Src.Name,
		object_schema_name(Src.ObjectID) as source_owner,
		object_name(Src.ObjectID) as source_object,
		Case
			When O.type = 'U' then 'logbased' -- User table
			When O.type = 'V' and Indexed.object_id is null then 'view schema only' -- non-indexed view
			When O.type = 'V' and Indexed.object_id is not null then 'indexed view logbased' -- indexed view
			When O.type = 'FN' then 'func schema only' -- SQL scalar function
			When O.type = 'TF' then 'func schema only' -- SQL table-valued-function
			When O.type = 'P' then 'proc schema only' -- SQL Stored Procedure
			else 'logbased'
		 End as Type,
		Case
			When O.type = 'U' then 'delete' -- User table
			When O.type = 'V' and Indexed.object_id is null then 'drop' -- non-indexed view
			When O.type = 'V' and Indexed.object_id is not null then 'drop' -- indexed view
			When O.type = 'FN' then 'drop' -- SQL scalar function
			When O.type = 'TF' then 'drop' -- SQL table-valued-function
			When O.type = 'P' then 'drop' -- SQL Stored Procedure
			else 'logbased'
		 End as PreCreationCmd,
		Convert(binary(8), Case
			When O.type = 'U' then 0x000000000803509F -- User table
			When O.type = 'V' and Indexed.object_id is null then 0x0000000008000001 -- non-indexed view
			When O.type = 'V' and Indexed.object_id is not null then 0x0000000008000001 -- indexed view
			When O.type = 'FN' then 0x0000000008000001 -- SQL scalar function
			When O.type = 'TF' then 0x0000000008000001 -- SQL table-valued-function
			When O.type = 'P' then 0x0000000008000001 -- SQL Stored Procedure
			else 'logbased'
		 End) as SchemaOption
	  From sysmaint.ReplArticle as Src
	  Inner Join sysmaint.ReplPublication as Pub on Src.ReplPublicationID = Pub.ReplPublicationID
	  Inner Join sys.objects as O on Src.ObjectID = O.object_id
	  Left Outer Join (
		Select distinct object_id
		 From sys.indexes
	   ) as Indexed on O.object_id = Indexed.object_id
	  Left Outer Join dbo.sysarticles as AlreadyCreated on Src.ObjectID = AlreadyCreated.objid
	  Where AlreadyCreated.objid is null

	Open art

	Fetch next from art into @publication, @article, @source_owner, @source_object, @type, @pre_creation_cmd, @schema_option
	
	While @@FETCH_STATUS = 0
	 Begin
		If not exists (
			Select *
			 From distribution.dbo.MSarticles as A
			 Inner Join distribution.dbo.MSpublications as P on A.publication_id = P.publication_id
			 Where P.publication = @publication and A.source_owner = @source_owner and A.source_object = @source_object
		 )
		 Begin
			Select
				@ins_cmd = N'CALL sp_MSins_' + @source_owner + @source_object,
				@del_cmd = N'CALL sp_MSdel_' + @source_owner + @source_object,
				@upd_cmd = N'SCALL sp_MSupd_' + @source_owner + @source_object

			Print @publication + ': ' + @source_owner + '.' + @source_object
			exec sp_addarticle
				@publication = @publication,
				@article = @article,
				@source_owner = @source_owner,
				@source_object = @source_object,
				@type = @type,
				@description = null,
				@creation_script = null,
				@pre_creation_cmd = @pre_creation_cmd,
				@schema_option = @schema_option,
				@identityrangemanagementoption = N'manual',
				@destination_table = @source_object,
				@destination_owner = @source_owner,
				@vertical_partition = N'false',
				@force_invalidate_snapshot = 1,
				@ins_cmd = @ins_cmd,
				@del_cmd = @del_cmd,
				@upd_cmd = @upd_cmd
		 End

		Fetch next from art into @publication, @article, @source_owner, @source_object, @type, @pre_creation_cmd, @schema_option
	 End

	Close art
	Deallocate art

End
Go

--Exec sysmaint.taskCreateReplArticles
