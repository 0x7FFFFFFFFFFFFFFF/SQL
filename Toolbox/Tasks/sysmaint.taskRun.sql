Alter procedure sysmaint.taskRun
	@Schedule varchar(50)

 as
	Declare @err_msg varchar(1000)
	Set @err_msg = 'sysmaint.taskRun: '
	
	If not exists(select * from sysmaint.TaskExecSchedule where [Name] = @Schedule)
	 Begin
		Set @err_msg = @err_msg + 'Schedule ''' + @Schedule + ''' not found'
		RAISERROR (@err_msg, 16, 1)
		Print @err_msg
		Return -1
	 End
	
	Declare @sql varchar(1000)
	
	Declare task cursor for
	 Select Task.StoredProc
	  From sysmaint.TaskExecSchedule as ExecSchedule
	  Inner Join sysmaint.Task as Task on ExecSchedule.TaskExecScheduleID = Task.TaskExecScheduleID
	  Inner Join sysmaint.EnvironmentTask as EnvTask on Task.TaskID = EnvTask.TaskID
	  Inner Join sysmaint.Environment as Env on EnvTask.EnvironmentID = Env.EnvironmentID
	  Where
		ExecSchedule.[Name] = @Schedule and
		Env.ServerName = @@servername and
		Env.DatabaseName = DB_Name() and
		Task.Run = 1
	
	Open task
	Fetch next from task into @sql
	
	While @@FETCH_STATUS = 0
	 Begin
		Begin transaction
		
		Print @sql
		Exec (@sql)

		If @@Trancount > 0 and @@ERROR > 0
		 Begin
			Rollback
			Set @err_msg = @err_msg + 'Problem executing ''' + @Schedule
			RAISERROR (@err_msg, 16, 1)
			Return
		 End
		
		If @@Trancount > 0 commit transaction
		
		Fetch next from task into @sql
	 End
	
	Close task
	Deallocate task
go