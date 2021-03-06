USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<MD.Alim Ul Karim , auk-port.webs.com>
-- Create date: <29-Jul-2012>
-- Description:	<Auto Winner Schedule>
-- =============================================
ALTER PROCEDURE [dbo].[RunTheSchedule]
AS
	BEGIN 
		
		--Run the Schedule 2 times in a row, so that we could work with the Reward and failed members.
		DECLARE @I			int

		SET @i = 0;

		WHILE (@i < 2) BEGIN
			-- Connecting Reward Members with Failed users
			EXEC ConnectRewardMemberWithFailedUsersCode;

			-- Connecting Reward Members with Company's Reward Pool
			EXEC ConnectRewardMemberWithCompanyRewardPool;

			-- If Reward users failed with their reward and if that was from a 
			-- Failed user. In addition, those reward users will not get any future reward.
			EXEC KeepFailedUsers_OnAgainFailedOfReward;

			-- Deleting business codes which are connect with company's pool and expired.
			EXEC DeleteFailedRecordsWhichAreConnectedWithServer;


			-- Get a list of expire codes users in FailedBusiness Table.
			EXEC GenerateFailedUsersList;

			-- Get a list of reward users in the RewardPromote Table and then delete all expired business and temp business codes.
			EXEC GenerateRewardUsersList;

			-- Refresh Business Level and User Counts in the Reward Table ( 26 Aug 2012 )
			EXEC dbo.RefreshBusinessLevel;
			
			
			-- Promote users who are eligible for the reward , more than 120 user in one downlink
			EXEC PromotoUsersWhoAreEligibleForReward;

			SET @i += 1;
		END
	END 