Use [distribution]
Go

exec sys.sp_replmonitorhelppublisher @publisher = 'OZFDB01'
exec sys.sp_replmonitorhelppublication @publisher = 'OZFDB01'
exec sys.sp_replmonitorhelpsubscription @publisher = 'OZFDB01', @publication_type = 0

