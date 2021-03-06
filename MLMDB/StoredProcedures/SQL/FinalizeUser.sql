USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 5 Sep 2012
-- Description:	Finalize the user account when he or she has been paid (rewards) 3 + 1
-- =============================================
ALTER PROCEDURE [dbo].[FinalizeUser] 
	-- Add the parameters for the stored procedure here
       @MemberID BIGINT
AS 
       BEGIN
             IF ( EXISTS ( SELECT   M.MemberID
                           FROM     dbo.Member M
                           WHERE    M.MemberID = @MemberID AND M.IsFinalize = 1 ) ) 
                BEGIN
                      RETURN -1;
                END
	
             SET NOCOUNT ON;
             DECLARE @Child TINYINT
             DECLARE @Reward TINYINT
             DECLARE @TotalPosible INT 
	
             SELECT TOP 1
                    @Child = S.Childs ,
                    @Reward = S.RewardPosibility
             FROM   dbo.Settings AS S;
	
	
             --SET @TotalPosible = @Child + @Reward;
		     --Select 'Possible' =  @TotalPosible;

			 SELECT   R.MemberID
                           FROM     dbo.RewardPaidList R
                           WHERE    R.MemberID = @MemberID AND R.Paid >= @TotalPosible

             IF ( EXISTS ( SELECT   R.MemberID
                           FROM     dbo.RewardPaidList R
                           WHERE    R.MemberID = @MemberID AND R.Paid >= @TotalPosible ) ) 
                BEGIN
					UPDATE dbo.Member SET IsFinalize = 1
					WHERE dbo.Member.MemberID = @MemberID AND dbo.Member.IsFinalize = 0;
                END
       END
