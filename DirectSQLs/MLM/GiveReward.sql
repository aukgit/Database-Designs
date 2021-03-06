USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 4 Sep 2012
-- Description:	Give Away Rewar Money (64,000) to users and deploy other money in respective places.
-- =============================================
ALTER PROCEDURE [dbo].[GiveReward] 
	-- Add the parameters for the stored procedure here
      @EmpID	BIGINT,
      @EmpLog   VARCHAR(80),
      @RewardID UNIQUEIDENTIFIER ,
      @Notes VARCHAR(50) ,
      @RewardKey VARCHAR(5)
AS 
      BEGIN
			-- if nothing exist with this ID
            IF ( NOT EXISTS ( SELECT    RewardID
                              FROM      dbo.Reward
                              WHERE     Reward.RewardID = @RewardID AND Reward.RewardPaymentClear = 0 AND Reward.PromoteForReward = 1 ) ) 
               RETURN -1;
				
            SET NOCOUNT ON;
			-- check the connection types
            DECLARE @BonusFromFailedUser TINYINT = 1;
            DECLARE @BonusFromCompanyRewardPool TINYINT = 2;
            DECLARE @FailedUsersReapplySituation TINYINT = 3;
            DECLARE @RewardUserFailed TINYINT = 4; -- there will nothing with this.
            DECLARE @ConnectionStatus TINYINT;
            DECLARE @Service DECIMAL(18, 0);
            DECLARE @VAT DECIMAL(18, 0);
            DECLARE @PaidReward DECIMAL(18, 0);
            DECLARE @CompanyBonus DECIMAL(18, 0) = 0;
			DECLARE @PaidDate SMALLDATETIME = GETUTCDATE();
            DECLARE @PurchaseIDx	BIGINT ;
            DECLARE @MemberID	BIGINT ;
            DECLARE @IsCompanyGetBonus BIT;
            
			DECLARE @PaidRewardToUser TINYINT = 4;
			DECLARE @CollectInVATBox TINYINT = 8;
			DECLARE @CollectInServiceBox TINYINT = 9;
			DECLARE @CollectInRewardBox TINYINT = 10; -- company's reward pool box.
			
            
   
	
            SELECT TOP 1
                    @ConnectionStatus = RLV.ConnectionStatusID ,
                    @Service = RLV.ServiceCharge ,
                    @VAT = RLV.VAT,
                    @PaidReward = RLV.PaidReward,
                    @MemberID = RLV.RewardMemberID,                
                    @PurchaseIDx = RLV.PurchaseID,
                    @IsCompanyGetBonus = RLV.IsCompanyGetsBonus                   
            FROM    dbo.RewardListView AS RLV
            WHERE   RLV.RewardID = @RewardID AND RLV.RewardKey = @RewardKey;
            
				-- vat goes to vat account
				-- operating expense add
				-- service charge goes to its account.
				-- No company extra bonus.
				-- Revenue was previous added when collected the money so no new revenue.
				
				-- Service Charge 8,000
				EXEC dbo.AdditionToServiceBox 
				    @Amount = @Service; -- decimal
	
				
				-- VAT 8,000
				EXEC dbo.AdditionToVATBox 
				    @Amount = @VAT; -- decimal
				    
				-- Operating Expenses Add
				
				-- For Paid User.
				EXEC dbo.AddOperatingExpense 
				    @EmpID = @EmpID , -- bigint
				    @EmpLog = @EmpLog , -- varchar(80)
				    @MemberID = @MemberID , -- bigint
				    @Amount = @PaidReward , -- decimal
				    @PayTypeID = @PaidRewardToUser , -- tinyint
				    @Notes = @Notes , -- varchar(50)
				    @Dated = @PaidDate , -- smalldatetime
				    @PurchaseID = @PurchaseIDx ;-- bigint
				
				 -- Expense for VAT.
				EXEC dbo.AddOperatingExpense 
				    @EmpID = @EmpID , -- bigint
				    @EmpLog = @EmpLog , -- varchar(80)
				    @MemberID = @MemberID , -- bigint
				    @Amount = @VAT , -- decimal
				    @PayTypeID = @CollectInVATBox , -- tinyint
				    @Notes = NULL , -- varchar(50)
				    @Dated = @PaidDate , -- smalldatetime
				    @PurchaseID = @PurchaseIDx ; -- bigint
				
				-- Expense for Service.
				EXEC dbo.AddOperatingExpense 
				    @EmpID = @EmpID , -- bigint
				    @EmpLog = @EmpLog , -- varchar(80)
				    @MemberID = @MemberID , -- bigint
				    @Amount = @Service , -- decimal
				    @PayTypeID = @CollectInServiceBox , -- tinyint
				    @Notes = NULL , -- varchar(50)
				    @Dated = @PaidDate , -- smalldatetime
				    @PurchaseID = @PurchaseIDx ; -- bigint
            
            
            
            -- Only If Company Bonus True:
			-- Regular downlink , company gets service charge only
			-- But if company gets any bonus only if this users 
			-- downlink is from company's reward pool
            
            IF @IsCompanyGetBonus = 1 BEGIN
				SELECT TOP 1 @CompanyBonus = S.CompanyProfitFromRewardDownlink FROM dbo.Settings AS S 
				EXEC dbo.AdditionToCompanyRewardBox 
				    @Amount = @CompanyBonus -- decimal
				-- Expense for Service.
				EXEC dbo.AddOperatingExpense 
				    @EmpID = @EmpID , -- bigint
				    @EmpLog = @EmpLog , -- varchar(80)
				    @MemberID = @MemberID , -- bigint
				    @Amount = @CompanyBonus , -- decimal
				    @PayTypeID = @CollectInRewardBox , -- tinyint
				    @Notes = NULL , -- varchar(50)
				    @Dated = @PaidDate , -- smalldatetime
				    @PurchaseID = @PurchaseIDx ; -- bigint
            END

			UPDATE Reward SET RewardPaymentClear = 1,
							  PaidDate = @PaidDate,
							  RewardPaymentNotes = @Notes
			WHERE RewardID = @RewardID;
       END
