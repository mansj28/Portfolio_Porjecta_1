USE pokemon_database;

SELECT COUNT(*)
FROM pokemonstats;

-- 1) The number of distinct primary types present across Pokemon
SELECT DISTINCT Type_1 as "Primary Types"
FROM pokemonstats;

-- 2) The average Total stats for each Pokemon generation

SELECT Generation, ROUND(AVG(Total),2) AS "Average of total stats"
FROM pokemonstats
GROUP BY Generation;

-- 3) The white Pokemon with the highest Total stats

WITH T AS
(
	SELECT Name, Total, Color,
	DENSE_RANK() over(partition by Color order by Total DESC) as rnk
	FROM pokemonstats
	WHERE color = 'White'
)
SELECT Name
FROM T 
WHERE rnk = 1;