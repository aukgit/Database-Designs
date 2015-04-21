USE [E:\WORKING\GITHUB\FLORALIMITEDTESTDRIVE\DATAACCESSLAYER\FLORASAMPLEDB.MDF]
GO
/****** Object:  StoredProcedure [dbo].[sp_get_over_times]    Script Date: 15-Apr-15 8:02:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim
-- Create date: 12 Mar 2015
-- Description:	OverTimeFind
-- =============================================
ALTER PROCEDURE [dbo].[sp_get_over_times] 
@officeHours					INT = 8
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @emp_id			VARCHAR(10);
	DECLARE @att_date		Date = NULL;
	DECLARE @att_time		SMALLDATETIME = NULL;
	DECLARE @status		    VARCHAR(4) = NULL;
	DECLARE @emp_id_2			VARCHAR(10) = NULL;
	DECLARE @att_date_2		DATE = NULL;
	DECLARE @status_2		    VARCHAR(4) = NULL;
	DECLARE @att_time_2		SMALLDATETIME = NULL;

	DECLARE @duration		int = NULL;

	DECLARE c1 CURSOR READ_ONLY 
			FOR 
			SELECT Emp_id,  Att_Date,Att_time
			FROM dbo.timesheet 
			WHERE STATUS = 'IN'
			GROUP BY Emp_id, Att_Date,Att_time
			OPEN c1
			FETCH NEXT FROM c1 INTO @emp_id,@att_date,@att_time
		
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				
					SELECT TOP 1 @emp_id_2 = Emp_id, @att_date_2 = Att_Date,  @att_time_2 = Att_time
					FROM dbo.timesheet 
					WHERE STATUS = 'OUT' AND Emp_id = @emp_id AND Att_Date = @att_date;
			
					IF(@emp_id_2 IS NOT NULL) BEGIN
						SET @duration = DATEDIFF(minute,@att_time,@att_time_2);
						IF(@duration < 0 ) BEGIN
							SET @duration = @duration * -1;
						END
						IF(@duration > @officeHours) BEGIN
						   SELECT @emp_id, (@duration- @officeHours) AS 'OverTime';              
						END                  
					END    
					SET @emp_id_2 = NULL;
					FETCH NEXT FROM c1 INTO   @emp_id,@att_date,@att_time
			END

			CLOSE c1
			DEALLOCATE c1

END
