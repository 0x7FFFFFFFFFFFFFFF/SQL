
select *
 From sys.foreign_key_columns as FKC
 Left Outer Join (
	Select IC.object_id, IC.column_id
	 From sys.index_columns as IC
	 Inner Join (
		Select object_id, index_id 
		 From sys.index_columns
		 Group by object_id, index_id
		 Having Count(object_id) = 1
	  ) as SingleColumnIndex on IC.object_id = SingleColumnIndex.object_id and IC.index_id = SingleColumnIndex.index_id
 ) as IndexedColumn on FKC.referenced_object_id = IndexedColumn.object_id and FKC.referenced_column_id = IndexedColumn.column_id


select *
 From sys.foreign_key_columns as FKC
 Left Outer Join sys.index_columns as IC on
	FKC.parent_object_id = IC.object_id and
	FKC.parent_column_id = IC.column_id and
	IC.index_column_id = 1
 Where IC.object_id is null -- no index found


select *
 From sys.foreign_key_columns as FKC
 Left Outer Join sys.index_columns as IC on
	FKC.referenced_object_id = IC.object_id and
	FKC.referenced_column_id = IC.column_id and
	IC.index_column_id = 1
 Where IC.object_id is null -- no index found
