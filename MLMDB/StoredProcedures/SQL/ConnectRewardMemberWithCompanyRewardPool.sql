USE [MLM Db]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<MD.Alim Ul Karim , auk-port.webs.com>
-- Create date: <29-Jul-2012>
-- Description:	<Condition B , see the Reward Class>
-- =============================================
ALTER PROCEDURE [dbo].[ConnectRewardMemberWithCompanyRewardPool]
AS
	BEGIN
		SET NOCOUNT ON;
		
		DECLARE @RewardActsCount	bigint
		DECLARE @FailedActsCount	bigint
		DECLARE @RewardPoolID		bigint -- company's reward pool id
		DECLARE @UserTypeRewardPool int
		SET @RewardPoolID = -1;
		SET @UserTypeRewardPool = 6; --company's reward pool type.
		
		--DECLARE @CountTake			bigint
		--DECLARE	@IsTesting			bit

		--EXEC  @IsTesting = dbo.SettingsValue 'IsTesting';
		EXEC  @RewardActsCount = dbo.Counter dbo,RewardPromote;
		--EXEC  @FailedActsCount = dbo.Counter dbo,FailedBusiness;
		
		Select TOP 1 @RewardPoolID = m.MemberID FROM Member m Where UsersTypeID = @UserTypeRewardPool;
		
		IF (@RewardPoolID is null or @RewardPoolID < 2) BEGIN
			-- again create reward account.
			-- first reset the settings.
			  UPDATE dbo.Settings 
		      SET RewardAccountID = -1 
			  WHERE dbo.Settings.SettingsID = 1; 

			  -- now create reward account.
			EXEC  CreateRewardAccount;
			Select TOP 1 @RewardPoolID = m.MemberID FROM Member m Where UsersTypeID = @UserTypeRewardPool;
      
		END

		IF (@RewardActsCount > 0 AND (@RewardPoolID <> -1 OR @RewardPoolID IS NOT NULL)) BEGIN
		
			DECLARE @RewardID			uniqueidentifier
			DECLARE @RewardMemberID		bigint
			DECLARE @ConnectionStatus	tinyint -- 2 BonusFromCompanyRewardPool
			DECLARE @AssignDate			smalldatetime
			
			--DECLARE @it					bigint
			SET @ConnectionStatus = 2;-- 2 BonusFromCompanyRewardPool
			
			SET @AssignDate = GETUTCDATE();
			--SET @it = 0;
			
			
			DECLARE c1 CURSOR READ_ONLY 
			FOR 
			SELECT r.RewardPromoteID, r.MemberID from RewardPromote r Order By StoredDate
			OPEN c1

			FETCH NEXT FROM c1 INTO @RewardID,@RewardMemberID
			
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				
				-- Getting every failed member
				-- Get RewardMemberID
				---Select Top 1 @RewardID = r.RewardPromoteID, @RewardMemberID = r.MemberID from RewardPromote r Order By StoredDate;
				
				-- Create business code for this reward user under this failed user.
				EXEC dbo.CreateBusinessCode @RewardMemberID,1,@RewardPoolID,@ConnectionStatus,@AssignDate;
		
				DELETE FROM RewardPromote WHERE RewardPromoteID = @RewardID;
		
				FETCH NEXT FROM c1 INTO @RewardID,@RewardMemberID
			END

			CLOSE c1
			DEALLOCATE c1
		END
		
	
		
		
		
	END

