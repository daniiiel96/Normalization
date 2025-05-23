USE Youtube2006
GO

--Declare @Rating int = 5, @VideoId int, @UserName NVARCHAR(30);

--SET @UserName = 'Vera';

DROP PROCEDURE IF EXISTS SetRating;
GO


CREATE PROCEDURE SetRating @Rating tinyint, @VideoId int, @UserName NVARCHAR(30)
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		Declare @UserId int = (
			SELECT userId
			FROM Users
			WHERE userName = @UserName
		)
		/* INITIAL CHECKS*/

		IF  @Rating > 10 OR @Rating = 0
			THROW 50000, 'Invalid Rating',0;
		
		IF  @UserId IS NULL
			THROW 50000, 'User does not exist',0;


		IF NOT EXISTS ( SELECT videoId from Videos WHERE videoId = @VideoId)
			THROW 50000, 'Video does not exist',0;

		/*Get previous rating */
		Declare @oldRating int ;

		SET @oldRating = ( -- Comparar con SELECT @oldRating = halfstars
			SELECT halfstars
			FROM Ratings
			WHERE @UserId = userId AND @VideoId =videoId
		)

		IF @oldRating IS NULL
		BEGIN
			/* Add rating*/
			INSERT INTO Ratings (userId,videoId,halfstars, dateRated,timeRated)
			VAlUES (@UserId,@VideoId, @Rating, GETDATE(), GETDATE())
		END
		ELSE
		BEGIN
			/* Update rating*/
			UPDATE Ratings 
			SET halfstars = @Rating, 
				dateRated = GETDATE(), 
				timeRated = GETDATE()
			WHERE @UserId = userId AND @VideoId =videoId
		END

		/*Update Average*/
		UPDATE Videos
		SET numvotes += IIF(@oldRating IS NULL,1,0) , 
			sumvotes += @Rating - ISNULL(@oldRating,0) --Explicar
		WHERE videoId = @VideoId

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH

		PRINT 'Transaction failed, rolling back changes'
		ROLLBACK TRANSACTION;
		THROW; --Propagar el error

	END CATCH
	PRINT CONCAT('Still Open Transactions: ', @@TRANCOUNT)
END
GO


EXEC SetRating @Rating = 10, @VideoId=1, @UserName='Veran''t'
GO


SELECT TOP (1000) *
FROM [Youtube2006].[dbo].[Ratings]

SELECT TOP (1000) *
FROM Videos