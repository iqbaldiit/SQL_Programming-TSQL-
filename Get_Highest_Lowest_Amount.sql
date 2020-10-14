/*
-- =============================================
-- Author:		Md. Masud Iqbal
-- Create date: 14 Oct 2020
-- Description:	The aim of the these query is to getting highest or lowest amount or number or salary or anything numerical value from a table or recordset.
				We will try to do this by 2 way
				1. Using Subquery
				2. Using CTE
-- =============================================
*/

--Create a table like "Employee"
DECLARE @tbl_Employee AS TABLE (EmployeeID int NOT NULL, EmployeeName varchar(50), Salary decimal(18,2));

--Insert Record in the table
INSERT INTO @tbl_Employee VALUES
(1,'NESTOR D CALIPAY',160000)
,(2,'Sanjoy Kumar Joy',300000)
,(3,'Muhammad Moniruzzaman',187000)
,(4,'Moslem Uddin',260000)
,(5,'Anwar Hossain Khondoker',250000)
,(6,'Mahatab Uddin Kabir',142000)
,(7,'DELWAR HOSSAIN',190000)
,(8,'MD. Jahangir Alom',187000)
,(9,'Md. Amdadul Haque',130000)
,(10,'Md. Delowar Hossain Dulal',170000)
,(11,'Asraful Alam',307740)
,(12,'Md.Mizanur Rahman',159000)
,(13,'Md. Firoz ahmed',150000)
,(14,'MD. LITON MIAH',143000)
,(15,'MD. CHANCHAL HOSSAIN',220000)
,(16,'Engr. Muhammad Moniruzzaman',140000)
,(17,'Md. Azizur Rahman',140000)
,(18,'Sorowar Alam',139000)
,(19,'MD. NAJIBUR MALLICK',137000)
,(20,'Md.ZahidHasan ',135000)
,(21,'Md. Khondoker mamun',134000)
,(22,'MD. MAHFUJUL HAQUE',132000)
,(23,'Md.Atiqur Rahman',300000);

--SELECT * FROM @tbl_Employee

--Get Highest Value using SubQuery
SELECT * FROM (
SELECT Emp.EmployeeName,Emp.Salary, DENSE_RANK() OVER (ORDER BY SALARY DESC) AS Position FROM @tbl_Employee Emp) tab
WHERE tab.Position=1; -- Now you can set highest, 2nd highest, 3rd highest and what you desire 

--Get Highest Value using CTE (Common Table Expression)
WITH Result AS 
(
	SELECT Emp.EmployeeName,Emp.Salary, DENSE_RANK() OVER (ORDER BY SALARY DESC) AS Position FROM @tbl_Employee Emp
)
SELECT * FROM Result RS WHERE RS.Position=2-- Now you can set highest, 2nd highest, 3rd highest and what you desire


--Get Lowest Value using SubQuery
SELECT * FROM (
SELECT Emp.EmployeeName,Emp.Salary, DENSE_RANK() OVER (ORDER BY SALARY ASC) AS Position FROM @tbl_Employee Emp) tab
WHERE tab.Position=1; -- Now you can set highest, 2nd highest, 3rd highest and what you desire 

--Get Lowest Value using CTE (Common Table Expression)
WITH Result AS 
(
	SELECT Emp.EmployeeName,Emp.Salary, DENSE_RANK() OVER (ORDER BY SALARY ASC) AS Position FROM @tbl_Employee Emp
)
SELECT * FROM Result RS WHERE RS.Position=2-- Now you can set highest, 2nd highest, 3rd highest and what you desire


