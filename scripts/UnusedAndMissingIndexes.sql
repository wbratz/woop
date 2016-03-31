
-- Missing Index

SELECT mig.index_group_handle,
       mid.index_handle,
       migs.avg_total_user_cost AS AvgTotalUserCostThatCouldbeReduced,
       migs.avg_user_impact AS AvgPercentageBenefit,
       'CREATE INDEX missing_index_'+CONVERT( VARCHAR, mig.index_group_handle)+'_'+CONVERT(VARCHAR, mid.index_handle)+' ON '+mid.statement+' ('+ISNULL(mid.equality_columns, '')+CASE
                         WHEN mid.equality_columns IS NOT NULL
                              AND mid.inequality_columns IS NOT NULL
                         THEN ','
                         ELSE ''
				     END+ISNULL(mid.inequality_columns, '')+')'+ISNULL(' INCLUDE ('+mid.included_columns+')', '') AS create_index_statement
FROM sys.dm_db_missing_index_groups mig
     INNER JOIN sys.dm_db_missing_index_group_stats migs
         ON migs.group_handle = mig.index_group_handle
     INNER JOIN sys.dm_db_missing_index_details mid
         ON mig.index_handle = mid.index_handle
            --where statement = '[.[dbo].[<TableName>]'
	   ORDER BY AvgPercentageBenefit DESC, AvgTotalUserCostThatCouldbeReduced DESC

-- Unused index

SELECT OBJECT_NAME(i.object_id) AS ObjectName,
       i.name AS [Unused Index]
FROM sys.indexes i
     LEFT JOIN sys.dm_db_index_usage_stats s
         ON s.object_id = i.object_id
            AND i.index_id = s.index_id
            AND s.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsIndexable') = 1
      AND OBJECTPROPERTY(i.object_id, 'IsIndexed') = 1
      AND s.index_id IS NULL -- and dm_db_index_usage_stats has no reference to this index
	 			 --AND i.name COLLATE DATABASE_DEFAULT IN (SELECT IndexName FROM [US-HEN-SQLDEV].DBA_Data.dbo.IndexAudit WHERE Indexname <> 'Heap')
	 
      OR (s.user_updates > 0
          AND s.user_seeks = 0
          AND s.user_scans = 0
          AND s.user_lookups = 0			 
		)--AND i.name COLLATE DATABASE_DEFAULT IN (SELECT IndexName FROM [US-HEN-SQLDEV].DBA_Data.dbo.IndexAudit WHERE Indexname <> 'Heap'))
ORDER BY OBJECT_NAME(i.object_id) 