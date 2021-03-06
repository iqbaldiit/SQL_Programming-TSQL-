-- =============================================
-- Author:		Md. Masud Iwbal
-- Create date: 24 April 2013
-- Description:	This Process is for getting list of child and parent ids sequentially for 
--				any kind of hierachy table by primary key id as input id.
/*
Summary:

01. User Input His Hierachy Table Name, PrimaryKey Field name,Parent field name, 
	Single Primary key field value or multiple Primary key valus as sting with coma separator.
	Now user input his getting requirement like only parent or only child or both.
	If user want his input id in his list, he can set WithoutInputId as 1.
*/
-- =============================================

CREATE TABLE #tbl_Location (LocationID int, Location_Name varchar(50), ParentID int)
INSERT INTO #tbl_Location VALUES (1,'Bangladesh',0)
INSERT INTO #tbl_Location VALUES (2,'UK',0)
INSERT INTO #tbl_Location VALUES (3,'USA',0)
INSERT INTO #tbl_Location VALUES (4,'Dhaka',1)
INSERT INTO #tbl_Location VALUES (5,'London',2)
INSERT INTO #tbl_Location VALUES (6,'NewYork',3)
INSERT INTO #tbl_Location VALUES (7,'Dhanmondi',4)
INSERT INTO #tbl_Location VALUES (8,'Dh_Shoping Mall',7)

--SELECT * FROM @tbl_Location

--ALTER PROCEDURE [dbo].[SP_GetHierarchyList] (
DECLARE
	@Param_TableName as nvarchar (100),
	@Param_PrimaryKeyColumn as nvarchar (100),
	@Param_ParentColumn as nVarchar(100),
	@Param_isParent bit,
	@Param_isChild bit,
    @Param_InputIDs nvarchar(max),
    @Param_WithInputID bit    
--)

	SET @Param_TableName='#tbl_Location'
	SET @Param_PrimaryKeyColumn='LocationID'
	SET @Param_ParentColumn='ParentID'
	SET @Param_isParent='1'
	SET @Param_isChild ='1'
    SET @Param_InputIDs='1'
    SET @Param_WithInputID=1 

--AS
--BEGIN Tran
    DECLARE @RootID int
     ,@ParentID int
     ,@PV_SQLString as nvarchar(max)
     ,@PV_RowIndex as int
     ,@PV_InputID as int
     
    --DECLARE @Lst as TABLE (id int)
    CREATE TABLE #tempLst (id int)
    
    SET @PV_RowIndex=0
    
    IF @Param_WithInputID=1 
	BEGIN
		INSERT INTO #tempLst SELECT * FROM 	dbo.SplitInToDataSet(@Param_InputIDs,',')
	END	
    
    --Get only Parent
    IF @Param_isParent=1
    BEGIN
		WHILE (@PV_RowIndex<(SELECT COUNT(*) FROM 	dbo.SplitInToDataSet(@Param_InputIDs,',')))
		BEGIN
			SET @PV_InputID= CONVERT(int,dbo.SplitedStringGet(@Param_InputIDs,',',@PV_RowIndex))
			SET @PV_SQLString=N'SELECT @ParentID='+@Param_ParentColumn+' FROM '+@Param_TableName+'	WHERE '+@Param_PrimaryKeyColumn+' ='+ CONVERT(varchar(50),@PV_InputID)
			EXEC sp_executesql @PV_SQLString, N'@ParentID int out', @ParentID output
			INSERT INTO #tempLst VALUES (@ParentID)
			
			WHILE @ParentID!=1
			BEGIN
				SET @PV_SQLString=N'SELECT @ParentID='+@Param_ParentColumn+' FROM '+@Param_TableName+'	WHERE '+@Param_PrimaryKeyColumn+' ='+ CONVERT(varchar(50),@ParentID)
				EXEC sp_executesql @PV_SQLString, N'@ParentID int out', @ParentID output				
				IF NOT EXISTS(SELECT * FROM #tempLst WHERE id=@ParentID)
				BEGIN
					INSERT INTO #tempLst VALUES (@ParentID)				
				END
				ELSE Break;
			END--insert	
			
			SET @PV_RowIndex=@PV_RowIndex+1
		END--rowindex
	END--Parent

	--Get Only Child
	IF @Param_isChild=1
	BEGIN
		INSERT INTO #tempLst
		EXEC('WITH  tbl
				AS (
					SELECT  '+@Param_PrimaryKeyColumn+'
					FROM    '+@Param_TableName+'
					WHERE   '+@Param_ParentColumn+' IN ('+@Param_InputIDs+')
					UNION ALL
					SELECT  rt.'+@Param_PrimaryKeyColumn+'                    
					FROM    '+@Param_TableName+' AS rt
							JOIN tbl AS ac
							  ON rt.'+@Param_ParentColumn+' = ac.'+@Param_PrimaryKeyColumn+'
				   )				   
				   SELECT * FROM tbl')		
			
	END--child	
	EXEC('SELECT * FROM '+@Param_TableName+' WHERE '+@Param_PrimaryKeyColumn+' IN 
    (SELECT distinct id FROM #tempLst ) ORDER By '+@Param_ParentColumn+', '+@Param_PrimaryKeyColumn)
    DROP TABLE #tempLst
--Commit Tran
DROP TABLE #tbl_Location
