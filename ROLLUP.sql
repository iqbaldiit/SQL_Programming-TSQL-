DECLARE @EMPLOYEE AS TABLE(  
 emp_id int identity,  
 fullname varchar(65),  
 occupation varchar(45),  
 gender varchar(30),  
 salary int,  
 country varchar(55)  
);  

INSERT INTO @EMPLOYEE(fullname, occupation, gender, salary, country)  
VALUES ('John Doe', 'Writer', 'Male', 62000, 'USA'),  
('Mary Greenspan', 'Freelancer', 'Female', 55000, 'India'),  
('Grace Smith', 'Scientist', 'Male', 85000, 'USA'),  
('Mike Johnson', 'Manager', 'Male', 250000, 'India'),  
('Todd Astel', 'Business Analyst', 'Male', 42000, 'India'),  
('Sara Jackson', 'Engineer', 'Female', 65000, 'UK'),  
('Nancy Jackson', 'Writer', 'Female', 55000, 'UK'),  
('Rose Dell', 'Engineer', 'Female', 58000, 'USA'),  
('Elizabeth Smith', 'HR', 'Female', 55000, 'UK'),  
('Peter Bush', 'Engineer', 'Male', 42000, 'USA');  

SELECT ISNULL(country,'GRAND TOTAL--'),ISNULL(Gender,'Sub Total--'),SUM(salary) AS SALARY FROM @EMPLOYEE
GROUP BY ROLLUP(country,Gender) --ORDER BY country,Gender 