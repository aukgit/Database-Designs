USE [MLM Db]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 31 Aug 2012
-- Description:	Collect Money From Agent to Company, 
--              put the IsCollectedFromEditor = true and collect it in the revenue box. 
-- =============================================
ALTER PROCEDURE [dbo].[CollectMoneyFromAgent] 
	-- Add the parameters for the stored procedure here
      @AgentID				BIGINT = -1 ,
	  @CollectedAdminID		BIGINT = -1 ,
      @Notes				VARCHAR(50) = NULL
AS 
      BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
            SET NOCOUNT ON;
            DECLARE @Collection				DECIMAL(18, 0);
			DECLARE @CollectMoneyFromAgent	TINYINT = 2;
            IF ( @AgentID <> -1 ) 
               BEGIN
					 --Got Collection
                     SELECT @Collection = ETR.TotalCollection
                     FROM   EmployeeTransactionRecords ETR
                     WHERE  EditorID = @AgentID;
					 
					  --Add Revenue
                     INSERT INTO dbo.RevenueBox
                            ( RevenueBoxID ,
                              EditorID ,
                              Collected ,
                              Notes,
                              Dated,
                              PaymentTypeID )
                     VALUES ( NEWID() , -- RevenueBoxID - uniqueidentifier
                              @AgentID , -- EditorID - bigint
                              @Collection , -- Collected - decimal
                              @Notes,  -- Notes - varchar(50)
                              GETUTCDATE(),
                              @CollectMoneyFromAgent);
                     
                      --Seal the money.   
                     UPDATE dbo.Purchase
                     SET    IsCollectedFromEditor = 1 ,
                            TransactionOccuredDate = GETUTCDATE(),
							AdminEmployeeID	= @CollectedAdminID
                     WHERE  dbo.Purchase.TransactionEditorID = @AgentID AND IsCollectedFromEditor = 0;                      
               END
      END
