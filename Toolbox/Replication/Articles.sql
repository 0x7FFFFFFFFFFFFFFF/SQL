-- Run against distribution DB

-- Articles by Publication
Select
	P.publisher_db as [Publisher DB],
	P.publication as [Publication],
	A.article as [Article],
	A.source_owner as [Schema],
	A.source_object as [Object]
 From distribution.dbo.MSarticles as A
 Inner Join distribution.dbo.MSpublications as P on A.publication_id = P.publication_id
 Where p.publication not in ('FXAPPLICATION_ReadOnly')
 Order by [Schema], [Object]

-- Articles by source object
Select
	P.publisher_db as [Publisher DB],
	P.publication as [Publication],
	A.article as [Article],
	A.source_owner as [Schema],
	A.source_object as [Object]
 From distribution.dbo.MSarticles as A
 Inner Join distribution.dbo.MSpublications as P on A.publication_id = P.publication_id
 Where A.source_object like '%deal%'

