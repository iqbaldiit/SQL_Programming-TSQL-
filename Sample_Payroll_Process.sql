/*
-- =============================================
-- Author:		Md. Masud Iqbal
-- Create date: 1 Jul 2019
-- Description:	This is a sample payroll process as designed to my HCM project. This process need all required table existance to execute.
-- =============================================
*/



CREATE PROCEDURE [dbo].[SP_Process_Payroll] 
@Param_Index as int--for pagination top 300. 
,@Param_PayRollProcessID as int
,@Param_EmployeeIDs as varchar (max)
,@Param_DBUserID as int

--SET @Param_Index=0
--SET @Param_PayRollProcessID=1
--SET @Param_DBUserID=-9
AS
BEGIN
--DECLARE
--@Param_Index as int--for pagination top 300. 
--,@Param_PayRollProcessID as int
--,@Param_EmployeeIDs as varchar (max)
--,@Param_DBUserID as int

--SET @Param_Index =0
--SET @Param_PayRollProcessID=375--400
--SET @Param_EmployeeIDs=''
--SET @Param_DBUserID=-9

 
	--Common Validation
	IF (@Param_PayRollProcessID>0 AND @Param_EmployeeIDs!='') OR (@Param_PayRollProcessID=0 AND @Param_EmployeeIDs='')
	BEGIN
		ROLLBACK
			RAISERROR(N'Invalid Operation. Please Contact with vendor',16,1);
		RETURN
	END

	IF NOT EXISTS (SELECT * FROM PayrollProcessManagement WHERE PPMID=@Param_PayRollProcessID)
	BEGIN
		ROLLBACK
			RAISERROR(N'Invalid Process.Please Contact with vendor!!!',16,1)
		RETURN
	END
	IF EXISTS (SELECT * FROM PayrollProcessManagement WHERE [Status]=4 AND PPMID=@Param_PayRollProcessID)
	BEGIN
		ROLLBACK
			RAISERROR(N'Already freezed.!!!',16,1)
		RETURN
	END
	--Declare Local variable

	--for Department, Salary Scheme & SalaryHead
	DECLARE @tbl_Department AS TABLE (DepartmentID int)
	DECLARE @tbl_SalaryScheme AS TABLE (SalarySchemeID int)
	DECLARE @tbl_SalaryHead AS TABLE (SalaryHeadID int)
	DECLARE @tbl_Group AS TABLE (EmployeeTypeID int)


	--for update Production rate at EmployeeProduction
	DECLARE @tbl_PRate AS TABLE (EPSRDID int, ProductionRate decimal(30,17))

	-- drop temporary table. if found because of previous error temporary table may not dropped.
	IF OBJECT_ID('tempdb..#tbl_Employee') IS NOT NULL	BEGIN	DROP TABLE #tbl_Employee	END
	IF OBJECT_ID('tempdb..#tbl_EmployeeSalaryStructureDetail') IS NOT NULL BEGIN	DROP TABLE #tbl_EmployeeSalaryStructureDetail END
	IF OBJECT_ID('tempdb..#tbl_MonthlyAtt') IS NOT NULL	BEGIN	DROP TABLE #tbl_MonthlyAtt	END
	IF OBJECT_ID('tempdb..#tbl_EmployeeBasicSalary') IS NOT NULL BEGIN	DROP TABLE #tbl_EmployeeBasicSalary END
	IF OBJECT_ID('tempdb..#tbl_SchemeCondition') IS NOT NULL	BEGIN	DROP TABLE #tbl_SchemeCondition	END
	IF OBJECT_ID('tempdb..#tbl_AttBonusEligible') IS NOT NULL	BEGIN	DROP TABLE #tbl_AttBonusEligible	END
	IF OBJECT_ID('tempdb..#tbl_CompAttBonusEligible') IS NOT NULL BEGIN	DROP TABLE #tbl_CompAttBonusEligible END
	IF OBJECT_ID('tempdb..#tbl_EmpLeaveLedger') IS NOT NULL	BEGIN	DROP TABLE #tbl_EmpLeaveLedger	END
	IF OBJECT_ID('tempdb..#tbl_OT') IS NOT NULL BEGIN	DROP TABLE #tbl_OT END
	IF OBJECT_ID('tempdb..#tbl_BankInformation') IS NOT NULL	BEGIN	DROP TABLE #tbl_BankInformation	END	

	-- temporary table declaration
	CREATE TABLE  #tbl_Employee (EmployeeID int,ESSID int,ActualGrossAmount decimal(30,17),SalarySchemeID int,CompGrossAmount decimal(18,2),IsCashFixed bit,CashAmount decimal(18,2)
								,BasicAmount decimal(18,2),CompBasicAmount decimal(18,2),DateOfJoin Date,ShiftWorkingTime decimal(18,2))
	CREATE INDEX idx_#tbl_Employee ON #tbl_Employee (EmployeeID);
	/*
		There is some condition when inserting structure detail
		1. First Insert must paid amount those are not in any condition including addition and deduction
		2. Insert from disiplinary action (adition and deduction)
		3. Insert Conditional amount based on attendance
		4. Insert tax amount, PF and benefit on Attendance amount.

	*/
	CREATE TABLE  #tbl_EmployeeSalaryStructureDetail (EmployeeID int,SalaryHeadID int,Amount decimal(30,17),CompAmount decimal(18,2),SalaryHeadType smallint)
	CREATE INDEX idx_#tbl_EmployeeSalaryStructureDetail ON #tbl_EmployeeSalaryStructureDetail (EmployeeID,SalaryHeadID);

	CREATE TABLE  #tbl_MonthlyAtt (EmployeeID int,AttStartDate DATE,AttEndDate DATE,TotalDayOff int,TotalHoliday Int,TotalLeave int
											,TotalUpLeave int, TotalLate int, LateHourInMin int,TotalEarly int,TotalEarlyInMin int,TotalOTInMin int,TotalPresent int
											,CompTotalDayOff int,CompTotalHoliday Int,CompTotalLeave int
											,CompTotalLate int,CompLateHourInMin int, CompTotalEarly int,CompTotalEarlyInMin int,CompTotalOTInMin int,CompTotalPresent int,TotalAbsent int,CompTotalAbsent int)
	CREATE INDEX idx_#tbl_MonthlyAtt ON #tbl_MonthlyAtt (EmployeeID);

	CREATE TABLE  #tbl_EmployeeBasicSalary (EmployeeID int, BasicTypeAmount decimal(18,2),Addition decimal(18,2),Deduction decimal(18,2)
													,CompBasicTypeAmount decimal(18,2),CompAddition decimal(18,2),CompDeduction decimal(18,2))
	CREATE INDEX idx_#tbl_EmployeeBasicSalary ON #tbl_EmployeeBasicSalary (EmployeeID);


	CREATE TABLE #tbl_SchemeCondition (SalarySchemeID int,Condition smallint,FixedValue decimal(18,2),SalaryHeadID int,SalaryType smallint,LateCount int,FixedLateAmount decimal(18,2),EarlyCount int)
	CREATE INDEX idx_#tbl_SchemeCondition ON #tbl_SchemeCondition (SalarySchemeID,Condition);

	CREATE TABLE #tbl_AttBonusEligible (EmployeeID int)
	CREATE TABLE #tbl_CompAttBonusEligible (EmployeeID int)
	CREATE TABLE #tbl_EmpLeaveLedger (EmployeeID int,EmpLeaveLedgerID int,LeaveAmount int)

	CREATE TABLE #tbl_OT (EmployeeID Int, TotalOTHr decimal(18,2), OTRatePerHr decimal(18,2), CompTotalOThr decimal(18,2), CompOTRatePerHr decimal(18,2))
	CREATE INDEX idx_#tbl_OT ON #tbl_OT (EmployeeID);

	CREATE TABLE #tbl_BankInformation (EmployeeID Int, BankAccountID int)
	CREATE INDEX idx_#tbl_BankInformation ON #tbl_BankInformation (EmployeeID);



	DECLARE
	--for payroll Process
	@PV_PPM_LocationID as int
	,@PV_PPM_StartDate as date
	,@PV_PPM_EndDate as date
	,@PV_PPM_Month as int
	,@PV_Loan_SalaryHeadID as int
	,@PV_PPM_MonthDays as int
	,@PV_BaseAddress as varchar (100)
	,@PV_MonthCycleByCompany as int

	--new
	,@PV_Loan_SalaryHeadType as smallint
	,@PV_CompMonthCycleByCompany as int

	SET @PV_BaseAddress=(SELECT top(1)BaseAddress FROM Company)

	--Get & Set basic information from Payroll process management
	SELECT @PV_PPM_LocationID=LocationID,@PV_PPM_StartDate=SalaryFrom,@PV_PPM_EndDate=SalaryTo, @PV_PPM_Month=MonthID 
	FROM PayrollProcessManagement WHERE PPMID=@Param_PayRollProcessID



	--Insert Department those are attached with PayrollProcessManagement
	INSERT INTO @tbl_Department
	SELECT ObjectID FROM PayrollProcessManagementObject WITH (NOLOCK)
	WHERE PPMID=@Param_PayRollProcessID AND PPMObject=1/*DepartmentID*/

	--Insert SalaryScheme those are attached with PayrollProcessManagement
	INSERT INTO @tbl_SalaryScheme
	SELECT ObjectID FROM PayrollProcessManagementObject WITH (NOLOCK)
	WHERE PPMID=@Param_PayRollProcessID AND PPMObject=2/*SalaryScheme*/

	--Insert SalaryHead(Process Dependent) those are attached with PayrollProcessManagement
	INSERT INTO @tbl_SalaryHead
	SELECT ObjectID FROM PayrollProcessManagementObject WITH (NOLOCK)
	WHERE PPMID=@Param_PayRollProcessID AND PPMObject=3/*SalaryHead*/

	INSERT INTO @tbl_Group
	SELECT ObjectID FROM PayrollProcessManagementObject WITH (NOLOCK) 
	WHERE PPMID=@Param_PayRollProcessID AND PPMObject=4/*Group*/



	--Set MonthDAys
	SET @PV_PPM_MonthDays=DATEDIFF(DAY,@PV_PPM_StartDate,@PV_PPM_EndDate)+1
	SET @PV_MonthCycleByCompany=@PV_PPM_MonthDays
	SET @PV_CompMonthCycleByCompany=@PV_PPM_MonthDays
	IF @PV_BaseAddress IN ('ABC','XYX') BEGIN	SET @PV_MonthCycleByCompany=30 END
	IF @PV_BaseAddress IN ('ABC','XYZ') BEGIN	SET @PV_CompMonthCycleByCompany=30 END


	--Insert active running empoyee by conditions 
	IF ISNULL(@Param_EmployeeIDs,'')<>''
	BEGIN
		INSERT INTO #tbl_Employee 
				(EmployeeID		,ESSID			,ActualGrossAmount		,SalarySchemeID		,CompGrossAmount				,IsCashFixed	,CashAmount		,BasicAmount	,CompBasicAmount,DateOfJoin,ShiftWorkingTime)	
		SELECT	 top (500) ESS.EmployeeID	,ESS.ESSID		,ESS.ActualGrossAmount	,ESS.SalarySchemeID	,ISNULL(ESS.CompGrossAmount ,0)	,ISNULL(ESS.IsCashFixed,0),ISNULL(ESS.CashAmount,0)	,0			,0				,NULL		,0 			
		FROM EmployeeSalaryStructure ESS WITH(NOLOCK)  WHERE ESS.IsActive=1 AND ESS.StartDay=DAY(@PV_PPM_StartDate) AND ESS.ESSID IN (
		SELECT ESSID FROM EmployeeSalaryStructureDetail WITH (NOLOCK)) AND SalarySchemeID IN (
		SELECT SalarySchemeID FROM @tbl_SalaryScheme) AND EmployeeID IN (
		SELECT EmployeeID FROM EmployeeOfficial WITH(NOLOCK) WHERE --WorkingStatus IN (1,2,6)/*InWorkingPlace,OSD*/
		IsActive=1 AND DateOfJoin<=@PV_PPM_EndDate 
		AND EmployeeID IN (SELECT items FROm dbo.SplitInToDataSet(@Param_EmployeeIDs,','))
		AND EmployeeID NOT IN (	SELECT EmployeeID FROM EmployeeSalary WITH(NOLOCK) WHERE StartDate=@PV_PPM_StartDate)
		AND DRPID IN (	SELECT DepartmentRequirementPolicyID FROM DepartmentRequirementPolicy WHERE LocationId=@PV_PPM_LocationID 
		AND DepartmentID IN (SELECT DepartmentID FROM @tbl_Department))) 
	END ELSE BEGIN
		INSERT INTO #tbl_Employee 
				(EmployeeID		,ESSID			,ActualGrossAmount		,SalarySchemeID		,CompGrossAmount				,IsCashFixed	,CashAmount		,BasicAmount,CompBasicAmount,DateOfJoin,ShiftWorkingTime)
		SELECT	top (500) ESS.EmployeeID	,ESS.ESSID		,ESS.ActualGrossAmount	,ESS.SalarySchemeID	,ISNULL(ESS.CompGrossAmount ,0)	,ISNULL(ESS.IsCashFixed,0),ISNULL(ESS.CashAmount,0)	,0			,0				,NULL		,0
		FROM EmployeeSalaryStructure ESS WITH(NOLOCK)  WHERE ESS.IsActive=1 AND ESS.StartDay=DAY(@PV_PPM_StartDate) AND ESS.ESSID IN (
		SELECT ESSID FROM EmployeeSalaryStructureDetail WITH (NOLOCK)) AND SalarySchemeID IN (
		SELECT SalarySchemeID FROM @tbl_SalaryScheme) AND EmployeeID IN (
		SELECT EmployeeID FROM Employee WHERE IsActive=1 AND EmployeeID IN (
		SELECT EmployeeID FROM EmployeeOfficial WITH(NOLOCK) WHERE --WorkingStatus IN (1,2,6)/*InWorkingPlace,OSD*/
		IsActive=1 AND DateOfJoin<=@PV_PPM_EndDate 
		AND EmployeeID NOT IN (	SELECT EmployeeID FROM EmployeeSalary WITH(NOLOCK) WHERE StartDate=@PV_PPM_StartDate)
		AND DRPID IN (	SELECT DepartmentRequirementPolicyID FROM DepartmentRequirementPolicy WHERE LocationId=@PV_PPM_LocationID 
		AND DepartmentID IN (SELECT DepartmentID FROM @tbl_Department)))) 

		--Employee group is an optional criteria. So if there is any group then remove those employee who are not in this group table
		IF EXISTS (SELECT * FROM @tbl_Group)
		BEGIN
			DELETE FROM #tbl_Employee WHERE EmployeeID NOT IN (SELECT EmployeeID FROM EmployeeGroup EG WITH(NOLOCK) WHERE EG.EmployeeTypeID IN (
			SELECT EmployeeTypeID FROM @tbl_Group))
		END
	END

	--Check Employees availability in employee table		
	IF NOT EXISTS (SELECT * FROM #tbl_Employee)
	BEGIN
		GOTO Param_Index
	END


	--Insert in salary scheme condition
	/*
		There are some salary addition and deduction in salary scheme like AttendanceBonus, Absent Amount and so on. These addition and deduction occured based on some condition.
		 As example, if any employee attend full month, he will get bonus. There are 11 fixed Condition in our software.

			01. MonthlyFullAttendance- 	-Structure
			02. LWP						-SalaryScheme
			03. LeaveAllowance			-No Condition
			04. NoWorkAllowance			-No Condition
			05. Absent					-SalaryScheme
			06. Late					-SalaryScheme
			07. Early					-SalaryScheme
			08. NJ						-SalaryScheme
			09. SP						-SalaryScheme
			10. EducationFund			-SalaryScheme	
			11. Charity Fund			-SalaryScheme
	*/

	INSERT INTO #tbl_SchemeCondition (SalarySchemeID,Condition,FixedValue,SalaryHeadID,SalaryType,LateCount,FixedLateAmount,EarlyCount)
	SELECT SS.SalarySchemeID,SS.Condition 
	,CASE WHEN SS.Condition=1 THEN ISNULL((SELECT top(1)FixedValue FROM SalarySchemeDetailCalculation WITH(NOLOCK) WHERE SalarySchemeDetailID=SS.SalarySchemeDetailID),0) ELSE 0 END
	,SS.SalaryHeadID,SS.SalaryType,SSS.LateCount,SSS.FixedLatePenalty,SSS.EarlyLeavingCount
	FROM SalarySchemeDetail SS 
	INNER JOIN SalaryScheme SSS ON SS.SalarySchemeID=SSS.SalarySchemeID
	WHERE SS.Condition<>0 AND SS.SalarySchemeID IN (SELECT Emp.SalarySchemeID FROM #tbl_Employee Emp)
	Order By SS.SalarySchemeID,SS.Condition 


	--get monthly attendance sumary of those employees
	INSERT INTO #tbl_MonthlyAtt (EmployeeID ,AttStartDate ,AttEndDate ,TotalDayOff ,TotalHoliday ,TotalLeave 
								,TotalUpLeave , TotalLate , LateHourInMin ,TotalEarly ,TotalEarlyInMin ,TotalOTInMin ,TotalPresent 
								,CompTotalDayOff ,CompTotalHoliday ,CompTotalLeave 
								,CompTotalLate ,CompLateHourInMin , CompTotalEarly ,CompTotalEarlyInMin ,CompTotalOTInMin ,CompTotalPresent,TotalAbsent,CompTotalAbsent)

	SELECT EmployeeID,MIN(AttendanceDate),MAX(AttendanceDate)
	--Actual
	,SUM(CONVERT(INT,IsDayoff)) TotalDayoff
	,SUM(CONVERT(INT,IsHoliday)) TotalHoliday 
	,SUM(CONVERT(INT,IsLeave)) TotalLeave
	,SUM(CONVERT(INT,CASE WHEN IsLeave=1 AND IsUnPaid=1 THEN 1 ELSE 0 END)) TotalUPLeave
	,SUM(CASE WHEN LateArrivalMinute >0 THEN 1 ELSE 0 END) TotalLate
	,SUM(LateArrivalMinute) LateHourInMin
	,SUM(CASE WHEN EarlyDepartureMinute >0 THEN 1 ELSE 0 END) TotalEarly
	,SUM(EarlyDepartureMinute) TotalEarlyInMin
	,SUM(OverTimeInMinute) TotalOTInMin
	--,SUM(CASE WHEN CAST(InTime AS TIME(0))!='00:00:00' OR CAST(OutTime AS TIME(0))!='00:00:00' OR IsOSD =1 THEN 1 ELSE 0 END) TotalPresent
	,SUM(CASE WHEN IsDayOff=0 AND IsHoliday=0 AND IsLeave=0 AND (CAST(InTime AS TIME(0))!='00:00:00' OR CAST(OutTime AS TIME(0))!='00:00:00' OR IsOSD =1) THEN 1 ELSE 0 END) TotalPresent
	--Compliance
	,SUM(CONVERT(INT,IsCompDayOff)) CompTotalDayoff
	,SUM(CONVERT(INT,IsCompHoliday)) CompTotalHoliday 
	,SUM(CONVERT(INT,IsCompLeave)) CompTotalLeave
	--,SUM(CONVERT(INT,CASE WHEN IsLeave=1 AND IsUnPaid=1 THEN 1 ELSE 0 END)) TotalUPLeave
	,SUM(CASE WHEN CompLateArrivalMinute >0 THEN 1 ELSE 0 END) CompTotalLate
	,SUM(CompLateArrivalMinute) CompLateHourInMin
	,SUM(CASE WHEN CompEarlyDepartureMinute >0 THEN 1 ELSE 0 END) CompTotalEarly
	,SUM(CompEarlyDepartureMinute) CompTotalEarlyInMin
	,SUM(CompOverTimeInMinute) CompTotalOTInMin
	--,SUM(CASE WHEN CAST(CompInTime AS TIME(0))!='00:00:00' OR CAST(CompOutTime AS TIME(0))!='00:00:00' OR IsOSD =1 THEN 1 ELSE 0 END) CompTotalPresent
	,SUM(CASE WHEN IsCompDayOff=0 AND IsCompHoliday=0 AND IsCompLeave=0 AND (CAST(CompInTime AS TIME(0))!='00:00:00' OR CAST(CompOutTime AS TIME(0))!='00:00:00' OR IsOSD =1) THEN 1 ELSE 0 END) CompTotalPresent
	,0,0
	FROM AttendanceDaily WITH (NOLOCK) WHERE AttendanceDate BETWEEN @PV_PPM_StartDate AND @PV_PPM_EndDate AND EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee)
	GROUP By EmployeeID
	Order BY EmployeeID

	--update Absent amount (Actual and compliance)
	UPDATE #tbl_MonthlyAtt SET TotalAbsent=(DATEDIFF(DAY,AttStartDate,AttEndDate)+1-TotalPresent-TotalDayOff-TotalHoliday-TotalLeave-TotalUpLeave)
	,CompTotalAbsent=(DATEDIFF(DAY,AttStartDate,AttEndDate)+1-CompTotalPresent-CompTotalDayOff-CompTotalHoliday-CompTotalLeave)


	--SELECT * FROM #tbl_MonthlyAtt Order By EmployeeID

	--Insert unconditional salarystructure detail that an employee must get.
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,ESSD.SalaryHeadID,ESSD.Amount,ESSD.CompAmount,SD.SalaryHeadType FROM EmployeeSalaryStructureDetail ESSD WITH (NOLOCK) 
	INNER JOIN #tbl_Employee Emp ON ESSD.ESSID=Emp.ESSID
	INNER JOIN SalarySchemeDetail SCH WITH (NOLOCK) ON Emp.SalarySchemeID=SCH.SalarySchemeID AND ESSD.SalaryHeadID=SCH.SalaryHeadID AND SCH.Condition=0
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON ESSD.SalaryHeadID=SD.SalaryHeadID
	WHERE SD.SalaryHeadType IN (1,2,3,4) AND ISNULL(SD.IsProcessDependent,0)=0

	--UPDATE basic and comp basic to employee
	UPDATE #tbl_Employee SET BasicAmount= ISNULL((SELECT MAX(Amount) FROM #tbl_EmployeeSalaryStructureDetail ESSD WHERE ESSD.EmployeeID=Emp.EmployeeID),0)
						,CompBasicAmount= ISNULL((SELECT MAX(CompAmount) FROM #tbl_EmployeeSalaryStructureDetail ESSD WHERE ESSD.EmployeeID=Emp.EmployeeID),0)
	FROM #tbl_Employee Emp

	--Update Date of join to Employee
	UPDATE #tbl_Employee SET DateOfJoin=(SELECT EO.DateOfJoin FROM EmployeeOfficial EO WITH (NOLOCK) WHERE EO.EmployeeID=Emp.EmployeeID)
	FROM #tbl_Employee Emp

	--UPDATE shiftworking time
	UPDATE #tbl_Employee SET ShiftWorkingTime=(SELECT ISNULL(HS.TotalWorkingTime,0) FROM HRM_Shift HS WHERE HS.ShiftID IN (SELECT EO.CurrentShiftID FROM EmployeeOfficial EO WITH (NOLOCK) WHERE EO.EmployeeID=Emp.EmployeeID))
	FROM #tbl_Employee Emp


	--New Join
	IF EXISTS (SELECT * FROM #tbl_Employee Emp WHERE Emp.DateOfJoin>@PV_PPM_StartDate)
	BEGIN
		INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
		SELECT Emp.EmployeeID,SC.SalaryHeadID
		,CASE WHEN @PV_BaseAddress='ABC' THEN (Emp.ActualGrossAmount/30)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin)-1)
			WHEN @PV_BaseAddress='XYZ' THEN (Emp.BasicAmount/@PV_PPM_MonthDays)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin))		
			ELSE ((Emp.ActualGrossAmount+ISNULL(ESD.Amount,0))/@PV_PPM_MonthDays)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin))
		END 
		,CASE WHEN @PV_BaseAddress='ABC' THEN (Emp.CompGrossAmount/30)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin)-1)
			WHEN @PV_BaseAddress='XYZ' THEN (Emp.CompBasicAmount/@PV_PPM_MonthDays)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin))		
			ELSE ((Emp.CompGrossAmount+ISNULL(ESD.CompAmount,0))/@PV_PPM_MonthDays)*(DATEDIFF(DAY,@PV_PPM_StartDate,Emp.DateOfJoin))
		END 
		,SD.SalaryHeadType
		FROM #tbl_Employee Emp 
		INNER JOIN #tbl_SchemeCondition SC ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=8
		INNER JOIN SalaryHead SD ON SC.SalaryHeadID=SD.SalaryHeadID
		LEFT JOIN (SELECT ESD.EmployeeID,ISNULL(SUM(ESD.Amount),0) AS Amount,ISNULL(SUM(ESD.CompAmount),0) AS CompAmount FROM #tbl_EmployeeSalaryStructureDetail ESD WITH (NOLOCK) 
					WHERE ESD.SalaryHeadType=2/*Addition*/ GROUP BY ESD.EmployeeID)ESD ON emp.EmployeeID=ESD.EmployeeID
		WHERE Emp.DateOfJoin>@PV_PPM_StartDate
	END--New Join


	/*
		For Resign
		Generally, Employees are resigned by Employee Settlement and their salaries are processed saparetly. Resigned employees are not in this process.    
	*/


	--Insert disciplinary action to salary structure detail
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT DA.EmployeeID,DA.SalaryHeadID,SUM(DA.Amount),SUM(DA.CompAmount),SD.SalaryHeadType FROM DisciplinaryAction DA WITH (NOLOCK) 
	LEFT JOIN SalaryHead SD WITH(NOLOCK) ON DA.SalaryHeadID=SD.SalaryHeadID
	WHERE DA.ExecutedOn BETWEEN @PV_PPM_StartDate AND @PV_PPM_EndDate AND DA.ApproveBy>0
	AND DA.EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee)
	GROUP BY  DA.EmployeeID,DA.SalaryHeadID,SD.SalaryHeadType

	--PF amount that must be deducted 
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT PFM.EmployeeID, PFScheme.RecommandedSalaryHeadID
	,CASE WHEN PFScheme.RecommandedSalaryHeadID IS NOT NULL AND PFScheme.RecommandedSalaryHeadID>0 AND PFMC.Value>0 AND PFMC.CalculationOn>0 THEN
			CASE WHEN PFMC.CalculationOn=1 THEN ROUND (PFMC.Value*EMP.ActualGrossAmount/100,0)
				 WHEN PFMC.CalculationOn=2 THEN ROUND (PFMC.Value*Emp.BasicAmount/100,0) 
			ELSE 0 END
		ELSE 0 END AS PFAmount
		,0--Compliance Amount 
		,SD.SalaryHeadType
	FROM PFmember PFM WITH (NOLOCK)
	INNER JOIN #tbl_Employee EMP ON PFM.EmployeeID=EMP.EmployeeID
	LEFT JOIN PFMemberContribution PFMC WITH (NOLOCK) ON PFM.PFSchemeID =PFMC.PFSchemeID AND EMP.ActualGrossAmount BETWEEN PFMC.MinAmount AND PFMC.MaxAmount
	LEFT JOIN PFScheme  WITH (NOLOCK) ON PFScheme.PFSchemeID =PFMC.PFSchemeID 
	LEFT JOIN SalaryHead SD WITH (NOLOCK) ON PFScheme.RecommandedSalaryHeadID=SD.SalaryHeadID
	WHERE PFM.ApproveBy>0 AND PFM.IsActive=1


	--TAX deduction insert to Employee SAlary structure detail
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT ITD.EmployeeID,ITRS.SalaryHeadID,ITD.InstallmentAmount,0/*Comp amount*/,SD.SalaryHeadType FROM ITaxLedger ITD WITH (NOLOCK)
	INNER JOIN ITaxRateScheme ITRS WITH (NOLOCK) ON ITD.ITaxRateSchemeID=ITRS.ITaxRateSchemeID
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON ITRS.SalaryHeadID=SD.SalaryHeadID
	INNER JOIN ITaxAssessmentYear ITY WITH (NOLOCK) ON ITRS.ITaxAssessmentYearID=ITY.ITaxAssessmentYearID AND @PV_PPM_EndDate BETWEEN ITY.StartDate AND ITY.EndDate
	WHERE ITD.InactiveDate IS NULL AND EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee WITH (NOLOCK))

	----Loan Deduction
	SET @PV_Loan_SalaryHeadID=ISNULL((SELECT SalaryHeadID FROM EmployeeLoanSetup WITH(NOLOCK) WHERE InactiveBy=0),0)
	SET @PV_Loan_SalaryHeadType=ISNULL((SELECT SalaryHeadType FROM SalaryHead WITH(NOLOCK) WHERE SalaryHeadID=@PV_Loan_SalaryHeadID),0)

	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT EL.EmployeeID,@PV_Loan_SalaryHeadID,SUM(ELI.InstallmentAmount),0/*Comp amount*/,@PV_Loan_SalaryHeadType
	FROM EmployeeLoanInstallment ELI  WITH (NOLOCK)
	INNER JOIN EmployeeLoan EL WITH (NOLOCK) ON ELI.EmployeeLoanID=EL.EmployeeLoanID
	WHERE ELI.InstallmentDate BETWEEN @PV_PPM_StartDate AND @PV_PPM_EndDate AND (ELI.ESDetailID<=0 OR ELI.ESDetailID IS NULL) 
	GROUP BY EL.EmployeeID
	SET @PV_Loan_SalaryHeadID=ISNULL((SELECT SalaryHeadID FROM EmployeeLoanSetup WITH(NOLOCK) WHERE InactiveBy=0),0)

	----Advance Payment Actual
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT ES.EmployeeID, EAS.SararyHeadID,ES.NetAmount,0/*Comp*/,SD.SalaryHeadType 
	FROM EmployeeAdvanceSalary ES WITH (NOLOCK) 
	INNER JOIN EmployeeAdvanceSalaryProcess EAS WITH (NOLOCK) ON ES.EASPID=EAS.EASPID
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON EAS.SararyHeadID=SD.SalaryHeadID
	WHERE ES.EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee) 
	AND EAS.NYear=DATEPART(YEAR,@PV_PPM_EndDate) 
	AND EAS.NMonth=@PV_PPM_Month AND ApproveBy>0 AND SararyHeadID>0	

	----Advance Payment Compliance
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT ES.EmployeeID, EAS.SararyHeadID,0/*actual*/,ES.NetAmount,SD.SalaryHeadType 
	FROM EmployeeAdvanceSalaryCompliance ES WITH (NOLOCK) 
	INNER JOIN EmployeeAdvanceSalaryProcess EAS WITH (NOLOCK) ON ES.EASPID=EAS.EASPID
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON EAS.SararyHeadID=SD.SalaryHeadID
	WHERE ES.EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee) 
	AND EAS.NYear=DATEPART(YEAR,@PV_PPM_EndDate) 
	AND EAS.NMonth=@PV_PPM_Month AND ApproveBy>0 AND SararyHeadID>0	


	--Attendance Bonus 
	IF @PV_BaseAddress='ABC'
	BEGIN
		INSERT INTO #tbl_AttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.TotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate

		INSERT INTO #tbl_CompAttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.CompTotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate
	END ELSE IF @PV_BaseAddress='XYZ'
	BEGIN
		INSERT INTO #tbl_AttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.TotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate AND MA.TotalLeave<=0 AND MA.TotalUpLeave=0 AND MA.LateHourInMin<=5

		INSERT INTO #tbl_CompAttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.CompTotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate AND MA.CompTotalLeave<=0 AND MA.CompLateHourInMin<=5
	END ELSE BEGIN
		INSERT INTO #tbl_AttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.TotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate AND MA.TotalUpLeave=0 AND MA.TotalLeave=0

		INSERT INTO #tbl_CompAttBonusEligible (EmployeeID)
		SELECT MA.EmployeeID FROM #tbl_MonthlyAtt MA WITH (NOLOCK) WHERE MA.CompTotalAbsent<=0 AND MA.AttStartDate=@PV_PPM_StartDate AND MA.CompTotalLeave<=0
	END
 

	--Actual Attendance Bonus
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,SC.SalaryHeadID,CASE WHEN SC.SalaryType IN (1,2) THEN SC.FixedValue ELSE 0 END
	,0, SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH (NOLOCK)
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=1
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	WHERE Emp.EmployeeID IN (SELECT Att.EmployeeID FROM #tbl_AttBonusEligible Att WITH (NOLOCK))

	--Compliance Attendance Bonus
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,SC.SalaryHeadID,0
	,CASE WHEN SC.SalaryType IN (1,3) THEN SC.FixedValue ELSE 0 END, SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH (NOLOCK)
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=1
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	WHERE Emp.EmployeeID IN (SELECT Att.EmployeeID FROM #tbl_CompAttBonusEligible Att WITH (NOLOCK))


	--LWP Amount (Actual & Compliance)
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,SD.SalaryHeadID
	,CASE WHEN @PV_BaseAddress IN ('ABC') THEN MA.TotalUpLeave*Emp.ActualGrossAmount/@PV_MonthCycleByCompany 
			ELSE MA.TotalUpLeave*Emp.BasicAmount/@PV_MonthCycleByCompany END
	,CASE WHEN @PV_BaseAddress IN ('XYZ') THEN MA.TotalUpLeave*Emp.BasicAmount/@PV_MonthCycleByCompany ELSE 0 END
	,SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH(NOLOCK) 
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=2
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	INNER JOIN #tbl_MonthlyAtt MA WITH (NOLOCK) ON Emp.EmployeeID= MA.EmployeeID AND MA.TotalUpLeave>0


	--Absent Amount (Actual & Compliance)
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT tab.EmployeeID,tab.SalaryHeadID,tab.Amount,CASE WHEN tab.Amount>0 AND tab.CompAmount<=0 THEN tab.Amount ELSE tab.CompAmount END,tab.SalaryHeadType FROM (
	SELECT Emp.EmployeeID,SD.SalaryHeadID
	,CASE WHEN @PV_BaseAddress IN ('ABC') THEN MA.TotalAbsent*Emp.ActualGrossAmount/@PV_MonthCycleByCompany 
			ELSE MA.TotalAbsent*Emp.BasicAmount/@PV_MonthCycleByCompany END AS Amount
	,CASE WHEN @PV_BaseAddress IN ('XYZ') THEN MA.CompTotalAbsent*Emp.CompBasicAmount/30 
			ELSE 0 END AS CompAmount
	,SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH(NOLOCK) 
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=5
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	INNER JOIN #tbl_MonthlyAtt MA WITH (NOLOCK) ON Emp.EmployeeID= MA.EmployeeID AND (MA.TotalAbsent>0 OR MA.CompTotalAbsent>0))tab


	--Late Amount (Actual & Compliance)
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT * FROM (SELECT tab.EmployeeID,tab.SalaryHeadID,tab.Amount,CASE WHEN @PV_BaseAddress NOT IN ('ABC') AND tab.Amount>0 THEN tab.Amount ELSE 0 END AS CompAmount,tab.SalaryHeadType FROM (
	SELECT Emp.EmployeeID,SD.SalaryHeadID
	,CASE WHEN @PV_BaseAddress IN ('ABC') AND MA.TotalLate>=3 THEN ISNULL(AttBonus.Amount,0)+ (MA.TotalLate/SC.LateCount)*(Emp.ActualGrossAmount/@PV_MonthCycleByCompany)
			WHEN @PV_BaseAddress IN ('ABC') AND MA.TotalLate=2 THEN ISNULL(AttBonus.Amount,0)
			WHEN @PV_BaseAddress IN ('XYZ') AND MA.TotalLate BETWEEN 1 AND 2 THEN ISNULL(AttBonus.Amount,0)
			WHEN @PV_BaseAddress IN ('XYZ') AND MA.TotalLate/SC.LateCount>0 THEN (MA.TotalLate/SC.LateCount)*(Emp.ActualGrossAmount/@PV_MonthCycleByCompany)
			WHEN @PV_BaseAddress NOT IN ('ABC') AND SC.FixedLateAmount>0 AND (MA.TotalLate/SC.LateCount)>0 AND AttBonus.Amount>0 THEN  SC.FixedLateAmount
			WHEN @PV_BaseAddress NOT IN ('XYZ') AND ISNULL(SC.FixedLateAmount,0)<=0 AND (MA.TotalLate/SC.LateCount)>0 THEN  (MA.TotalLate/SC.LateCount)*(Emp.BasicAmount/@PV_MonthCycleByCompany)
			ELSE 0 END AS Amount
	,0 AS CompAmount
	,SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH(NOLOCK) 
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=6
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	INNER JOIN #tbl_MonthlyAtt MA WITH (NOLOCK) ON Emp.EmployeeID= MA.EmployeeID AND (MA.TotalLate>0 OR MA.CompTotalLate>0)
	LEFT JOIN (SELECT EmployeeID,SUM(Amount) AS Amount,SUM(CompAmount) AS CompAmount 
				FROM #tbl_EmployeeSalaryStructureDetail WHERE SalaryHeadID IN (SELECT SC.SalaryHeadID FROM #tbl_SchemeCondition SC WHERE SC.Condition=1)
				GROUP BY EmployeeID) AttBonus ON Emp.EmployeeID=AttBonus.EmployeeID)tab)tab_A WHERE tab_A.Amount>0 OR tab_A.CompAmount>0



	--SELECT tab.EmployeeID,tab.EmpLeaveLedgerID,MAX(tab.Balance) FROM (SELECT ELL.EmployeeID,ELL.EmpLeaveLedgerID 
	--,ELL.TotalDay- ISNULL((SELECT SUM(DATEDIFF(DAY,StartDateTime,EndDateTime)+1) FROM LeaveApplication WITH (NOLOCK) WHERE EmpLeaveLedgerID=ELL.EmpLeaveLedgerID 
	--AND ISNULL(CancelledBy,0)<=0 AND LeaveType=1 ),0) AS Balance
	--,MA.TotalLate/SC.LateCount as LCount
	--FROM EmployeeLeaveLedger ELL
	--INNER JOIN #tbl_MonthlyAtt MA WITH(NOLOCK) ON ELL.EmployeeID=MA.EmployeeID
	--INNER JOIN #tbl_Employee Emp WITH (NOLOCK) ON MA.EmployeeID=Emp.EmployeeID
	--INNER JOIN #tbl_SchemeCondition SC WITH(NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID
	--WHERE (MA.TotalLate/SC.LateCount)>0 AND ELL.ACSID IN (SELECT ACSID FROM AttendanceCalendarSession WHERE IsActive=1))tab WHERE tab.Balance>tab.LCount
	--GROUP BY tab.EmployeeID,tab.EmpLeaveLedgerID


	--Early Amount (Actual & Compliance)
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT * FROM (SELECT tab.EmployeeID,tab.SalaryHeadID,tab.Amount,CASE WHEN @PV_BaseAddress IN ('ABC') THEN 0 
																		WHEN @PV_BaseAddress NOT IN ('XYZ') AND tab.Amount>0 THEN tab.Amount ELSE 0 END AS CompAmount,tab.SalaryHeadType FROM (
	SELECT Emp.EmployeeID,SD.SalaryHeadID
	,CASE WHEN @PV_BaseAddress IN ('ABC') AND MA.TotalEarlyInMin>0 THEN (Emp.ActualGrossAmount*MA.TotalEarlyInMin)/(@PV_PPM_MonthDays*Emp.ShiftWorkingTime)
			WHEN @PV_BaseAddress IN ('XYZ') AND MA.TotalEarlyInMin>0 THEN (Emp.BasicAmount/1400)*MA.TotalEarlyInMin		
			WHEN @PV_BaseAddress NOT IN ('ABC','XYZ') AND MA.TotalEarlyInMin>0 THEN MA.TotalEarlyInMin*Emp.BasicAmount/@PV_MonthCycleByCompany		
			ELSE  0 END AS Amount
	,CASE WHEN @PV_BaseAddress IN ('XYZ') AND MA.CompTotalEarlyInMin>0 THEN (Emp.CompBasicAmount/1400)*MA.CompTotalEarlyInMin ELSE 0 END AS CompAmount
	,SD.SalaryHeadType
	FROM #tbl_Employee Emp WITH(NOLOCK) 
	INNER JOIN #tbl_SchemeCondition SC WITH (NOLOCK) ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=7
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID
	INNER JOIN #tbl_MonthlyAtt MA WITH (NOLOCK) ON Emp.EmployeeID= MA.EmployeeID AND (MA.TotalEarly>0 OR MA.CompTotalEarly>0)
	)tab)tab_A WHERE tab_A.Amount>0 OR tab_A.CompAmount>0


	IF @PV_BaseAddress ='ABC'
	BEGIN
		--Educational fund
		INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
		SELECT Emp.EmployeeID,SC.SalaryHeadID
		,CASE WHEN Emp.ActualGrossAmount BETWEEN 1 AND 19999 THEN 10
			WHEN Emp.ActualGrossAmount BETWEEN 20000 AND 39999 THEN 20
			ELSE 30 END AS Amount
		,0 AS CompAmount
		,SD.SalaryHeadtype FROM #tbl_Employee Emp
		INNER JOIN #tbl_SchemeCondition SC ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=999
		INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID

		--Rohingya Fund
		INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
		SELECT * FROM (SELECT Emp.EmployeeID,SC.SalaryHeadID
		,CASE WHEN Emp.ActualGrossAmount BETWEEN 10000 AND 12000 THEN 10
			WHEN Emp.ActualGrossAmount BETWEEN 12001 AND 15000 THEN 20
			WHEN Emp.ActualGrossAmount BETWEEN 15001 AND 20000 THEN 25
			WHEN Emp.ActualGrossAmount BETWEEN 20001 AND 30000 THEN 30
			WHEN Emp.ActualGrossAmount BETWEEN 30001 AND 50000 THEN 60
			WHEN Emp.ActualGrossAmount BETWEEN 50001 AND 75000 THEN 120
			WHEN Emp.ActualGrossAmount BETWEEN 75001 AND 100000 THEN 175
			WHEN Emp.ActualGrossAmount  > 100000 THEN 250
			ELSE 0 END AS Amount
		,0 AS CompAmount
		,SD.SalaryHeadtype FROM #tbl_Employee Emp
		INNER JOIN #tbl_SchemeCondition SC ON Emp.SalarySchemeID=SC.SalarySchemeID AND SC.Condition=10
		INNER JOIN SalaryHead SD WITH (NOLOCK) ON SC.SalaryHeadID=SD.SalaryHeadID)tab
	END--amg


	--OT Calculation and insert to Ot table 
	IF EXISTS (SELECT * FROM #tbl_MonthlyAtt WHERE (TotalOTInMin>0 OR CompTotalOTInMin>0))
	BEGIN
		INSERT INTO #tbl_OT (EmployeeID , TotalOTHr , OTRatePerHr , CompTotalOThr , CompOTRatePerHr )
		SELECT tab.EmployeeID,tab.TotalOTHr,CASE WHEN tab.OT_Value>0 AND tab.TotalOTHr>0 THEN ROUND(tab.OT_Value/tab.TotalOTHr,2) ELSE 0 END
		,tab.CompTotalOThr,CASE WHEN tab.CompOT_Value>0 AND tab.CompTotalOThr>0 THEN ROUND(tab.CompOT_Value/tab.CompTotalOThr,2) ELSE 0 END
		FROM (SELECT MA.EmployeeID,CONVERT(DECIMAL(18,2),MA.TotalOTInMin)/60 AS TotalOTHr
		,CASE WHEN SC.OverTimeOn=1/*gross*/ AND MA.TotalOTInMin>0 THEN (CONVERT(DECIMAL(18,2),MA.TotalOTInMin)/60) * ROUND((Emp.ActualGrossAmount/SC.DividedBy)* SC.MultiplicationBy,2)
			WHEN SC.OverTimeOn=2/*basic*/ AND MA.TotalOTInMin>0 THEN (CONVERT(DECIMAL(18,2),MA.TotalOTInMin)/60) * ROUND((Emp.BasicAmount/SC.DividedBy)* SC.MultiplicationBy,2)
			ELSE 0 END AS OT_Value
		,CONVERT(DECIMAL(18,2),MA.CompTotalOTInMin)/60 AS CompTotalOThr
		,CASE WHEN SC.CompOverTimeON=1/*gross*/ AND MA.CompTotalOTInMin>0 THEN (CONVERT(DECIMAL(18,2),MA.CompTotalOTInMin)/60) * ROUND((Emp.CompGrossAmount/SC.CompDividedBy)* SC.CompMultiplicationBy,2)
			WHEN SC.CompOverTimeON=2/*basic*/ AND MA.CompTotalOTInMin>0 THEN (CONVERT(DECIMAL(18,2),MA.CompTotalOTInMin)/60) * ROUND((Emp.CompBasicAmount/SC.CompDividedBy)* SC.CompMultiplicationBy,2)
			ELSE 0 END AS CompOT_Value
		FROM #tbl_MonthlyAtt MA WITH (NOLOCK)
		INNER JOIN #tbl_Employee Emp ON MA.EmployeeID=Emp.EmployeeID
		INNER JOIN SalaryScheme SC ON Emp.SalarySchemeID=SC.SalarySchemeID
		WHERE (MA.TotalOTInMin>0 OR MA.CompTotalOTInMin>0)
		AND ISNULL(SC.IsAllowOverTime,0)=1)tab
	END--OT

	/*******Benefits On Attendance********/	

	--For Actual
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,BO.SalaryHeadID, SUM(CASE WHEN BO.AllowanceOn=0 THEN BO.Value
												WHEN BO.AllowanceOn=1 THEN (Emp.ActualGrossAmount/@PV_MonthCycleByCompany)* BO.Value/100
												WHEN BO.AllowanceOn=2 THEN (Emp.BasicAmount/@PV_MonthCycleByCompany)* BO.Value/100
												ELSE 0 END)
	,0/*Comp*/,SD.SalaryHeadType
	FROM BenefitOnAttendanceEmployeeLedger BOL WITH (NOLOCK)
	INNER JOIN BenefitOnAttendanceEmployee BOA WITH (NOLOCK) ON BOL.BOAEmployeeID=BOA.BOAEmployeeID
	INNER JOIN BenefitOnAttendance BO WITH (NOLOCK) ON BOA.BOAID=BO.BOAID
	INNER JOIN #tbl_Employee Emp WITH (NOLOCK) ON BOA.EmployeeID=Emp.EmployeeID
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON BO.SAlaryHeadID=SD.SalaryHeadID
	WHERE BOL.AttendanceDate BETWEEN @PV_PPM_StartDate AND @PV_PPM_EndDate AND ISNULL(BO.IsExtraBenefit,0)=0 AND BO.SalaryHeadID>0 AND BO.IsComp=0
	GROUP BY Emp.EmployeeID,BO.SalaryHeadID,SD.SalaryHeadType

	--For Compliance
	INSERT INTO #tbl_EmployeeSalaryStructureDetail(EmployeeID,SalaryHeadID,Amount,CompAmount,SalaryHeadType)
	SELECT Emp.EmployeeID,BO.SalaryHeadID,0/*Actual*/, SUM(CASE WHEN BO.AllowanceOn=0 THEN BO.Value
												WHEN BO.AllowanceOn=1 THEN (Emp.ActualGrossAmount/@PV_MonthCycleByCompany)* BO.Value/100
												WHEN BO.AllowanceOn=2 THEN (Emp.BasicAmount/@PV_MonthCycleByCompany)* BO.Value/100
												ELSE 0 END)
	,SD.SalaryHeadType
	FROM BenefitOnAttendanceEmployeeLedger BOL WITH (NOLOCK)
	INNER JOIN BenefitOnAttendanceEmployee BOA WITH (NOLOCK) ON BOL.BOAEmployeeID=BOA.BOAEmployeeID
	INNER JOIN BenefitOnAttendance BO WITH (NOLOCK) ON BOA.BOAID=BO.BOAID
	INNER JOIN #tbl_Employee Emp WITH (NOLOCK) ON BOA.EmployeeID=Emp.EmployeeID
	INNER JOIN SalaryHead SD WITH (NOLOCK) ON BO.SAlaryHeadID=SD.SalaryHeadID
	WHERE BOL.AttendanceDate BETWEEN @PV_PPM_StartDate AND @PV_PPM_EndDate AND ISNULL(BO.IsExtraBenefit,0)=0 AND BO.SalaryHeadID>0 AND BO.IsComp=1
	GROUP BY Emp.EmployeeID,BO.SalaryHeadID,SD.SalaryHeadType
	/***************End BOA**********************/	

	--Employee Salary Detail summation
	INSERT INTO #tbl_EmployeeBasicSalary (EmployeeID,BasicTypeAmount,Addition,Deduction,CompBasicTypeAmount,CompAddition,CompDeduction)
	SELECT ESD.EmployeeID
	,SUM(CASE WHEN ESD.SalaryHeadType=1 THEN ISNULL(ESD.Amount,0) ELSE 0 END) AS BasicTypeAmount
	,SUM(CASE WHEN ESD.SalaryHeadType IN (2,4) THEN ISNULL(ESD.Amount,0) ELSE 0 END) AS Addition
	,SUM(CASE WHEN ESD.SalaryHeadType=3 THEN ISNULL(ESD.Amount,0) ELSE 0 END) AS Deduction
	,SUM(CASE WHEN ESD.SalaryHeadType=1 THEN ISNULL(ESD.CompAmount,0) ELSE 0 END) AS CompBasicTypeAmount
	,SUM(CASE WHEN ESD.SalaryHeadType IN (2,4) THEN ISNULL(ESD.CompAmount,0) ELSE 0 END) AS CompAddition
	,SUM(CASE WHEN ESD.SalaryHeadType=3 THEN ISNULL(ESD.CompAmount,0) ELSE 0 END) AS CompDeduction
	FROM #tbl_EmployeeSalaryStructureDetail ESD WITH (NOLOCK)
	GROUP BY ESD.EmployeeID


	--Insert Bank information
	INSERT INTO #tbl_BankInformation(EmployeeID,BankAccountID)
	SELECT EBA.EmployeeID, MAX(EBA.EmployeeBankACID) AS BankAccID FROM EmployeeBankAccount EBA WITH (NOLOCK) WHERE EBA.IsActive=1 AND EBA.EmployeeID IN (
	SELECT EmployeeID FROM #tbl_Employee)
	GROUP BY EmployeeID


	--Insert Employee salary ()
	SELECT tab.EmployeeID,DRP.LocationID,DRP.DepartmentID,EO.DesignationID,tab.ActualGrossAmount,ROUND(tab.NetAmount,0) AS NetAmount,1 AS Currency,GETDATE() AS ProcessDate,NULL
			,@Param_PayRollProcessID AS PPMID,0,@PV_PPM_StartDate AS StartDate,@PV_PPM_EndDate AS EndDate,1/*Lock*/,0,0/*Prod*/,OT.TotalOTHr,OT.OTRatePerHr,(DATEDIFF(DAY,MA.AttStartDate,MA.AttEndDate)+1-MA.TotalDayOff-MA.TotalHoliday) AS TotalWorkingDay
			,MA.TotalAbsent,MA.TotalLate,MA.TotalEarly,MA.TotalDayOff,MA.TotalUpLeave,MA.TotalLeave,0,0,0,0,@Param_DBUserID AS DBUserID,GETDATE(),MA.TotalHoliday,OT.CompTotalOThr,OT.CompOTRatePerHr
			,ROUND(tab.CompNetAmount,0) CompNetAmount,tab.CompGrossAmount,MA.LateHourInMin,MA.CompTotalAbsent,MA.CompTotalDayOff,MA.CompTotalHoliday,MA.CompTotalLeave
			,0,ISNULL(MA.CompTotalLate,0) AS CompTotalLate,MA.CompTotalEarly,MA.CompLateHourInMin,(DATEDIFF(DAY,MA.AttStartDate,MA.AttEndDate)+1-MA.CompTotalDayOff-MA.CompTotalHoliday) AS CompTotalWorkingDay
	,ROUND(CASE WHEN tab.FixedCashAmount>0 AND tab.NetAmount>tab.FixedCashAmount AND ISNULL(tab.BankAccountID,0)>0 THEN tab.NetAmount-tab.FixedCashAmount
			WHEN tab.FixedBankAmount>0 THEN tab.FixedBankAmount
			ELSE 0 END,0) AS BankAmount 
	,ROUND(CASE WHEN tab.FixedBankAmount<=0 AND tab.FixedCashAmount<=0 THEN tab.NetAmount 
			WHEN tab.FixedBankAmount>0 AND tab.NetAmount>tab.FixedBankAmount THEN tab.NetAmount-tab.FixedBankAmount		
			ELSE tab.FixedCashAmount END,0) AS CashAmount 
	,tab.BankAccountID
	,ROUND(CASE WHEN tab.CompFixedCashAmount>0 AND tab.CompNetAmount>tab.CompFixedCashAmount AND ISNULL(tab.BankAccountID,0)>0 THEN tab.CompNetAmount-tab.CompFixedCashAmount		
			WHEN tab.CompFixedBankAmount>0 THEN tab.CompFixedBankAmount
			ELSE 0 END,0) AS CompBankAmount 
	,ROUND(CASE WHEN tab.CompFixedBankAmount<=0 AND tab.CompFixedCashAmount<=0 THEN tab.CompNetAmount 
			WHEN tab.CompFixedBankAmount>0 AND tab.CompNetAmount>tab.CompFixedBankAmount THEN tab.CompNetAmount-tab.CompFixedBankAmount		
			ELSE tab.CompFixedCashAmount END,0) AS CompCashAmount 

	FROM (SELECT Emp.*,Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction AS NetAmount
	,CASE WHEN ISNULL(Bnk.BankAccountID,0)>0 AND ISNULL(Emp.IsCashFixed,0)=0 AND Emp.CashAmount>0 THEN (CASE WHEN Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction> Emp.CashAmount THEN Emp.CashAmount ELSE Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction END)
		WHEN ISNULL(Bnk.BankAccountID,0)>0 AND ISNULL(Emp.IsCashFixed,0)=0 AND ISNULL(Emp.CashAmount,0)=0 THEN Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction
		ELSE 0 END AS FixedBankAmount
	,CASE WHEN ISNULL(Emp.IsCashFixed,0)=1 AND ISNULL(Emp.CashAmount,0)>0 THEN (CASE WHEN Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction> Emp.CashAmount THEN Emp.CashAmount ELSE Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction END)
		WHEN ISNULL(Emp.IsCashFixed,0)=1 AND ISNULL(Emp.CashAmount,0)=0 THEN Emp.ActualGrossAmount+EBS.Addition -EBS.Deduction
		ELSE 0 END AS FixedCashAmount
	--Compliance
	,Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction AS CompNetAmount
	,CASE WHEN ISNULL(Bnk.BankAccountID,0)>0 AND ISNULL(Emp.IsCashFixed,0)=0 AND Emp.CashAmount>0 THEN (CASE WHEN Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction> Emp.CashAmount THEN Emp.CashAmount ELSE Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction END)
		WHEN ISNULL(Bnk.BankAccountID,0)>0 AND ISNULL(Emp.IsCashFixed,0)=0 AND ISNULL(Emp.CashAmount,0)=0 THEN Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction
		ELSE 0 END AS CompFixedBankAmount
	,CASE WHEN ISNULL(Emp.IsCashFixed,0)=1 AND ISNULL(Emp.CashAmount,0)>0 THEN (CASE WHEN Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction> Emp.CashAmount THEN Emp.CashAmount ELSE Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction END)
		WHEN ISNULL(Emp.IsCashFixed,0)=1 AND ISNULL(Emp.CashAmount,0)=0 THEN Emp.CompGrossAmount+EBS.CompAddition -EBS.CompDeduction
		ELSE 0 END AS CompFixedCashAmount
	,Bnk.BankAccountID
	FROM #tbl_Employee Emp WITH (NOLOCK)
	LEFT JOIN #tbl_EmployeeBasicSalary EBS WITH (NOLOCK) ON Emp.EmployeeID=EBS.EmployeeID
	LEFT JOIN #tbl_BankInformation Bnk WITH (NOLOCK) ON Emp.EmployeeID=Bnk.EmployeeID
	)tab 
	LEFT JOIN EmployeeOfficial EO WITH (NOLOCK) ON tab.EmployeeID=EO.EmployeeID
	LEFT JOIN DepartmentReQuirementPolicy DRP WITH (NOLOCK) ON EO.DRPID=DRP.DepartmentRequirementPolicyID
	LEFT JOIN #tbl_OT OT WITH (NOLOCK) ON tab.EmployeeID=OT.EmployeeID
	LEFT JOIN #tbl_MonthlyAtt MA WITH (NOLOCK) ON tab.EmployeeID=MA.EmployeeID
	--WHERE tab.EmployeeID=339
	Order BY tab.EmployeeID


	--Insert Details

	SELECT ES.EmployeeSalaryID,tab.SalaryHeadID,tab.Amount,tab.CompAmount,@Param_DBUserID,GETDATE(),tab.CompAmount 
	FROM (SELECT ESD.EmployeeID,ESD.SalaryHeadID,SUM(ISNULL(ESD.Amount,0)) AS Amount,SUM(ISNULL(ESD.CompAmount,0)) AS CompAmount FROM #tbl_EmployeeSalaryStructureDetail ESD
	GROUP BY ESD.EmployeeID,ESD.SalaryHeadID)tab
	LEFT JOIN EmployeeSalary ES WITH (NOLOCK) ON tab.EmployeeID=ES.EmployeeID AND ES.PayrollProcessID=@Param_PayRollProcessID
	WHERE ES.EmployeeID IN (SELECT EmployeeID FROM #tbl_Employee)


	--SELECT  * FROM EmployeeSalaryDetail WHERE EmployeeSalaryID=138143 Order By SalaryHeadID

	--SELECT ESD.*,SD.Name FROM #tbl_EmployeeSalaryStructureDetail ESD
	----LEFT JOIN EmployeeSalary ES WITH (NOLOCK)
	--LEFT JOIN SalaryHead SD ON ESD.SalaryHeadID=SD.SalaryHeadID
	-- WHERE ESD.EmployeeID=339 Order By SD.SalaryHeadID

	--SELECT * FROM #tbl_MonthlyAtt WHERE EmployeeID=339
	--SELECT * FROM #tbl_Employee WHERE EmployeeID=46


	--SELECT * FROM #tbl_EmployeeBasicSalary

	--SELECT * FROM #tbl_OT
	--SELECT * FROM #tbl_SchemeCondition SC WHERE SC.Condition=1
	--SELECT * FROM #tbl_EmployeeSalaryStructureDetail 
	--SELECT * FROM #tbl_MonthlyAtt WHERE EmployeeID=90809

	Param_Index:
	IF EXISTS (SELECT * FROM #tbl_Employee)
	BEGIN
		SET @Param_Index=500
	END ELSE BEGIN
		SET @Param_Index=0
	END
	
	SELECT @Param_Index

	DROP TABLE  #tbl_Employee
	DROP TABLE  #tbl_EmployeeSalaryStructureDetail
	DROP TABLE  #tbl_MonthlyAtt
	DROP TABLE  #tbl_EmployeeBasicSalary 
	DROP TABLE	#tbl_SchemeCondition
	DROP TABLE	#tbl_AttBonusEligible
	DROP TABLE	#tbl_CompAttBonusEligible
	DROP TABLE	#tbl_EmpLeaveLedger
	DROP TABLE	#tbl_OT
	DROP TABLE	#tbl_BankInformation

END




