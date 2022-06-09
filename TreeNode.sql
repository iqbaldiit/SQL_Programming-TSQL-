/*
Each node in the tree can be one of three types:

"Leaf": if the node is a leaf node.
"Root": if the node is the root of the tree.
"Inner": If the node is neither a leaf node nor a root node.
Write an SQL query to report the type of each node in the tree.

Return the result table ordered by id in ascending order.

The query result format is in the following example.
*/

CREATE TABLE Tree(id int, p_id int)

INSERT INTO Tree VALUES (1,NULL),(2,1),(3,1),(4,2),(5,2)
SELECT * FROM Tree

SELECT id, 'Root' AS type FROM Tree WHERE p_id IS NULL
UNION ALL
SELECT id, 'Inner' AS type FROM Tree WHERE ISNULL(p_id,0)>0
AND id IN (SELECT p_id FROM Tree)
UNION ALL
SELECT id, 'Leaf' AS type FROM Tree WHERE  ISNULL(p_id,0)>0
AND id NOT IN (SELECT ISNULL(p_id,0) FROM Tree)
ORDER BY id ASC



DROP TABLE Tree
