CREATE DATABASE RentACar

CREATE TABLE Cars(
	Id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	Model NVARCHAR(100) NOT NULL,
	Power INT NOT NULL,
	PricePerHour DECIMAL NOT NULL,
	LicenseNumber NVARCHAR(10) NOT NULL
)

INSERT INTO Cars(Model, Power, PricePerHour, LicenseNumber)
VALUES (N'BMW', 120, 5, 'GF2455KL')

INSERT INTO Cars(Model, Power, PricePerHour, LicenseNumber)
VALUES (N'Audi', 120, 7, 'GF5675KL')


CREATE TABLE Rents(
	Id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	RentDate DATETIME NOT NULL,
	Duration INT NOT NULL,
	CarId INT NOT NULL FOREIGN KEY REFERENCES Cars(Id)
)

ALTER TABLE Rents
ADD CreatedAt DATETIME

CREATE TRIGGER TR_Rent_CreatedAt
ON Rents
FOR Insert
AS
	UPDATE Rents SET CreatedAt = GETDATE() 
	WHERE Id IN (SELECT Id from inserted)
	
INSERT INTO Rents (RentDate, Duration, CarId)
VALUES ('2019-10-06', 10, 2)

ALTER TABLE Rents
ADD LastChanged DATETIME

CREATE TRIGGER TR_Rents_LastChanged
ON Rents
FOR INSERT, UPDATE
AS
	UPDATE Rents SET LastChanged = GETDATE()
	WHERE ID IN (SELECT ID FROM inserted)

INSERT INTO Rents (RentDate, Duration, CarId)
VALUES ('2019-10-06', 10, 1)

UPDATE Rents SET Duration = 15 where Id = 1

ALTER TABLE Rents
ADD DeletedAt DATETIME

CREATE TRIGGER TR_Rents_SoftDelete
ON Rents
INSTEAD OF DELETE
AS
	UPDATE Rents SET DeletedAt = GETDATE()
	WHERE Id IN (SELECT Id FROM deleted)
	
DELETE FROM Rents WHERE Id = 2

DISABLE TRIGGER TR_Rents_SoftDelete ON Rents

ALTER TRIGGER TR_Rents_PreventOverlapping
On Rents
INSTEAD OF INSERT
AS
	DECLARE @ReturnDate DATETIME
	SET @ReturnDate = 
	(SELECT dbo.FN_AddDuration(Duration, RentDate) FROM inserted)

	SELECT @ReturnDate AS InsertDate

	DECLARE @MaxReturnDate DATETIME
	SET @MaxReturnDate = 
	(SELECT MAX(dbo.FN_AddDuration(Duration, RentDate)) 
	FROM Rents WHERE CarId = (SELECT CarId FROM inserted))

	SELECT @MaxReturnDate AS MaxDate

	IF @ReturnDate <= @MaxReturnDate
		BEGIN
			return
			RAISERROR ('Car is already in use', 16, 1)
		END
	ELSE
	INSERT INTO Rents (Duration, RentDate, CarId)
	SELECT I.Duration, I.RentDate, I.CarId FROM inserted AS I

DISABLE TRIGGER TR_Rents_PreventOverlapping ON Rents

INSERT Rents (RentDate, Duration, CarId)
VALUES ('2019-10-6', 10, 1)

CREATE FUNCTION FN_AddNumbers (@Num1 INT, @Num2 INT)
RETURNS INT
AS 
	BEGIN
		RETURN @Num1 + @Num2
	END

SELECT dbo.FN_AddNumbers(1, 4) AS Result
	
CREATE FUNCTION FN_AddDuration(@Duration INT, @Date DATETIME)
RETURNS DATETIME
AS
	BEGIN
		RETURN DATEADD(HOUR, @Duration, @Date)
	END

CREATE FUNCTION FN_MaxDurationForCar(@CarId INT)
RETURNS TABLE
AS 
RETURN(
	SELECT C.Model, MAX(R.Duration) AS MaxDuration FROM Cars As C
	JOIN Rents AS R
	ON R.CarId = C.Id
	WHERE C.Id = @CarId
	GROUP BY C.Model
)

SELECT * FROM dbo.FN_MaxDurationForCar(1)

CREATE PROCEDURE SP_SelectCars
AS
SELECT * FROM Cars

EXEC SP_SelectCars

CREATE PROCEDURE SP_SelectRentsForCar @CarId INT
AS
SELECT * FROM Rents WHERE CarId = @CarId

EXEC SP_SelectRentsForCar @CarId = 1

CREATE PROCEDURE SP_DeleteAllRentsUnder
@Profit INT
AS
	DELETE FROM Rents
	SELECT * FROM (SELECT Duration * PricePerHour AS Profit FROM Rents AS R
	JOIN Cars AS C
	ON R.CarId = C.Id) T
	WHERE T.Profit < @Profit

EXEC SP_DeleteAllRentsUnder @Profit = 170

CREATE PROCEDURE SP_DeleteUnusedCars
AS
DELETE FROM Cars
WHERE ID NOT IN (SELECT CarId FROM Rents)

EXEC SP_DeleteUnusedCars

-- Create BANK

--Customers
--FirstName, LastName

--BankAccount
--Balance, ExpirationDate

--AccountActivity
--Amount, Date

--edit bankaccount --> Create Account Activity with amount and current date
--delete activity --> add amount ot bank account
--soft delete customers
--prevent balance from going below 0

--delete all expired bank accounts
--get all bank accounts with balance over 1000
--add 1% to all bank accounts with balance over 1000
--get all activities after date, for customer
