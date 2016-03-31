----------------------------------------------------------------------------------------------
-- AUTHOR: William Bratz
-- Date: 03/08/16
----------------------------------------------------------------------------------------------
	  
	  
	   DECLARE @dblist TABLE (DBname VARCHAR(64))
	   DECLARE @db VARCHAR(64)
	   DECLARE @cmd VARCHAR(MAX)


--CREATE TABLE #indexRebuilds(DB           VARCHAR(64),
--                            TableName    VARCHAR(MAX),
--                            SchemaName   VARCHAR(64),
--                            IndexName    VARCHAR(MAX),
--                            IndexType    VARCHAR(64),
--                            Frag_Percent DECIMAL(5, 2),
--                            InsertDate   DATE NOT NULL
--                                              DEFAULT GETDATE(),
--					   )
									

	   INSERT INTO @dblist
	   SELECT name
	   FROM master.dbo.sysdatabases
	   WHERE name <> 'Secured'

	   WHILE (SELECT COUNT(*) FROM @dblist) > 1
	   BEGIN


	   SELECT TOP 1 @db = dbname FROM @dblist
	   DELETE FROM @dblist where dbname = @db
	   
	   SET @cmd ='
	   INSERT INTO [US-HEN-SQLDEV].[DBA_DATA].[dbo].[IndexAudit] (DB, TableName, SchemaName, IndexName, IndexType, Frag_Percent)
	   SELECT ^%db^ as DB, tbls.name AS TableName, sche.name AS SchemaName,
	   CASE WHEN ind.name IS NULL THEN ^HEAP^ WHEN ind.name IS NOT NULL THEN ind.name END, indexstats.index_type_desc AS IndexType, 
	   CAST(indexstats.avg_fragmentation_in_percent as decimal(5,2)) AS Frag_Percent
	   FROM sys.dm_db_index_physical_stats(DB_ID(^%db^), NULL, NULL, NULL, NULL) indexstats 
	   INNER JOIN %db.sys.indexes ind 
	   ON ind.object_id = indexstats.object_id 
	   AND ind.index_id = indexstats.index_id 
	   JOIN %db.sys.objects objs  on ind.object_id = objs.object_id
	   JOIN %db.sys.schemas sche on objs.schema_id = sche.schema_id 
	   JOIN %db.sys.tables  tbls on objs.object_id = tbls.object_ID
	   AND tbls.schema_id = sche.schema_ID
	   WHERE indexstats.avg_fragmentation_in_percent > 30
	   ORDER BY indexstats.avg_fragmentation_in_percent DESC'

	   
	   SET @cmd = (SELECT REPLACE(@cmd, '%db', @db))
	   SET @cmd = (SELECT REPLACE(@cmd, '^', CHAR(39)))

	   EXEC(@cmd)
	   END
	   