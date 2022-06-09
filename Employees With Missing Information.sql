CREATE TABLE Employees (employee_id int, name varchar(100))
CREATE TABLE Salaries (employee_id int, salary int)

INSERT INTO Employees VALUES (2,'Crew'),(4,'Haven'),(5,'Kristian')
INSERT INTO Salaries VALUES (5,76071),(1,22517),(4,63539)


--SELECT * FROM Employees
--SELECT * FROM Salaries

--SELECT * FROM Employees E
--FULL OUTER JOIN Salaries S ON E.employee_id=S.employee_id


SELECT S.employee_id FROM Employees E
RIGHT JOIN Salaries S ON E.employee_id=S.employee_id WHERE ISNULL(E.name,'')=''
UNION ALL
SELECT E.employee_id FROM Employees E
LEFT JOIN Salaries S ON E.employee_id=S.employee_id WHERE ISNULL(S.salary,0)=0





DROP TABLE Employees
DROP TABLE Salaries

