-- Create school load scrip

-- needs a staging schema
CREATE SCHEMA staging
-- needs a loading table for k-12 and one for Colleges
CREATE TABLE staging.SchoolDataDumpK12 (PreceedingName VARCHAR(100)
							 , [State] VARCHAR(100)
							 , County VARCHAR(100)
							 , City VARCHAR(100)
							 , ReportingDistrictName VARCHAR(MAX)
							 , SchoolPop INT, Notes VARCHAR(MAX)
							 , FirstDay DATE
							 , MidFallBreakStart DATE
							 , MidFallBreakEnd DATE
							 , ThanksgivingStart DATE
							 , ThanksgivingEnd DATE
							 , WinterBreakStart DATE
							 , WinterBreakEnd DATE
							 , MidWinterBreakStart DATE
							 , MidWinterBreakEnd DATE
							 , SpringBreakStart DATE
							 , SpringBreakEnd DATE
							 , LastDay DATE
							 , ExtraBreakStart DATE
							 , ExtraBreakEnd DATE
							 , ExtraBreak1Start DATE
							 , ExtraBreak1End DATE
							 )

-- College Table
CREATE TABLE staging.SchoolDataDumpColl (PreceedingName VARCHAR(100)
							 , [State] VARCHAR(100)
							 , CollegeUniversity VARCHAR(MAX)
							 , City VARCHAR(100)
							 , [Population] INT
							 , Notes VARCHAR(MAX)
							 , FirstDay DATE
							 , MidFallBreakStart DATE
							 , MidFallBreakEnd DATE
							 , ThanksgivingStart DATE
							 , ThanksgivingEnd DATE
							 , WinterBreakStart DATE
							 , WinterBreakEnd DATE
							 , MidWinterBreakStart DATE
							 , MidWinterBreakEnd DATE
							 , SpringBreakStart DATE
							 , SpringBreakEnd DATE
							 , LastDay DATE
							 , ExtraBreakStart DATE
							 , ExtraBreakEnd DATE
							 , ExtraBreak1Start DATE
							 , ExtraBreak1End DATE
							 )


-- Execute SSIS Package to dump Data
-- Check Data
SELECT * FROM staging.SchoolDataDumpk12
SELECT * FROM staging.SchoolDataDumpColl

-- Jon's Query
/*

SELECT CAST(b.Base AS DATE) RecordDate, 'US' country, a.state, a.county, a.city, a.district, a.studentpopulation, 
    CASE 
        WHEN base < startTerm THEN 0 -- beforetermstart
        WHEN base BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN base BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN base BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
        WHEN base > EndTerm THEN 0 -- aftertermend
    ELSE 1
    END InSession,
    CASE 
        WHEN base < startTerm THEN 0 -- beforetermstart
        WHEN base BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN base BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN base BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
        WHEN base > EndTerm THEN 0 -- aftertermend
    ELSE studentPopulation
    END populationInSession, 
    CASE 
        WHEN base < startTerm THEN 'beforeTermStart'
        WHEN base BETWEEN winterBreakStart AND winterbreakEND THEN 'winterBreak'
        WHEN base BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 'midWinterBreak'
        WHEN base BETWEEN springBreakStart AND springbreakEND THEN 'springBreak'
        WHEN base > EndTerm THEN 'afterTermEnd'
    ELSE 'InSession'
    END RecordEvent
FROM [dbo].[schooldatesraw_k12] a
CROSS APPLY dbo.dates b
WHERE base BETWEEN '7/1/15' AND '6/30/16'
ORDER BY state, county, city, base

*/

-- I don't have a dates table so I might as well create one, wonder how long this will take
CREATE SCHEMA dim

CREATE TABLE dim.dateNoTime (ID INT IDENTITY (1,1) PRIMARY KEY, [Date] DATE)

-- Loopy add 1
DECLARE @dt date
DECLARE @dtstart date

SET @dt = '1900-01-01'

WHILE @dt < '3000-01-01'
BEGIN

INSERT INTO dim.dateNoTime
SELECT @dt

SET @dt = (SELECT DATEADD(DAY, 1, @dt))
END

-- That took ....34 seconds pretty cool
-- Don't want double dates
CREATE UNIQUE INDEX UQ_INDEX0 ON dim.dateNoTime ([Date]) WITH IGNORE_DUP_KEY
CREATE NONCLUSTERED INDEX IX_Index0 ON dim.dateNoTime (ID) INCLUDE (DATE)

-- Keeping track of breaks
/* 
MidFallBreak
Thanksgiving
WinterBreak
MidWinterBreak
SpringBreak
ExtraBreak
ExtraBreak1
*/

-- Updated Query taken from above for K-12
SELECT CAST(b.date AS DATE) RecordDate, 'US' country, a.state, a.county, a.city, a.ReportingDistrictName, a.schoolPop, 
    CASE 
        WHEN date < FirstDay THEN 0 -- beforetermstart
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 0 --MidFallBreak
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 0 --ThanksgivingBreak
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 0 -- ExtraBreak
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 0 -- ExtraBreak1
        WHEN date > LastDay THEN 0 -- aftertermend
    ELSE 1
    END InSession,
    CASE 
        WHEN date < FirstDay THEN 0 -- beforetermstart
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 0 --MidFallBreak
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 0 --ThanksgivingBreak
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 0 -- ExtraBreak
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 0 -- ExtraBreak1
        WHEN date > LastDay THEN 0 -- aftertermend
    ELSE SchoolPop
    END populationInSession, 
    CASE 
        WHEN date < FirstDay THEN 'Before Term Start'
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 'Mid-Fall Break'
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 'Thanksgiving Break'
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN  'Winter Break'
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 'Mid-Winter Break'
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 'Spring Break'
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 'Extra Break'
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 'Extra Break'
        WHEN date > LastDay THEN 'After Term End'
    ELSE 'In Session'
    END RecordEvent
FROM staging.SchoolDataDumpK12 a
CROSS APPLY DIMS.dim.dates b
WHERE date BETWEEN '7/1/16' AND '6/30/17'
ORDER BY state, county, city, date

-- Updated Query taken from above for Colleges
SELECT CAST(b.date AS DATE) RecordDate, 'US' country, a.state, a.city, a.CollegeUniversity, a.POPULATION, 
    CASE 
        WHEN date < FirstDay THEN 0 -- beforetermstart
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 0 --MidFallBreak
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 0 --ThanksgivingBreak
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 0 -- ExtraBreak
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 0 -- ExtraBreak1
        WHEN date > LastDay THEN 0 -- aftertermend
    ELSE 1
    END InSession,
    CASE 
        WHEN date < FirstDay THEN 0 -- beforetermstart
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 0 --MidFallBreak
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 0 --ThanksgivingBreak
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN 0 -- winterBreak
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 0 -- midwinterBreak
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 0 -- springBreak
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 0 -- ExtraBreak
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 0 -- ExtraBreak1
        WHEN date > LastDay THEN 0 -- aftertermend
    ELSE [Population]
    END populationInSession, 
    CASE 
        WHEN date < FirstDay THEN 'Before Term Start'
	   WHEN date BETWEEN MidFallBreakStart AND MidFallBreakEND THEN 'Mid-Fall Break'
	   WHEN date BETWEEN ThanksgivingStart AND ThanksgivingEND THEN 'Thanksgiving Break'
	   WHEN date BETWEEN winterBreakStart AND winterbreakEND THEN  'Winter Break'
        WHEN date BETWEEN midwinterBreakStart AND midwinterbreakEND THEN 'Mid-Winter Break'
        WHEN date BETWEEN springBreakStart AND springbreakEND THEN 'Spring Break'
	   WHEN date BETWEEN ExtraBreakStart AND ExtraBreakEnd THEN 'Extra Break'
	   WHEN date BETWEEN ExtraBreak1Start AND ExtraBreak1END THEN 'Extra Break'
        WHEN date > LastDay THEN 'Bfter Term End'
    ELSE 'In Session'
    END RecordEvent
FROM staging.SchoolDataDumpColl a
CROSS APPLY DIMS.dim.dates b
WHERE date BETWEEN '7/1/16' AND '6/30/17' 
ORDER BY state, city, CollegeUniversity, date
 

