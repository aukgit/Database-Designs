USE [MLM Db]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Counter] 
	
	@SchemaName SYSNAME = 'dbo' , 
	@TableName  SYSNAME
                              
AS
  BEGIN
      SET NOCOUNT ON;

      DECLARE @SQLQ NVARCHAR(1000)
      DECLARE @Counter INT;

      SET @SQLQ = 'SELECT @Counter = COUNT(*) FROM ' + 
       Quotename(@SchemaName) + '.' + Quotename(@TableName);

      EXEC sp_executesql
        @SQLQ ,
        N'@Counter INT OUTPUT',
        @Counter = @Counter OUTPUT
		
	  SET @TableName = (CAST(@Counter AS VARCHAR(50))  + ' ' + @TableName);
	  SELECT @TableName;
      Return  @Counter
  END 