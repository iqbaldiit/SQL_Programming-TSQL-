/*
Write a SQL query for a report that provides the pairs (actor_id, director_id) where the actor has cooperated with the director at least three times.

Return the result table in any order.

The query result format is in the following example.
*/
CREATE TABLE ActorDirector (actor_id   int,director_id int,timestamp   int)
INSERT INTO ActorDirector VALUES (1, 1, 0), (1, 1, 1), (1, 1, 2), (1, 2, 3), (1, 2, 4), (2, 1, 5), (2, 1, 6)
SELECT * FROM ActorDirector

SELECT actor_id,director_id FROM ActorDirector
GROUP BY actor_id,director_id HAVING COUNT(timestamp)>=3

DROP TABLE ActorDirector
