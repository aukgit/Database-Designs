USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 3 Sep 2012
-- Description:	Create Test Member
-- =============================================
ALTER PROCEDURE [dbo].[CreateTestPurchase]
	-- Add the parameters for the stored procedure here
       @ProductID INT = NULL ,
       @MemberID BIGINT = -1 ,
       @ProductDeliveryMethodID TINYINT = -1,
	   @ShowRoom Uniqueidentifier = null
AS 
       BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
             SET NOCOUNT ON;
             DECLARE @PaymentMethodID INT = 1;
             DECLARE @ProductBuy DECIMAL(18, 0)
             DECLARE @ProductSell DECIMAL(18, 0)
             DECLARE @ProductDue DECIMAL(18, 0)
             DECLARE @Advance DECIMAL(18, 0)
             DECLARE @WarrantyMonths INT = 1;
			
	
             IF ( @ProductID IS NULL OR @MemberID = -1 ) 
                RETURN -1;
	 
             IF @ProductDeliveryMethodID = -1 
                BEGIN
                      SET @ProductDeliveryMethodID = 3; -- Business Post Delivery
                END
	
             SELECT TOP 1
                    @Advance = PDM.ProductBookingMoney
             FROM   dbo.ProductDeliveryMethod AS PDM
			 WHERE PDM.ProductDeliveryMethodID = @ProductDeliveryMethodID ;
             
             SELECT TOP 1
					@ProductID = P.ProductID,
                    @ProductBuy = P.BuyingCost,
                    @ProductSell = P.SellingCost,  
					@WarrantyMonths = P.WarrentyMonths
             FROM   dbo.Product AS P;
             
             SET @ProductDue = @ProductSell - @Advance;
             
	
	
             INSERT INTO dbo.Purchase
                    ( ProductID ,
                      MemberID ,
                      ProductDeliveryMethodID ,
                      PaymentMethodID ,
                      ProductSellCost ,
                      ProductBuyCost ,
                      ProductPaymentDue ,
                      ProductPaymentPaid ,
                      ProductBookingMoney ,
                      DeliveryPaymentDue ,
                      DeliveryPaymentDueNotes ,
                      FailedDeliveryDue ,
                      FailedDeliveryDueNotes ,
                      BalancePayment ,
                      BalancePaymentNotes ,
                      SoldDated ,
                      BankID ,
                      BankBranchName ,
                      Account ,
                      ShowRoomID ,
                      TransactionEditorID ,
                      AdminEmployeeID ,
                      IsCollectedFromEditor ,
                      IsTransactionOccured ,
                      TransactionOccuredDate ,
                      IsProductDeliveried ,
					  WarrantyMonths)
             VALUES ( @ProductID , -- ProductID - int
                      @MemberID , -- MemberID - bigint
                      @ProductDeliveryMethodID , -- ProductDeliveryMethodID - tinyint
                      @PaymentMethodID , -- PaymentMethodID - int
                      @ProductSell , -- ProductSellCost - decimal
                      @ProductBuy , -- ProductBuyCost - decimal
                      @ProductDue , -- ProductPaymentDue - decimal
                      0 , -- ProductPaymentPaid - decimal
                      @Advance , -- ProductBookingMoney - decimal
                      0 , -- DeliveryPaymentDue - decimal
                      '' , -- DeliveryPaymentDueNotes - varchar(200)
                      0 , -- FailedDeliveryDue - decimal
                      '' , -- FailedDeliveryDueNotes - varchar(500)
                      0 , -- BalancePayment - decimal
                      '' , -- BalancePaymentNotes - varchar(200)
                      GETUTCDATE() , -- SoldDated - smalldatetime
                      NULL  , -- BankID - int
                      '' , -- BankBranchName - varchar(50)
                      '' , -- Account - varchar(80)
                      @ShowRoom , -- ShowRoomID - uniqueidentifier
                      0 , -- TransactionEditorID - bigint
                      0 , -- AdminEmployeeID - bigint
                      0 , -- IsCollectedFromEditor - bit
                      0 , -- IsTransactionOccured - bit
                      NULL , -- TransactionOccuredDate - date
                      0 , -- IsProductDeliveried - bit
                      @WarrantyMonths)
		RETURN @@IDENTITY;
	
       END
