CREATE TABLE Products (product_id int,store1 int,store2 int,store3 int)

INSERT INTO Products VALUES (0,95,100,105),(1,70,NULL,80)

SELECT * FROM Products

SELECT product_id,store,price
FROM Products
UNPIVOT
(
	price FOR store IN (store1,store2,store3)
)u;

DROP TABLE Products
