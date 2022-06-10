
--Write an SQL query to find all dates' Id with higher temperatures compared to its previous dates (yesterday).

CREATE TABLE Weather (id int, recordDate date, temperature int)
--INSERT INTO Weather VALUES (1,'2015-01-01',10),(2,'2015-01-02',25),(3,'2015-01-03',20),(4,'2015-01-04',30)
INSERT INTO Weather VALUES (1,'2000-12-14',3),(2,'2000-12-16',5)--,(3,'2015-01-03',20),(4,'2015-01-04',30)

SELECT * FROM Weather 
SELECT *, LAG(temperature) OVER(ORDER BY recordDate) PrevTmp, LAG(recordDate) OVER(ORDER BY recordDate) PrevDate FROM weather

SELECT tab.id FROM (SELECT *, LAG(temperature) OVER(ORDER BY recordDate) PrevTmp, LAG(recordDate) OVER(ORDER BY recordDate) PrevDate FROM weather)tab 
WHERE tab.temperature>tab.PrevTmp AND tab.PrevTmp IS NOT NULL AND DATEDIFF(DAY,tab.PrevDate,tab.recordDate)=1

DROP TABLE Weather

