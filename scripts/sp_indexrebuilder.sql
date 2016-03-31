ALTER PROC sp_IndexRebuilder 
    @yesno VARCHAR(3)
AS
BEGIN

SELECT * FROM sys.objects

SELECT DB_ID('CarDiffData')
SELECT OBJECT_ID('Hotel')

SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID('Hotel'), NULL, NULL, NULL, NULL) ipstats
JOIN Hotel.sys.indexes IND
ON ind.object_id = ipstats.object_id 
AND ind.index_id = ipstats.index_id
JOIN Hotel.

SELECT * FROM Hotel.sys.sysindexes

SELECT * FROM sys.stats

SELECT TOP 1 * FROM sys.tables

SELECT name
FROM master.dbo.sysdatabases


SELECT *
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL)

------------------------------------------------------------------------------
-- Author: William Bratz
--
-- Description: Rebuilds indexes in current DB fragmented over 30% 
-- selecting 'yes' will actually rebuild the indexes, HEAPS are disabled
-- from being rebuilt by default. Selecting 'no' will not rebuild anything
-- it will just show you the indexes INCLUDING HEAPS.
------------------------------------------------------------------------------
IF @yesno = 'yes'
    BEGIN
	   
	   DECLARE @dblist TABLE (DBname VARCHAR(64))
	   DECLARE @db VARCHAR(64)
	   DECLARE @cmd VARCHAR(MAX)
	   CREATE TABLE #indexRebuilds (DB VARCHAR(64), TableName VARCHAR(64), SchemaName VARCHAR(64), IndexName VARCHAR(100), IndexType VARCHAR(64), Frag_Percent DECIMAL(5,2)) 

	   INSERT INTO @dblist
	   SELECT name
	   FROM master.dbo.sysdatabases
	   --WHERE name <> 'BadSegments' AND name <> 'Secured'

	   WHILE (SELECT COUNT(*) FROM @dblist) > 1
	   BEGIN


	   SELECT TOP 1 @db = dbname FROM @dblist
	   DELETE FROM @dblist where dbname = @db
	   
	   SET @cmd ='
	   INSERT INTO #indexRebuilds
	   SELECT TOP 1 ^%db^ as DB, tbls.name AS TableName, sche.name AS SchemaName,
	   ind.name AS IndexName, indexstats.index_type_desc AS IndexType, 
	   CAST(indexstats.avg_fragmentation_in_percent as decimal(5,2)) AS Frag_Percent
	   FROM sys.dm_db_index_physical_stats(DB_ID(^%db^), NULL, NULL, NULL, NULL) WITH (READUNCOMMITTED) indexstats 
	   INNER JOIN %db.sys.indexes WITH (READUNCOMMITTED) ind  
	   ON ind.object_id = indexstats.object_id 
	   AND ind.index_id = indexstats.index_id 
	   JOIN %db.sys.objects WITH (READUNCOMMITTED) objs  on ind.object_id = objs.object_id
	   JOIN %db.sys.schemas WITH (READUNCOMMITTED) sche  on objs.schema_id = sche.schema_id 
	   JOIN %db.sys.tables WITH (READUNCOMMITTED) tbls  on objs.object_id = tbls.object_ID
	   AND tbls.schema_id = sche.schema_ID
	   WHERE indexstats.avg_fragmentation_in_percent > 30 AND indexstats.index_type_desc <> ^HEAP^
	   ORDER BY indexstats.avg_fragmentation_in_percent DESC'

	   
	   SET @cmd = (SELECT REPLACE(@cmd, '%db', @db))
	   SET @cmd = (SELECT REPLACE(@cmd, '^', CHAR(39)))

	   EXEC(@cmd)
	   END
	   
	   SELECT * FROM #indexRebuilds

	   DROP TABLE #indexRebuilds

	   WHILE (SELECT COUNT(*) FROM #indexRebuilds) > 0

		  BEGIN

			 SELECT TOP 1 @Tablename = Tablename, @SchemaName = SchemaName, @IndexName = IndexName, @IndexType = IndexType, @FragPercent = Frag_Percent
			 FROM #indexRebuilds

--			 INSERT INTO AdhocBilly.dbo.IndexCleanupJob
--			 SELECT @TableName, @SchemaName, @IndexName, @FragPercent, @db, GETDATE()

			 DELETE FROM #indexRebuilds
			 WHERE TableName = @Tablename and SchemaName = @SchemaName and IndexType = @IndexType and (IndexName = @IndexName or @IndexName is NULL) and Frag_Percent = @FragPercent

			 IF (SELECT @IndexName) IS NOT NULL 
				BEGIN
				    SET @Stmt = 'ALTER INDEX '+@IndexName+' on '+@SchemaName+'.'+@TableName+' REBUILD'
				    EXEC(@Stmt)
				END 

			 IF (SELECT @IndexName) IS NULL 
				BEGIN 
				    SET @Stmt = 'ALTER TABLE '+ @SchemaName+'.'+@Tablename+' REBUILD'
				    EXEC(@Stmt)
				END
	  
		  END 

	   DROP TABLE #indexRebuilds
    END

IF @yesno <> 'yes'
    BEGIN
	   SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName, sche.name AS SchemaName,
	   ind.name AS IndexName, indexstats.index_type_desc AS IndexType, 
	   indexstats.avg_fragmentation_in_percent AS Frag_Percent
	   --INTO #indexRebuilds
	   FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
	   INNER JOIN sys.indexes ind  
	   ON ind.object_id = indexstats.object_id 
	   AND ind.index_id = indexstats.index_id 
	   JOIN sys.objects objs on ind.object_id = objs.object_id
	   JOIN sys.schemas sche on objs.schema_id = sche.schema_id 
	   WHERE indexstats.avg_fragmentation_in_percent > 30 --
	   ORDER BY indexstats.avg_fragmentation_in_percent DESC
    END
END
