--SELECT * FROm Administrative.Active_Inactive_History

DECLARE @param_shcema_name as nvarchar(100)
,@param_table_name as nvarchar(100)
,@param_object_id as int
,@param_user_info_id as int
,@param_remarks as nvarchar(300)
,@param_created_datetime as datetime

SET @param_shcema_name='Auth'
SET @param_table_name='Menu'
SET @param_user_info_id=7
SET @param_object_id=2
SET @param_created_datetime=GETDATE()

DECLARE 
@pv_company_corporate_id as int
,@pv_company_id as int
,@pv_is_active as bit
,@pv_current_is_active as bit
,@pv_object_field as nvarchar(100)
,@pv_table_name as nvarchar(300)
,@pv_sql as nvarchar(max)
,@pv_active_inactive_history_id as int

SET @pv_table_name=@param_shcema_name+'.'+@param_table_name

--check valid user
IF NOT EXISTS (SELECT * FROM Auth.User_Info WHERE user_info_id=@param_user_info_id and is_active=1)
BEGIN
	ROLLBACK
		RAISERROR(N'Invalid User.',16,1);
	RETURN
END

--Find company corporate and company id
SELECT @pv_company_corporate_id=u.company_corporate_id
,@pv_company_id=u.company_id
FROm auth.User_Info u WHERE u.user_info_id=@param_user_info_id

--IF NOT EXISTS (SELECT * FROM Administrative.Company_Corporate WHERE company_corporate_id=@pv_company_corporate_id)
--BEGIN
--	ROLLBACK
--		RAISERROR(N'Invalid User.',16,1);
--	RETURN
--END

--IF NOT EXISTS (SELECT * FROM Administrative.Company WHERE company_id=@pv_company_id)
--BEGIN
--	ROLLBACK
--		RAISERROR(N'Invalid User.',16,1);
--	RETURN
--END

--Find object field
SET @pv_object_field=(SELECT C.COLUMN_NAME 
					FROM  INFORMATION_SCHEMA.TABLE_CONSTRAINTS T  
					JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE C  ON C.CONSTRAINT_NAME=T.CONSTRAINT_NAME  
					WHERE  C.TABLE_NAME=@param_table_name and T.CONSTRAINT_TYPE='PRIMARY KEY' )

IF (@pv_object_field='' OR @pv_object_field IS NULL)
BEGIN
	ROLLBACK
		RAISERROR(N'Opps. Something went wrong. Please contact with vendor',16,1);
	RETURN
END

-- find the current activation
SET @pv_sql='SELECT @pv_activity=is_active FROM '+@pv_table_name+' tbl WHERE tbl.'+@pv_object_field+'='+CONVERT(VARCHAR(50),@param_object_id)+''

EXEC sp_executesql @pv_sql, N'@pv_activity bit out', @pv_current_is_active out
SELECT @pv_current_is_active

IF (@pv_current_is_active IS NULL)
BEGIN
	ROLLBACK
		RAISERROR(N'Opps. invalid Operation. Please contact with vendor',16,1);
	RETURN
END

IF @pv_current_is_active=1
BEGIN
	SET @pv_is_active=0
END ELSE BEGIN
	SET @pv_is_active=1
END

--Update table
EXEC('UPDATE '+@pv_table_name+' SET is_active= '+@pv_is_active+' WHERE '+@pv_object_field+'='+@param_object_id+'')


--insert history
SET @pv_active_inactive_history_id=(SELECT ISNULL(MAX(ISNULL(active_inactive_history_id,0)),0)+1 FROM Administrative.Active_Inactive_History)

INSERT INTO [Administrative].[Active_Inactive_History]
			([active_inactive_history_id],	[table_schema_name],[table_name],		[object_id],		[is_active],	[remarks],		[created_datetime],		[db_server_date_time],	[created_user_id],	[company_corporate_id],	[company_id])
VALUES		(@pv_active_inactive_history_id,@param_shcema_name,	@param_table_name,	@param_object_id,	@pv_is_active,	@param_remarks,	@param_created_datetime,GETDATE(),				@param_user_info_id,@pv_company_corporate_id,@pv_company_id)



--EXEC('SELECT * FROM '+@pv_table_name+' WHERE '+@pv_object_field+'='+@param_object_id+'')





