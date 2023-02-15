DECLARE @Employees TABLE 
(
  EmployeeID int NOT NULL PRIMARY KEY,
  FirstName varchar(50) NOT NULL,
  LastName varchar(50) NOT NULL,
  ManagerID int NULL
)

INSERT INTO @Employees VALUES (1, 'Ken', 'Thompson', NULL)
INSERT INTO @Employees VALUES (2, 'Terri', 'Ryan', 1)
INSERT INTO @Employees VALUES (3, 'Robert', 'Durello', 1)
INSERT INTO @Employees VALUES (4, 'Rob', 'Bailey', 2)
INSERT INTO @Employees VALUES (5, 'Kent', 'Erickson', 2)
INSERT INTO @Employees VALUES (6, 'Bill', 'Goldberg', 3)
INSERT INTO @Employees VALUES (7, 'Ryan', 'Miller', 3)
INSERT INTO @Employees VALUES (8, 'Dane', 'Mark', 5)
INSERT INTO @Employees VALUES (9, 'Charles', 'Matthew', 6)
INSERT INTO @Employees VALUES (10, 'Michael', 'Jhonson', 6) 
--After the @Employees table is created, following SELECT statement, which is preceded by a WITH clause that includes a CTE named cteReports is created: 

;WITH
  cteReports (EmpID, FirstName, LastName, MgrID, EmpLevel)
  AS
  (
    SELECT EmployeeID, FirstName, LastName, ManagerID, 1
    FROM @Employees
    WHERE ManagerID IS NULL
    UNION ALL
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ManagerID, 
      r.EmpLevel + 1
    FROM @Employees e
      INNER JOIN cteReports r
        ON e.ManagerID = r.EmpID
  )
SELECT
  FirstName + ' ' + LastName AS FullName, 
  EmpLevel,
  (SELECT FirstName + ' ' + LastName FROM @Employees 
    WHERE EmployeeID = cteReports.MgrID) AS Manager
FROM cteReports 
ORDER BY EmpLevel, MgrID 

