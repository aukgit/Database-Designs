USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 26 Aug 2012
-- Description:	Insert Test Member
-- =============================================
ALTER PROCEDURE [dbo].[CreateTestMember] 
	-- Add the parameters for the stored procedure here
	@LogName				VARCHAR(80) = NULL, 
	@FullName				VARCHAR(80) = NULL,
	@Type					int = 1,
	@Parent					BIGINT = -1,
	@RewardAcc				BIGINT	= NULL,
	@CreatePurchase			BIT = 0,
	@ConnectionStatus		TINYINT = NULL,
	@BusinessCodeAssignDate	SMALLDATETIME = NULL,
	@BusinessCodeCount		int = 3,
	@IsFailedRecovery       BIT,
	@ShowRoomID			    Uniqueidentifier = null

	
AS
BEGIN
	DECLARE @date			DATETIME = GETUTCDATE();
	DECLARE @MemberID		bigint;
	DECLARE @AccountStatus		int = 1; -- successes

	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--SELECT LEN(@date),@date;
	IF @LogName IS NULL OR @LogName = ''  BEGIN
	   SET @LogName = CONVERT(varchar(80), @date, 113);
	END
	
	IF @FullName IS NULL OR @FullName = '' BEGIN
	   SELECT @FullName = CONVERT(varchar(80), @date, 113);  
	END

	IF @CreatePurchase = 1 BEGIN 
		SET @AccountStatus = 2; -- Pending
	END
	
	
	INSERT INTO dbo.Member
	        ( LogName ,
	          FullName ,
	          UsersTypeID ,
	          Parent ,
	          RewardAccountID ,
	          CountryID ,
	          Email ,
	          Mobile ,
	          AssignedDate ,
	          AccountCreatedDate ,
	          AccountStatusID ,
	          SponsorPayment ,
	          IsProductReceived ,
	          IsCreated ,
	          IsFinalize ,
	          MailingAddress ,
	          Profession ,
	          CountryDivisionID ,
	          CreatedDownlinks ,
	          CreatedDownlinksforReward ,
	          ConnectionStatusID ,
	          IsTestAccount ,
	          BusinessLevel ,
	          CachedTime ,
	          DateOfBirth
	        )
	VALUES  ( @LogName , -- LogName - nvarchar(80)
	          @FullName , -- FullName - nvarchar(80)
	          @Type , -- UsersTypeID - int
	          @Parent , -- Parent - bigint
	          @RewardAcc , -- RewardAccountID - bigint
	          1 , -- CountryID - int
	          @LogName , -- Email - varchar(256)
	          '1231322112' , -- Mobile - varchar(50)
	          GETUTCDATE() , -- AssignedDate - datetime
	          GETUTCDATE() , -- AccountCreatedDate - datetime
	          @AccountStatus , -- AccountStatusID - int
	          2500 , -- SponsorPayment - decimal
	          0 , -- IsProductReceived - bit
	          1 , -- IsCreated - bit
	          0 , -- IsFinalize - bit
	          'mail' , -- MailingAddress - varchar(400)
	          'profession' , -- Profession - varchar(50)
	          1 , -- CountryDivisionID - int
	          0 , -- CreatedDownlinks - tinyint
	          0 , -- CreatedDownlinksforReward - tinyint
	          NULL , -- ConnectionStatusID - tinyint
	          1 , -- IsTestAccount - bit
	          0 , -- BusinessLevel - int
	          GETUTCDATE() , -- CachedTime - smalldatetime
	          GETUTCDATE()  -- DateOfBirth - date
	        );
	        
	SET @MemberID = @@IDENTITY;
	
	SELECT * FROM dbo.Member AS M WHERE M.MemberID = @MemberID;
	
	
	IF @CreatePurchase = 1 BEGIN 
		-- Create Purchase
		EXEC dbo.CreateTestPurchase 
			@ProductID = -1 , -- int
			@MemberID = @MemberID , -- bigint
			@ProductDeliveryMethodID = 3 , -- tinyint business post paid
			@ShowRoom = @ShowRoomID ; -- guid
	END
	
	
	-- Create Downlink 
	
	EXEC dbo.CreateDownlink 
	    @ParentMemberID = @Parent , -- bigint
	    @ChildMemberID = @MemberID , -- bigint
	    @ConnectionStatus = @ConnectionStatus,
	    @IsFailedRecovery = @IsFailedRecovery , -- bit
	    @RewardAcc = @RewardAcc ;-- bigint
	
	--- Create Busienss Code
	EXEC dbo.CreateBusinessCode 
	    @MemberID = @MemberID , -- bigint
	    @len = @BusinessCodeCount , -- int
	    @RewardAccountID = @RewardAcc , -- bigint
	    @ConnectionStatusID = @ConnectionStatus , -- tinyint
	    @Assign =  @BusinessCodeAssignDate ;-- smalldatetime
	
END
