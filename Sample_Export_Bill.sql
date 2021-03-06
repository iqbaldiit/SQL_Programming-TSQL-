/*
-- =============================================
-- Author:		Md. Masud Iqbal
-- Create date: 1 Nov 2017
-- Description:	This is a sample export bill as designed to my Procurement project. This process needs all required table existence to execute.
-- =============================================
*/

CREATE PROCEDURE [dbo].[SP_ExportBill]
(
    @Param_ExportBillID int,
    @Param_ExportBillNo VARCHAR(500),
    @Param_Amount Decimal(30,17),
    @Param_State smallint,
    @Param_StartDate DateTime,
    @Param_ExportLCID int,
	@Param_Note VARCHAR(500),
	@Param_NoOfPackages VARCHAR(512),
	@Param_NetWeight VARCHAR(512),
	@Param_GrossWeight VARCHAR(512),
	@Param_DBUserID int,
	@Param_DBOperation as smallint
)		
AS
BEGIN TRAN
DECLARE 
@DBServerDateTime as datetime,
@ExportBillHistoryID int,
@Param_NoteSystem VARCHAR(500),
@BillState_Prevoius as int,
@FileNo VARCHAR(500),
@ExportLCOpendate Datetime,

--- For LC status history
@ExportLCStatusLogID int,
@PrevioustStatus_LC int,
@CurrentStatus_LC int,
@Sequence int,

--- for auto No
@TempNo as VARCHAR(100),
@NumericPartInString as VARCHAR(5),
@NumericPart as int,
@YearPart as int,
@BUID as int

SELECT @BUID=BUID, @PrevioustStatus_LC=ISNULL(ExportLC.CurrentStatus,0),@FileNo=ISNULL(FileNo,0),@ExportLCOpendate=ExportLC.OpeningDate FROM ExportLC WHERE  ExportLCID=@Param_ExportLCID
SET @CurrentStatus_LC=5
SET @BillState_Prevoius=0
SET @DBServerDateTime=Getdate()


IF(@Param_DBOperation=1)
BEGIN
	IF NOT EXISTS (SELECT top(1)* FROM ExportPILCMapping WHERE  ExportLCID=@Param_ExportLCID ) 
	BEGIN
		ROLLBACK
			RAISERROR(N'Pi Yet not attach with this L/C!!~',16,1)
		RETURN
	END

	IF EXISTS (SELECT top(1)* FROM [ExportLC] WHERE Stability =0 and ExportLCID=@Param_ExportLCID)
	BEGIN
		ROLLBACK
			RAISERROR(N'This L/C Yet not Approved!!~',16,1)
		RETURN
	END
	IF(@Param_StartDate<CONVERT(DATE,'01 Jan 2000'))
	BEGIN
		ROLLBACK
			RAISERROR(N'Invalid Date.!!~',16,1)
		RETURN
	END

	SET @Param_ExportBillID=(SELECT ISNULL(MAX(ExportBill.ExportBillID),0)+1 FROM ExportBill)
	SET @Sequence=(SELECT ISNULL(MAX(Sequence),0)+1 FROM ExportBill WHERE ExportBill.ExportLCID=@Param_ExportLCID)

	SET @YearPart=SUBSTRING((SELECT DATENAME(YEAR,@DBServerDateTime)),3,2)
	SET @TempNo=ISNULL((SELECT CONVERT(VARCHAR,MAX([dbo].[SplitedStringGet](View_ExportBill.ExportBillNo, '/', 0))) FROM View_ExportBill   WHERE BUID=@BUID and  YEAR(View_ExportBill.StartDate)=YEAR(@Param_StartDate)),'')
	IF(@TempNo!='')
	BEGIN		
		SET @NumericPart=CONVERT(int,@TempNo)+1
		SET @NumericPartInString=RIGHT('0000' + CONVERT(VARCHAR, @NumericPart), 4)
		SET @Param_ExportBillNo=  @NumericPartInString+'/'+Convert(VARCHAR(500),@YearPart)
	END
	ELSE
	BEGIN
			SET @Param_ExportBillNo= '0001'+'/'+ Convert(VARCHAR(500),@YearPart)
	END	

	IF(EXISTS(SELECT top(1)* FROM View_ExportBill WHERE View_ExportBill.ExportBillNo=@Param_ExportBillNo and  BUID=@BUID and  View_ExportBill.ExportBillID!=@Param_ExportBillID))
	BEGIN
		ROLLBACK
			RAISERROR(N'This Invoice No already EXISTS.!!~',16,1)
		RETURN
	END

	INSERT INTO [dbo].[ExportBill]([ExportBillID],	[ExportBillNo],	[Amount],	[State],	[StartDate],	[ExportLCID],	[IsActive],	[DBUserID],	[DBServerDate],		Sequence,	NoOfPackages,		NetWeight,	GrossWeight)
							VALUES (@Param_ExportBillID,	@Param_ExportBillNo,	@Param_Amount,	@Param_State,		@Param_StartDate,		@Param_ExportLCID,	1,			@Param_DBUserID,	@DBServerDateTime,	@Sequence,	@Param_NoOfPackages,		@Param_NetWeight,	@Param_GrossWeight)
	UPDATE [ExportBill] SET Amount=(SELECT ISNULL(SUM((EBD.Qty/ISNULL(EBD.RateUnit,1))*EBD.UnitPrice),0) FROM View_ExportBillDetail AS EBD WHERE EBD.ExportBillID=@Param_ExportBillID)  WHERE ExportBillID=@Param_ExportBillID
	-------------Insert History-------
		
	SET @Param_NoteSystem='Document Prepare'
	SET @ExportBillHistoryID=(SELECT ISNULL(MAX(ExportBillHistory.ExportBillHistoryID),0)+1 FROM ExportBillHistory)
				
	IF NOT EXISTS (SELECT top(1)* FROM ExportBillHistory WHERE [State]=@Param_State and  ExportBillID=@Param_ExportBillID )
	BEGIN
		INSERT INTO [dbo].[ExportBillHistory]   ([ExportBillHistoryID]     ,[ExportBillID]  ,[State]  ,PreviousState   ,[Note] ,[NoteSystem] ,[DBServerDateTime]  ,[DBUserID])
										VALUES   (@ExportBillHistoryID     ,@Param_ExportBillID   ,@Param_State,  @BillState_Prevoius,@Param_Note , @Param_NoteSystem ,@DBServerDateTime    ,@Param_DBUserID)
	END
	ELSE
	BEGIN
		UPDATE ExportBillHistory  SET [ExportBillID]=@Param_ExportBillID ,[State]=@Param_State ,[Note]=@Param_Note ,[NoteSystem]=@Param_NoteSystem ,[DBUserID]=@Param_DBUserID ,[DBServerDateTime]=@DBServerDateTime WHERE  [State]=@Param_State and  ExportBillID=@Param_ExportBillID 
	END
	-------------------------------

	----------------------Insert Export LCStatus History
	--OutstandingLC = 5,//
	IF(ISNULL(@PrevioustStatus_LC,0)!=5)
	BEGIN
		SET @ExportLCStatusLogID=(SELECT ISNULL(MAX(ExportLCStatusLog.ExportLCStatusLogID),0)+1 FROM ExportLCStatusLog)		
		INSERT INTO [dbo].[ExportLCStatusLog]	([ExportLCStatusLogID],	[ExportLCID],	[PreviousStatus],	[CurrentStatus],	[Note],				[DBUserID],	[DBServerDateTime])
										VALUES	(@ExportLCStatusLogID,	@Param_ExportLCID,	@PrevioustStatus_LC, @CurrentStatus_LC,	'Bill Received',	@Param_DBUserID,	@DBServerDateTime)
	END
	Else
	BEGIN
		SET @ExportLCStatusLogID=ISNULL((SELECT Top(1)ExportLCStatusLog.ExportLCStatusLogID FROM ExportLCStatusLog WHERE CurrentStatus=5 and ExportLCID in (SELECT ExportLCID FROM ExportBill WHERE ExportBillID=@Param_ExportBillID ) order by ExportLCStatusLogID DESC),0)
		UPDATE ExportLCStatusLog SET [DBServerDateTime]= @DBServerDateTime, Note='Bill Received', [DBUserID]= @Param_DBUserID WHERE  ExportLCStatusLog.ExportLCID=@Param_ExportLCID and [CurrentStatus]=@CurrentStatus_LC and ExportLCStatusLogID=@ExportLCStatusLogID
	END

	UPDATE ExportLC SET CurrentStatus=@CurrentStatus_LC WHERE [ExportLCID]=@Param_ExportLCID
	SELECT * FROM View_ExportBill WHERE ExportBillID= @Param_ExportBillID
END

IF(@Param_DBOperation=2)
BEGIN
	IF(@Param_ExportBillID<=0)
	BEGIN
		ROLLBACK
			RAISERROR (N'Your SELECTed Product Is Invalid Please Refresh and try again!!',16,1);	
		RETURN
	END	
	UPDATE ExportBill   SET ExportBillNo=@Param_ExportBillNo,		Amount=@Param_Amount,		[State]=@Param_State,		StartDate=@Param_StartDate,	ExportLCID =@Param_ExportLCID,	DBUserID=@Param_DBUserID,	DBServerDate=@DBServerDateTime, NoOfPackages=@Param_NoOfPackages,		NetWeight=@Param_NetWeight,	GrossWeight=@Param_GrossWeight 	WHERE ExportBillID= @Param_ExportBillID
	UPDATE [ExportBill] SET Amount=(SELECT ISNULL(SUM((EBD.Qty/ISNULL(EBD.RateUnit,1))*EBD.UnitPrice),0) FROM View_ExportBillDetail AS EBD WHERE EBD.ExportBillID=@Param_ExportBillID)  WHERE ExportBillID=@Param_ExportBillID

	SET @Param_NoteSystem='Document Prepare'
	SET @ExportBillHistoryID=(SELECT ISNULL(MAX(ExportBillHistory.ExportBillHistoryID),0)+1 FROM ExportBillHistory)
			
	IF NOT EXISTS (SELECT top(1)* FROM ExportBillHistory WHERE [State]=@Param_State and  ExportBillID=@Param_ExportBillID )
	BEGIN
		INSERT INTO [dbo].[ExportBillHistory]   ([ExportBillHistoryID]     ,[ExportBillID]  ,[State]  ,PreviousState   ,[Note] ,[NoteSystem] ,[DBServerDateTime]  ,[DBUserID])
										VALUES  (@ExportBillHistoryID     ,@Param_ExportBillID   ,@Param_State,  @BillState_Prevoius,@Param_Note , @Param_NoteSystem ,@DBServerDateTime    ,@Param_DBUserID)
	END
	ELSE
	BEGIN
		UPDATE ExportBillHistory  SET [ExportBillID]=@Param_ExportBillID ,[State]=@Param_State ,[Note]=@Param_Note ,[NoteSystem]=@Param_NoteSystem ,[DBUserID]=@Param_DBUserID ,[DBServerDateTime]=@DBServerDateTime WHERE  [State]=@Param_State and  ExportBillID=@Param_ExportBillID 
	END
	SELECT * FROM View_ExportBill WHERE ExportBillID= @Param_ExportBillID
END

IF(@Param_DBOperation=3)
BEGIN
	IF(@Param_ExportBillID<=0)
	BEGIN
		ROLLBACK
			RAISERROR (N'Your SELECTed Product Is Invalid Please Refresh and try again!!',16,1);	
		RETURN
	END
	IF EXISTS (SELECT * FROM ExportLDBC WHERE ExportBillID=@Param_ExportBillID)
	BEGIN
		ROLLBACK
			RAISERROR (N'Deletion not possible, Bank Negotiation create. LDBC No Already received  !!',16,1);	
		RETURN
	END
	SET @Sequence=(SELECT  ExportBill.Sequence FROM ExportBill WHERE ExportBillID=@Param_ExportBillID)
	SET @Param_ExportLCID=(SELECT  ExportBill.ExportLCID FROM ExportBill WHERE ExportBillID=@Param_ExportBillID)
	IF EXISTS(SELECT * FROM ExportBill WHERE Sequence>ISNULL(@Sequence,0) and  ExportLCID=@Param_ExportLCID)
	BEGIN
		ROLLBACK
			RAISERROR (N'Delation not possible,You can delete Sequence wise !!~',16,1);	
		RETURN
	END
	SET @ExportLCStatusLogID=ISNULL((SELECT Top(1)ExportLCStatusLog.ExportLCStatusLogID FROM ExportLCStatusLog WHERE CurrentStatus=5 and ExportLCID in (SELECT ExportLCID FROM ExportBill WHERE ExportBillID=@Param_ExportBillID ) order by ExportLCStatusLogID DESC),0)
	DELETE FROM ExportBill  WHERE ExportBillID= @Param_ExportBillID
	DELETE FROM ExportBillDetail  WHERE ExportBillID= @Param_ExportBillID
	DELETE FROM ExportBillHistory  WHERE ExportBillID= @Param_ExportBillID
	Delete FROM ExportLCStatusLog WHERE ExportLCStatusLog.ExportLCStatusLogID=@ExportLCStatusLogID
	UPDATE [ExportBill] SET Amount=(SELECT ISNULL(SUM((HH.Qty/ISNULL(HH.RateUnit,1))*HH.UnitPrice),0) FROM View_ExportBillDetail AS HH WHERE HH.ExportBillID=@Param_ExportBillID)  WHERE ExportBillID=@Param_ExportBillID
END
COMMIT TRAN