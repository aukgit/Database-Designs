USE [MLM Db]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 26 Aug 2012
-- Description:	Creating Downlink In the Reward table.
-- =============================================
ALTER PROCEDURE [dbo].[CreateDownlink] 
	-- Add the parameters for the stored procedure here
    @ParentMemberID				BIGINT = -1 ,
    @ChildMemberID				BIGINT = -1 ,
    @ConnectionStatus			TINYINT = NULL,
    @IsFailedRecovery			BIT,
    @RewardAcc					BIGINT 
AS 
    BEGIN
	-- If any of the id missing or if the same record already exist then do nothing
        IF ( @RewardAcc = -1 OR @ParentMemberID = -1
             OR @ChildMemberID = -1
             OR EXISTS ( SELECT *
                         FROM   dbo.Reward r
                         WHERE  r.ImmediateChildID = @ChildMemberID
                                AND r.MemberID = @ParentMemberID )
           ) 
            BEGIN
                RETURN -1;
            END	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
        DECLARE @email VARCHAR(256);
        DECLARE @logname VARCHAR(80);
        DECLARE @FullName VARCHAR(80);
        DECLARE @company VARCHAR(80);
        DECLARE @EmailSubject VARCHAR(550);
        DECLARE @Serial INTEGER;
        DECLARE @IsCreatedMemberCount INT;
        DECLARE @Count INT;
	
	
	---- Declare Types for Connection Status
	
        DECLARE @BonusFromFailedUser TINYINT = 1;
        DECLARE @BonusFromCompanyRewardPool TINYINT = 2;
        DECLARE @FailedUsersReapplySituation TINYINT = 3;
        DECLARE @RewardUserFailed TINYINT = 4;
	
	
	/*
		Fulfill those conditions aspects on the MemberExtendedMdoel->putdefaultsvalues section.
         * 
         * 1. Failed Users in DayLimit: 15 {F}
         * 2. Reward Users who have successfully sold their all 3 business codes. {A}
         * 
         * >>>Condition A
         * Now reward users will have a new business code extra.
         * First this extra code will be connected under that failed user , 
         * if any exist. So for that new business code and failed user 
         * Temp Business Code table:
         * SponsorID : Still that same failed guy(F) but RewardAccountID will be the
         * Reward Guy(A). In addition, ConnectionStatusID: 1
         * 
         * ******(Schedule)
         * Summary (Failed users):
         * SponsorID : Still that same failed guy(F)
         * RewardAccountID: A
         * ConnectionStatusID: 1 (Bonus business code is from a user who had failed to sold their business code in time. This reward is for person who has succeeded to sell all codes in time.( same downlink profit as other from this. ))
         * Code will be visible to A.
         * 
         * *****Failed Sequence****:
         * If it fails then keep the failed user,
         * but don't keep the reward user in the failed user list
         * and reward user will not get any new reward in the future.
         * 
         * 
         * >>>Condition B
         * Now if there is no failed form and then new bonus code will be
         * linked with company's reward pool account.
         * This time sponsor will be {A} but RewardAccountID will be company's
         * reward pool account. In addition, ConnectionStatusID: 2.
         * 
         * In both case the new business code should be linked with {A}
         * 
         * ******(Schedule)
         * Summary (Reward from Company):
         * SponsorID:A
         * RewardAccountID: Company Reward pool.
         * ConnectionStatusID: 2 (Bonus code is from company's reward pool. Company will be the owner of this downlink business.This reward is for person who has succeeded to sell all codes in time.( same downlink profit as other from this. ).)
         * Code will be visible to A.
         * 
         * *****Failed Sequence****:
         * If it fails then don't keep the reward user as failed user,
         * but reward user will not get any new reward in the future.
         * 
         * 
         * 
         * >>>Condition C         * 
         * Now if failed user apply again then he/she will be connected
         * with company's reward pool account. In that case, 
         * SponsorID:F , RewardAccountID: Company Reward Pool.
         * ConnectionStatusID: 3
         * 
         * ******(Manual)
         * Summary(Failed Users Reapply - For business code):
         * SponsorID:F
         * RewardAccountID: Company Reward Pool ( It is correct there is no need to involved the parent . Because he/she will be the parent of this selling business code)
         * ConnectionStatusID: 3 (Current code is from company's reward pool(not a bonus). Company will be the owner of this downlink business.This for the person who has failed to sell all codes in time.( but same downlink profit as other from this. ))
         * Code will be visible to F.
         * 
         * *****Failed Sequence****:
         * ***** Server will not keep the failed return code if again 
         * failed because there is no serious link. The link was already handled by the reward guys.
         * 
	*/
	
	-- So if previous conditions are not successfull then it will come to this far.
	
	-- So first update the parent's Created Downlinks Count.
	/*
	UPDATE [Member] SET 
		[Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1 , 
		[Member].[ConnectionStatusID] = @ConnectionStatus 
		WHERE MemberID = @ParentMemberID;
	*/
	-- Corrected One :  @ ConnectionStatusID will not be updated because then it would be redundant
    -- In member Table Updating Downlinks
    IF(@ConnectionStatus IS NULL) BEGIN
		-- if regular link.
		UPDATE  [Member]
		SET     [Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1  
		--[Member].[ConnectionStatusID] = @ConnectionStatus , this has been set in the PutDefaultValues Functins from the businesscode layer.
		WHERE   MemberID = @ParentMemberID;
	END 
	ELSE IF(@IsFailedRecovery = 1 AND @IsFailedRecovery IS NOT NULL) BEGIN
		-- if reapply connected with a failed user
		IF @ConnectionStatus = 1 BEGIN -- Reapplly connects with failed
		/*
		- 1. @BonusFromFailedUser ( In Business Code Table ) / On Failed User Reapply If connected with a failed form.::
		-		SponsorID(Parent): Previous Sponsor
		-		MemberID: NULL ( be set when created )
		-		ConnectionStatus: @BonusFromFailedUser(1)
		-		**RewardAccountID: This Reward Guy's ID. You
		-		No further changes in business.
		-		IsFailedRecovered = 1 ( Same will be applied in the Reward Table )
		*/
			UPDATE  [Member]
			SET     [Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1  
			WHERE   MemberID = @RewardAcc;
		END
		ELSE IF @ConnectionStatus = 3 BEGIN -- reapply connects with reward pool.
			UPDATE  [Member]
			SET     [Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1  
			WHERE   MemberID = @ParentMemberID;
		END
		
	END
	ELSE IF  (@IsFailedRecovery = 0 OR @IsFailedRecovery IS NULL) AND  @ConnectionStatus IS NOT NULL BEGIN
		IF @ConnectionStatus = 1 BEGIN -- Failed Reward
			UPDATE  [Member]
			SET     [Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1  
			WHERE   MemberID = @RewardAcc;
		END
		ELSE IF  @ConnectionStatus = 2 BEGIN -- Connected with reward pool
			UPDATE  [Member]
			SET     [Member].[CreatedDownlinks] = [Member].[CreatedDownlinks] + 1  
			WHERE   MemberID = @ParentMemberID;
		END
		
	END
	-- Getting email.
        SELECT TOP 1
                @Email = M.Email ,
                @logname = M.LogName ,
                @FullName = M.FullName
        FROM    dbo.Member AS M
        WHERE   M.MemberID = @ParentMemberID;
	
	
	-- Getting Company Name.
        SELECT TOP 1
                @company = S.CompanyName
        FROM    dbo.Settings S;
	
        SELECT  @EmailSubject = '[' + @company
                + '] Congratulations! One of your business code has been created a successfull business account.';
		
        EXEC dbo.CreateEmailPending 
            @EmailCategoryID = 7 , -- Downlink Created
            @Email = @email , -- varchar(256)
            @EmailSubject = @EmailSubject ,
            @MemberID = @ParentMemberID , -- bigint
            @LogName = @logname , -- varchar(255)
            @FullName = @FullName; -- varchar(256)

		-- Getting Downlink Serail
        SET @Serial = 1;
	
		-- If any downlink exist then generate serail
        IF EXISTS ( SELECT  *
                    FROM    dbo.Reward AS R
                    WHERE   R.MemberID = @ParentMemberID ) BEGIN
            SELECT TOP 1
                    @Serial += R.DownlinkSerial
            FROM    dbo.Reward AS R
            WHERE   R.MemberID = @ParentMemberID
            ORDER BY R.DownlinkSerial DESC;
		END
		
		
		-- Creating Reward Item (Downlink).
        EXEC dbo.InsertReward 
            @MemberID = @ParentMemberID , -- bigint
            @ChildID = @ChildMemberID , -- bigint
            @Serial = @Serial , -- int
            @ConnectionStatus = @ConnectionStatus,
            @IsFailedRecover = @IsFailedRecovery ,
            @RewardAccID = @RewardAcc; -- tinyint
	
	-- check if hypothetical syllolisgm exist.
	/*	MID    ImdID
		1		2 <-- Hypo 1
		1		3
		1		4
		2		6 <-- Hypo 2 ( Create by this becuase 
		this will be the main imediate id count for this MID 1 and ImdID 2.
		We will count this and put it in the Count Field.)
	*/
	
	--This is going to same for all users
    IF EXISTS ( SELECT  *
                FROM    dbo.Reward AS R
                WHERE   R.ImmediateChildID = @ParentMemberID ) 
        BEGIN
		-- Hypo sllyo exist.			
            EXEC @IsCreatedMemberCount = dbo.AddMembersToMembersCount 
                @MemberID = @ParentMemberID , -- bigint
                @ChildID = @ChildMemberID; -- bigint		
                
           SELECT @IsCreatedMemberCount;
        END



	/*
		- 1. @BonusFromFailedUser ( In Business Code Table )::
		-		SponsorID(Parent): Previous Sponsor
		-		MemberID: NULL ( be set when created )
		-		ConnectionStatus: @BonusFromFailedUser(1)
		-		**RewardAccountID: This Reward Guy's ID.
		-		No further changes in business.
		-		IsFailedRecovered = NULL
		
		- 1. @BonusFromFailedUser ( In Business Code Table ) / On Failed User Reapply If connected with a failed form.::
		-		SponsorID(Parent): Previous Sponsor
		-		MemberID: NULL ( be set when created )
		-		ConnectionStatus: @BonusFromFailedUser(1)
		-		**RewardAccountID: This Reward Guy's ID.
		-		No further changes in business.
		-		IsFailedRecovered = 1 ( Same will be applied in the Reward Table )
		
		- 2. @BonusFromCompanyRewardPool ( In Business Code Table )::
		-		SponsorID(Parent): Previous Sponsor
		-		MemberID: NULL ( be set when created )
		-		ConnectionStatus: @BonusFromCompanyRewardPool(2)
		-		**RewardAccountID: Company Reward Pool ID.
		-		No further changes in business.
		-		IsFailedRecovered = NULL
		
		- 3. @FailedUsersReapplySituation ( In Business Code Table ) It can also be the (1)::
		-		SponsorID(Him/Herself): You
		-		MemberID: NULL ( be set when created )
		-		ConnectionStatus: @FailedUsersReapplySituation(3)
		-		**RewardAccountID: Company Reward Pool ID.
		-		No further changes in business.
		-		IsFailedRecovered = 1 ( Same will be applied in the Reward Table )
		
	*/
    END
