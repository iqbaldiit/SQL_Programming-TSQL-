DECLARE @tbl_Dates AS TABLE (id int, sDate DATE, total_number int)

INSERT INTO @tbl_Dates 
VALUES (1,'01 Jan 2022',25)
,(2,'03 Jan 2022',10)
,(3,'04 Jan 2022',20)
,(4,'05 Jan 2022',30)
,(5,'07 Jan 2022',10)
,(6,'09 Jan 2022',10)
,(7,'10 Jan 2022',10)
,(8,'14 Jan 2022',10)
,(9,'15 Jan 2022',10)

--SELECT * FROM @tbl_Dates ORDER BY sDate
--Process 1
;WITH t AS (
  SELECT sDate d, SUM(total_number) tn, ROW_NUMBER() OVER(ORDER BY sDate) i
  FROM @tbl_Dates
  GROUP BY sDate
)
SELECT MIN(d) StartDate,MAX(d) EndDate, SUM (tn) AS tn 
FROM t
GROUP BY DATEDIFF(day,i,d)


--Process 2
-----------------------------------------
SELECT COUNT(DATEDIFF(DAY,t2.StartDate,t2.EndDate)+1) AS nCount FROM (SELECT MIN(d) StartDate,MAX(d) EndDate
FROM (
  SELECT sDate d,ROW_NUMBER() OVER(ORDER BY sDate) i
  FROM @tbl_Dates
  GROUP BY sDate
)t
GROUP BY DATEDIFF(day,i,d))t2 WHERE DATEDIFF(DAY,t2.StartDate,t2.EndDate)+1=3
