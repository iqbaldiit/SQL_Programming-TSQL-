DECLARE @param_start_Date AS DATE
,@param_days AS INT

SET @param_start_Date='01 Jan 2000'
SET @param_days=560

--SELECT @param_days/365 AS yr, (@param_days%365)/30 AS m, @param_days-(@param_days%365)/30*30 d

DECLARE @pv_end_date AS DATE
,@pv_year AS INT
,@pv_month AS INT
,@pv_days AS INT
,@pv_date_range AS VARCHAR (500)

SET @pv_end_date=DATEADD(DAY,@param_days-1,@param_start_Date)
SET @pv_year=DATEDIFF(YEAR,@param_start_Date,@pv_end_date)
SET @pv_month=DATEDIFF(MONTH,@param_start_Date,@pv_end_date)-DATEDIFF(YEAR,@param_start_Date,@pv_end_date)*12
SET @pv_days=DATEPART(DAY,@pv_end_date)-DATEPART(DAY,@param_start_Date)+1
SET @pv_date_range=''

IF @pv_year>0 BEGIN SET @pv_date_range+=TRIM(STR(@pv_year)+'y ') END
IF @pv_month>0 BEGIN SET @pv_date_range+=' '+TRIM(STR(@pv_month)+'m ') END
IF @pv_days>0 BEGIN SET @pv_date_range+=' '+TRIM(STR(@pv_days)+'d ') END

SELECT @pv_date_range
     

