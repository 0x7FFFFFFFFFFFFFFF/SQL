/*

Finds all indexes that are overlapped by onther index.
Index A is overlapped by index B when the set set of keys for A
are wholly containted in the set of keys for B.

*/

Select
	object_schema_name(I.object_id) as [Schema],
	object_name(I.object_id) as [Object],
	I.name as [Index],
	I.object_id,
	'drop index ' + quotename(I.name) + ' on ' + quotename(object_schema_name(I.object_id)) + '.' + quotename(object_name(I.object_id))
 From sys.indexes as I
 Inner Join (
	Select object_id, index_id, Count(object_id) as Columns
	 From sys.index_columns
	 Group by object_id, index_id
  ) as IndexSummary on I.object_id = IndexSummary.object_id and I.index_id = IndexSummary.index_id
 Inner Join (
	Select A.object_id, A.index_id, Count(A.object_id) as MatchedColumns
	 From sys.index_columns as A
	 Inner Join sys.index_columns as B on
		A.object_id = B.object_id and -- same object
		A.index_id != B.index_id and -- diffrent indexes
		A.column_id = B.column_id and -- same column
		A.index_column_id = B.index_column_id
	 Group by A.object_id, A.index_id
 ) as MatchedColumnSummary on
	IndexSummary.object_id = MatchedColumnSummary.object_id and
	IndexSummary.index_id = MatchedColumnSummary.index_id and
	IndexSummary.Columns <= MatchedColumnSummary.MatchedColumns
