Select
	D.name as [Database],
	P.name as [Owner],
	'EXEC [' + D.name + '].dbo.sp_changedbowner @loginame = N''sa'', @map = false'
 From sys.databases as D
 Left Outer Join sys.server_principals as P on D.owner_sid = P.sid
 Where P.sid is null or p.name like '%alex%'
