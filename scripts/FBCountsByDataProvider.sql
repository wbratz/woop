-- F&B Data Provider Counts by Month
-- The #'s below will be all records whether they are accepted or rejected
-- There are lines you can comment in/out if needing to find out a count of good records & a count of rejected records

--USE Hotel_Stage

DECLARE @Columns varchar(8000)

SELECT @columns = COALESCE(@columns + ',[' + cast(d.[Year] * 100 + d.Month as varchar) + ']',
'[' + cast(d.[Year] * 100 + d.Month as varchar)+ ']')
FROM (
	SELECT DISTINCT YEAR(r.[Date]) [Year],  MONTH(r.[Date]) Month FROM raw.MonthlySalesFoodAndBeverage r
	WHERE r.Date >= '1/1/2012'
) d
ORDER BY d.[Year], d.Month

DECLARE @query VARCHAR(8000)

SET @query = '
;WITH Data AS (

SELECT
	dp.DataProviderName as [Data Provider],
	[Contact Email] = 
	CASE 
	WHEN (NULLIF(LTRIM(RTRIM(ReminderContactEmail)), '''') IS NULL) THEN ISNULL(NULLIF(LTRIM(RTRIM(ReminderContactEmail2)), ''''), ''N/A'')
	ELSE ReminderContactEmail
	END, 
	df.IsActive, 
	CAST(rcg.RefCountryGroupID as VARCHAR(3)) RefCountryGroupID,
	Description = 
		  CASE rcg.sDescription  
		  WHEN ''Default Group'' THEN ''NNA'' 
		  ELSE rcg.sDescription 
		  END,
	YEAR(r.[Date]) * 100 + MONTH(r.[Date]) AS RecordDate,
	COUNT(DISTINCT r.censusID) RecordCount
FROM raw.MonthlySalesFoodAndBeverage r
JOIN Hotel.Census hc ON hc.CensusID = r.CensusID
JOIN Hotel.RefCountry rc ON rc.RefCountryID = hc.RefCountryID
JOIN Hotel.RefCountryGroup rcg ON rc.RefCountryGroupID = rcg.RefCountryGroupID
INNER JOIN dbo.DataProviderFeed df ON df.DataProviderFeedID = r.DataProviderFeedID
INNER JOIN dbo.DataProvider dp ON dp.DataProviderID = df.DataProviderID
WHERE r.Date >= ''1/1/2012''
AND r.dtDeleted IS NULL
------AND r.RawRecordStatus IN (1, 3)                                        -- ** Uncomment this line if only wanting to see count of good records **
------AND r.RawRecordStatus = 5												 -- ** Uncomment the 5 lines below if only wanting to see counts w/supply issues **
------AND EXISTS(SELECT * FROM dbo.DataFileLoadError de 
------	WHERE de.nBatchNo = r.BatchNo AND de.RowNumber = r.RowNumber 
------	AND de.StageID =r.StageID 
------	AND de.RefLoadErrorID IN (1036, 1037, 1039, 1040))
GROUP BY dp.DataProviderName, ReminderContactEmail, ReminderContactEmail2, df.isactive,rcg.RefCountryGroupID, rcg.sDescription,  r.Date
)
SELECT *
FROM Data
PIVOT (
SUM (RecordCount)
FOR RecordDate IN (' + @columns + ')
)
AS p
'

EXECUTE(@query)