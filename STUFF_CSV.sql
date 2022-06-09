CREATE TABLE Activities (sell_date date,product varchar(50))

INSERT INTO Activities VALUES
('2020-05-30','Headphone')
,('2020-06-01','Pencil')
,('2020-06-02','Mask')
,('2020-05-30','Basketball')
,('2020-06-01','Bible')
,('2020-06-02','Mask')
,('2020-05-30','T-Shirt')

--SELECT * FROm #Temp_Activities



  --SELECT tab.sell_date,LEN(tab.saleList)-LEN(REPLACE(tab.saleList,',',''))+1 AS num
  --, tab.saleList FROM (SELECT DISTINCT t1.sell_date,
  --    STUFF(
  --           (SELECT DISTINCT ', ' + t2.product
  --            FROM Activities t2
  --            WHERE t1.sell_date = t2.sell_date
  --            FOR XML PATH (''))
  --            , 1, 1, '')  AS saleList
  --  from Activities t1 ) tab
  
SELECT tab.sell_date,LEN(tab.products)-LEN(REPLACE(tab.products,',',''))+1 AS num_sold,tab.products 
FROM (SELECT DISTINCT AC.sell_date, STUFF(
(SELECT DISTINCT ','+A.product FROM Activities A WHERE A.sell_date=AC.sell_date FOR XML PATH('')),1,1,'') AS products
FROM Activities  AC)tab

DROP TABLE Activities