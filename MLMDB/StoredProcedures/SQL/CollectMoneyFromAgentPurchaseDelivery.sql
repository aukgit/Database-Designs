USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 22 Sep 2012
-- Description:	Seal collection records from employee on second product delivery. PurchaseDelivery.IsCollected = 1 based on the user
-- =============================================
ALTER PROCEDURE [dbo].[CollectMoneyFromAgentPurchaseDelivery]
	-- Add the parameters for the stored procedure here
	   @CollectingEmpID BIGINT = NULL ,
	   @Notes VARCHAR(50),
	   @Amount DECIMAL,
	   @AdminID BIGINT = NULL ,
	   @AdminLog VARCHAR(80)
AS 

		DECLARE @Dated SMALLDATETIME = GETUTCDATE()
		--DECLARE @Amount DECIMAL
		
		--SELECT TOP 1 @Amount = PDCFE.Total FROM dbo.PurchaseDeliveryCollectionFromEmployee AS PDCFE
	   BEGIN
	
			 SET NOCOUNT ON;
	
	-- add a revenue
			 INSERT	INTO dbo.RevenueBox
					( RevenueBoxID ,
					  EditorID ,
					  Collected ,
					  Notes ,
					  Dated ,
					  PaymentTypeID )
			 VALUES	( NEWID() , -- RevenueBoxID - uniqueidentifier
					  @CollectingEmpID , -- EditorID - bigint
					  @Amount , -- Collected - decimal
					  @Notes , -- Notes - varchar(50)
					  @Dated , -- Dated - smalldatetime
					  2  -- PaymentTypeID - tinyint
					  )
					 
		-- sealing the records
		
		UPDATE dbo.PurchaseDelivery SET
				CollectedDate = @Dated,
				CollectedByEmployeeID = @AdminID,
				CollectedByEmployeeLog = @AdminLog,
				IsCollectedFromEmployee = 1
		WHERE 
				dbo.PurchaseDelivery.IsCollectedFromEmployee = 0 AND
				dbo.PurchaseDelivery.DeliveredByEmployeeID = @CollectingEmpID AND
				dbo.PurchaseDelivery.CollectedByEmployeeID IS NULL;
				
				
	   END
