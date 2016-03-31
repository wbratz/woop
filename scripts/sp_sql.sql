CREATE PROC dbo.sp_sql
    @tname VARCHAR(100),
    @output VARCHAR(64)
AS
BEGIN

----------------------------------------------------------------------------------------------
-- AUTHOR: William Bratz
-- Date: 03/08/16
-- Description: This proc will take a tablename input (@tname), and desired output type
-- and will return the columns for that able name in the desired output type format.
-- 
-- CURRENT SUPPORTED OUTPUTS:
-- select
-- insert
-- create
-- variable
-- all
-- any input other than will result in all outputs being given, ENJOY!
----------------------------------------------------------------------------------------------

    DECLARE @cname VARCHAR(100)
    DECLARE @datatype VARCHAR(100)
    DECLARE @length VARCHAR(100)
    DECLARE @pris VARCHAR(10)
    DECLARE @scale VARCHAR(10)
    DECLARE @coloop INT
    DECLARE @coloopstart int
    DECLARE @stmt VARCHAR(MAX) 
    DECLARE @stmt2 VARCHAR(MAX)

    -- DECLARE @tname VARCHAR(100) = 'billofmaterials'
    -- DECLARE @output VARCHAR(64)
    -- SET @output = 'create'
    
    -- SET @output = 'select'

    -- SET @output = 'variable'

    SET NOCOUNT ON;

    IF @output NOT IN ('select', 'insert', 'create', 'variable')
	   BEGIN
		  SET @output = 'all'
	   END

    IF @output = 'all'

	   BEGIN

		  DECLARE @ot TABLE (ID INT, output1 VARCHAR(64))
		  INSERT INTO @ot 
		  VALUES (1, 'select')
		  ,(2, 'insert')
		  ,(3, 'create')
		  ,(4, 'variable')
		  ,(5, 'end')

		  WHILE (SELECT COUNT(*) FROM @ot) > 0
		  BEGIN

			 SET @output = (SELECT TOP 1 output1 FROM @ot)
			 DELETE FROM @ot WHERE output1 = @output

			 IF OBJECT_ID('tempdb..#temp') IS NOT NULL
				BEGIN
				    DROP TABLE #temp
				END

			 CREATE TABLE #temp (Column_Name VARCHAR(100))

			 SET @stmt = 'INSERT INTO #temp SELECT c.name 
			 FROM sys.objects o 
			 JOIN sys.tables t 
				ON o.object_id = t.object_id 
			 JOIN sys.columns c 
				ON t.object_id = c.OBJECT_ID 
			 WHERE t.NAME = ^%tname^'

			 SET @stmt = (SELECT REPLACE(@stmt, '^', CHAR(39)))
			 SET @stmt = (SELECT REPLACE(@stmt, '%tname', @tname))

			 EXEC (@stmt)

			 IF OBJECT_ID('tempdb..#tclist') IS NOT NULL
				BEGIN
				    DROP TABLE #tclist
				END

			 CREATE TABLE #tclist (ColumnName VARCHAR(100), 
							   DataType VARCHAR(100), 
							   [LENGTH] INT, 
							   Pres INT, 
							   Scale INT )

			 WHILE (SELECT COUNT(*) FROM #temp) > 0
				BEGIN
				    SELECT TOP 1 @cname = Column_name FROM #temp
				    DELETE FROM #temp WHERE Column_Name = @cname

				    SET @stmt2 =
				    'INSERT INTO #tclist
				    SELECT Column_Name, Data_Type, Character_Maximum_Length, Numeric_Precision, Numeric_scale
				    FROM INFORMATION_SCHEMA.COLUMNS IC
				    WHERE TABLE_Name = ^%tname^ AND COLUMN_NAME = ^%cname^'

				    SET @stmt2 = (SELECT REPLACE(@stmt2, '^', CHAR(39)))
				    SET @stmt2 = (SELECT REPLACE(@stmt2, '%tname', @tname))
				    SET @stmt2 = (SELECT REPLACE(@stmt2, '%cname', @cname))

				    EXEC (@stmt2)

				END

			 SET @coloopstart = (SELECT COUNT(*) FROM #tclist)
			 SET @coloop = @coloopstart
			 SET @stmt = 'SELECT_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'

			 IF @output <> 'insert' AND @output <> 'select'
			 BEGIN
				IF @coloop = @coloopstart
				    BEGIN
	   
					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype

					    IF @datatype = 'decimal' or @datatype = 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+'('+@pris+','+@scale+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END

					   IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+'('+@length+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END 
					   IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END
				    END   

				WHILE @coloop BETWEEN 2 AND @coloopstart
				    BEGIN

					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype

					    IF @datatype = 'decimal' or @datatype = 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+CHAR(13)+@cname+' '+@datatype+'('+@pris+','+@scale+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END
					   IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'('+@length+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END 
					   IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END
				    END

				WHILE @coloop = 1
				    BEGIN

					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype

					    IF @datatype = 'decimal' or @datatype = 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+CHAR(13)+@cname+' '+@datatype+'('+@pris+','+@scale+')*'))
						  END
					   IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'('+@length+')*'))
						  END 
					   IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'*'))
						  END
				    END

				IF @output = 'variable'
				BEGIN
				    SET @stmt = (SELECT REPLACE(@stmt, CHAR(13), CHAR(13)+'@'))
				    SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ','DECLARE @'))
				END

				IF @output = 'create'
				BEGIN
				    SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ', 'CREATE TABLE %table_name ('))
				    SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
				    SET @stmt = (SELECT REPLACE(@stmt, '*', ')')) 
				END

			 END

			 IF @output = 'insert' OR @output = 'select'
			 BEGIN
				    IF @coloop = @coloopstart
				    BEGIN
	   
					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype



					   IF @length IS NOT NULL
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END 
					   IF @length IS NULL
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END
				    END   

				WHILE @coloop BETWEEN 2 AND @coloopstart
				    BEGIN

					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype

					   IF @length IS NOT NULL
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END 
					   IF @length IS NULL
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
						  END
				    END

				WHILE @coloop = 1
				    BEGIN

					   SET @coloop = (SELECT @coloop - 1)

					   SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
					   FROM #tclist
					   DELETE FROM #tclist WHERE ColumnName = @cname and DataType = @datatype

					   IF @length IS NOT NULL
						  BEGIN 
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+'*'))
						  END 
					   IF @length IS NULL
						  BEGIN
							 SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+'*'))
						  END
				    END

				IF @output = 'insert'
				    BEGIN
					   SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ', 'INSERT INTO %table_name ('))
					   SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
					   SET @stmt = (SELECT REPLACE(@stmt, '*', ')')) 
				    END

				IF @output = 'select'
				    BEGIN

					   SET @stmt = (SELECT REPLACE(@stmt, '*', CHAR(13)+'FROM %table_name'))
					   SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
				    END 
			 END


			 SET @stmt = (SELECT REPLACE(@stmt, '*', '')) 

			 IF @stmt = 'SELECT_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'
				SET @output = 'end'
			 IF @stmt IS NULL
				BEGIN
				    SET @output ='end'
				    PRINT'The table you specified does not exist in the database you are currently in, check your syntax, or change databases.'
				END
			 IF @output <> 'end'
				BEGIN
					  SELECT LTRIM(RTRIM(@stmt))
				END
			 IF @stmt IS NULL
				BEGIN
				    BREAK
				END
			 END
		  END

    IF @output <> 'all' AND @output <> 'end'
    BEGIN
	   IF OBJECT_ID('tempdb..#temp2') IS NOT NULL
		  BEGIN
			 DROP TABLE #temp2
		  END

	   CREATE TABLE #temp2 (Column_Name VARCHAR(100))

	   SET @stmt = 'INSERT INTO #temp2 SELECT c.name 
	   FROM sys.objects o 
	   JOIN sys.tables t 
		  ON o.object_id = t.object_id 
	   JOIN sys.columns c 
		  ON t.object_id = c.OBJECT_ID 
	   WHERE t.NAME = ^%tname^'

	   SET @stmt = (SELECT REPLACE(@stmt, '^', CHAR(39)))
	   SET @stmt = (SELECT REPLACE(@stmt, '%tname', @tname))

	   EXEC (@stmt)

	   IF OBJECT_ID('tempdb..#tclist2') IS NOT NULL
		  BEGIN
			 DROP TABLE #tclist2
		  END

	   CREATE TABLE #tclist2 (ColumnName VARCHAR(100), 
						DataType VARCHAR(100), 
						[LENGTH] INT, 
						Pres INT, 
						Scale INT )

	   WHILE (SELECT COUNT(*) FROM #temp2) > 0
		  BEGIN
			 SELECT TOP 1 @cname = Column_name FROM #temp2
			 DELETE FROM #temp2 WHERE Column_Name = @cname

			 SET @stmt2 =
			 'INSERT INTO #tclist2
			 SELECT Column_Name, Data_Type, Character_Maximum_Length, Numeric_Precision, Numeric_scale
			 FROM INFORMATION_SCHEMA.COLUMNS IC
			 WHERE TABLE_Name = ^%tname^ AND COLUMN_NAME = ^%cname^'

			 SET @stmt2 = (SELECT REPLACE(@stmt2, '^', CHAR(39)))
			 SET @stmt2 = (SELECT REPLACE(@stmt2, '%tname', @tname))
			 SET @stmt2 = (SELECT REPLACE(@stmt2, '%cname', @cname))

			 EXEC (@stmt2)

		  END

	   SET @coloopstart = (SELECT COUNT(*) FROM #tclist2)
	   SET @coloop = @coloopstart
	   SET @stmt = 'SELECT_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'

	   IF @output <> 'insert' AND @output <> 'select'
		  BEGIN
			 IF @coloop = @coloopstart
				BEGIN
	   
				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype

					IF @datatype = 'decimal' or @datatype = 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+'('+@pris+','+@scale+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END

				    IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+'('+@length+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END 
				    IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+' '+@datatype+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END
				END   

			 WHILE @coloop BETWEEN 2 AND @coloopstart
				BEGIN

				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype

					IF @datatype = 'decimal' or @datatype = 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+CHAR(13)+@cname+' '+@datatype+'('+@pris+','+@scale+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END
				    IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'('+@length+'),_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END 
				    IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END
				END

			 WHILE @coloop = 1
				BEGIN

				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length], @pris = Pres, @scale = Scale
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype

					IF @datatype = 'decimal' or @datatype = 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+CHAR(13)+@cname+' '+@datatype+'('+@pris+','+@scale+')*'))
					   END
				    IF @length IS NOT NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'('+@length+')*'))
					   END 
				    IF @length IS NULL AND @datatype <> 'decimal' AND @datatype <> 'numeric'
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+' '+@datatype+'*'))
					   END
				END

			 IF @output = 'variable'
			 BEGIN
				SET @stmt = (SELECT REPLACE(@stmt, CHAR(13), CHAR(13)+'@'))
				SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ','DECLARE @'))
			 END

			 IF @output = 'create'
			 BEGIN
				SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ', 'CREATE TABLE %table_name ('))
				SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
				SET @stmt = (SELECT REPLACE(@stmt, '*', ')')) 
			 END

		  END

		  IF @output = 'insert' OR @output = 'select'
		  BEGIN
				IF @coloop = @coloopstart
				BEGIN
	   
				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype



				    IF @length IS NOT NULL
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END 
				    IF @length IS NULL
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, '_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ' '+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END
				END   

			 WHILE @coloop BETWEEN 2 AND @coloopstart
				BEGIN

				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype

				    IF @length IS NOT NULL
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END 
				    IF @length IS NULL
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'))
					   END
				END

			 WHILE @coloop = 1
				BEGIN

				    SET @coloop = (SELECT @coloop - 1)

				    SELECT TOP 1 @cname = ColumnName, @datatype = DataType, @length = [Length]
				    FROM #tclist2
				    DELETE FROM #tclist2 WHERE ColumnName = @cname and DataType = @datatype

				    IF @length IS NOT NULL
					   BEGIN 
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+'*'))
					   END 
				    IF @length IS NULL
					   BEGIN
						  SET @stmt = (SELECT REPLACE(@stmt, ',_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED', ','+CHAR(13)+@cname+'*'))
					   END
				END

			 IF @output = 'insert'
				BEGIN
				    SET @stmt = (SELECT REPLACE(@stmt, 'SELECT ', 'INSERT INTO %table_name ('))
				    SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
				    SET @stmt = (SELECT REPLACE(@stmt, '*', ')')) 
				END

			 IF @output = 'select'
				BEGIN

				    SET @stmt = (SELECT REPLACE(@stmt, '*', CHAR(13)+'FROM %table_name'))
				    SET @stmt = (SELECT REPLACE(@stmt, '%table_name', @tname))
				END 
		  END


		  SET @stmt = (SELECT REPLACE(@stmt, '*', '')) 
		  IF @stmt <> 'SELECT_TABLE HAS UNSPECIFIED DATATYPE PROC NEEDS TO BE UPDATED'
			 BEGIN
				SELECT LTRIM(RTRIM(@stmt))
			 END
		  ELSE
			 PRINT'The table you specified does not exist in the database you are currently in, check your syntax, or change databases.'
	   END
END