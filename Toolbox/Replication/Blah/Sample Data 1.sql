Use master
Go

If exists (Select * from sys.databases where name = 'TestPub')
 If exists (Select * from TestPub.sys.procedures where name = 'DropRepl' and schema_id = schema_id('sysmaint'))
  Exec TestPub.sysmaint.DropRepl
Go

If exists (select * from sys.databases where name = 'TestPub')
 Drop database TestPub
If exists (select * from sys.databases where name = 'TestSub')
 Drop database TestSub
Go

Create database TestPub
Create database TestSub
Go

Use TestPub
Go

Create table dbo.TestArticle1 (
	PK int not null identity(1,1) primary key,
	C1 varchar(10)
 )
Go

Use master
