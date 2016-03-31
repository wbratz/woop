----------------------------------------------------------------------------------------------
-- AUTHOR: William Bratz
-- Date: 03/08/16
----------------------------------------------------------------------------------------------

DECLARE @dbid INT
DECLARE @dbname VARCHAR(32)
DECLARE @stmt VARCHAR(MAX)

DECLARE @dbids TABLE
([dbid] int, dbName VARCHAR(32))

CREATE TABLE #temp
( DBname VARCHAR(32),
 [Table Name] VARCHAR(32),
 [Schema Name] VARCHAR(32),
 [Index Name] VARCHAR(64),
 [Index Type] VARCHAR(32),
 [Frag Percent] VARCHAR(16)
 )

INSERT INTO @dbids 
SELECT database_id, name
FROM sys.databases
WHERE DATABASE_ID > 6

WHILE (SELECT COUNT(*) FROM @dbids) > 50 
BEGIN
    SELECT TOP 1 @dbid = [dbid], @dbname = dbname FROM @dbids
    DELETE FROM @dbids WHERE [dbid] = @dbid AND dbname = @dbname

    SET @stmt ='
	INSERT INTO #temp
	SELECT TOP 1 ^%dbname^ [DBName], OBJECT_NAME(ind.OBJECT_ID) AS [TABLE NAME], sche.name AS [SCHEMA Name],
	ind.name AS [INDEX Name], indexstats.index_type_desc AS [INDEX Type], 
	indexstats.avg_fragmentation_in_percent AS [Frag Percent]
	--INTO #indexRebuilds
	FROM sys.dm_db_index_physical_stats(%dbid, NULL, NULL, NULL, NULL) indexstats 
	INNER JOIN sys.indexes ind  
	ON ind.object_id = indexstats.object_id 
	AND ind.index_id = indexstats.index_id 
	JOIN sys.objects objs on ind.object_id = objs.object_id
	JOIN sys.schemas sche on objs.schema_id = sche.schema_id 
	WHERE indexstats.avg_fragmentation_in_percent > 30 AND indexstats.index_type_desc <> ^HEAP^
	ORDER BY indexstats.avg_fragmentation_in_percent DESC'

	SET @stmt = (SELECT REPLACE(@stmt, '^', CHAR(39)))
	SET @stmt = (SELECT REPLACE(@stmt, '%dbname', @dbname))
	SET @stmt = (SELECT REPLACE(@stmt, '%dbid', @dbid))

	EXEC(@stmt)


END

 SELECT * FROM #temp

 SELECT TOP 1 * FROM sys.dm_db_index_physical_stats()