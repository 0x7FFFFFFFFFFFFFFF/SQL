Create procedure sysmaint.ReplUpdatePublicationsArticles
 as
 Begin

	Insert into sysmaint.ReplPublication (Name)
	Select Src.name
	 From dbo.syspublications as Src
	 Left Outer Join sysmaint.ReplPublication as Dst on Src.name = Dst.Name
	 Where Dst.Name is null

	Insert into sysmaint.ReplArticle (ReplPublicationID, ObjectID)
	Select DstPublication.ReplPublicationID, Src.objid
	 From dbo.sysarticles as Src
	 Inner Join dbo.syspublications as SrcPublications on Src.pubid = SrcPublications.pubid
	 Inner Join sysmaint.ReplPublication as DstPublication on SrcPublications.name = DstPublication.Name
	 left Outer Join sysmaint.ReplArticle as Dst on DstPublication.ReplPublicationID = Dst.ReplPublicationID and Src.objid = Dst.ObjectID
	 Where Dst.ReplPublicationID is null
 End
Go
