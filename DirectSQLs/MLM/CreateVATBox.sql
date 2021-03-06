USE [MLM Db]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Alim Ul Karim
-- Create date: 31 Aug 2012
-- Description:	Create VATBox Account
-- =============================================
ALTER PROCEDURE [dbo].[CreateVATBox] 
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @VatBoxId UNIQUEIDENTIFIER
	
	SELECT TOP 1 @VatBoxId = S.VATBoxID  FROM dbo.Settings AS S;
	
	
	
	IF @VatBoxId IS NULL OR NOT EXISTS(SELECT * FROM dbo.VATBox AS VB WHERE VB.VATBoxID = @VatBoxId AND VB.Cleared = 0 ) BEGIN
		-- create new account
		SET @VatBoxId = NEWID();
		INSERT INTO dbo.VATBox
		        ( VATBoxID ,
		          CountOf ,
		          LastClearedDate ,
		          Collected,
		          Cleared ,		          
		          CreatedDate )
		VALUES
		        (  @VatBoxId , -- VATBoxID - uniqueidentifier
		          0 , -- CountOf - decimal
		          NULL , -- LastClearedDate - smalldatetime
		          0, -- collected
		          0 , -- Cleared - bit
		          GETUTCDATE()  -- CreatedDate - smalldatetime
		          )
		UPDATE dbo.Settings SET VATBoxID = @VatBoxId WHERE dbo.Settings.SettingsID = 1;
	END
	
		
END
