Select
	A1.source_owner as [Schema],
	A1.source_object as [Object],
	P1.publisher_db as [Publisher DB],
	P1.publication as [Publication],
	A1.article as [Article]
 From distribution.dbo.MSarticles as A1
 Inner Join distribution.dbo.MSpublications as P1 on A1.publication_id = P1.publication_id
 Inner Join (
	Select
		A.source_owner,
		A.source_object
	 From distribution.dbo.MSarticles as A
	 Inner Join distribution.dbo.MSpublications as P on A.publication_id = P.publication_id
	 Where p.publication not in ('FXAPPLICATION_ReadOnly', 'InterfaceStaging_Reporting')
	 Group by A.source_owner, A.source_object
	 Having Count(A.source_owner) > 1
  ) as Dups on
		A1.source_owner = Dups.source_owner and
		A1.source_object = Dups.source_object
 Order by [Schema], [Object], [Publisher DB], [Publication]
