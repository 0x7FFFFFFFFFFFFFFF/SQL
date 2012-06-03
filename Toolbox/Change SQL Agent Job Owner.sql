USE [msdb]
Go

Select
	J.name as [Job],
	P.name as [Owner],
	'EXEC msdb.dbo.sp_update_job @job_id=N''' + Convert(varchar(50), J.job_id) + ''', @owner_login_name=N''sa'''
 From dbo.sysjobs as J
 Left Outer Join sys.server_principals as P on J.owner_sid = P.sid
 Where P.sid is null or P.name like '%Alex%'
