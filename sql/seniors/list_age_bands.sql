/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of people in each senior age band - 40+, 50+, 60+, etc
*/

/*
   Create temporary table(s) containing seniors - one record per person, per event, per age category
*/

-- Determine "explicit" seniors - "age category" is based on "age at competition"
DROP TEMPORARY TABLE IF EXISTS seniors_1;
CREATE TEMPORARY TABLE seniors_1 AS
SELECT DISTINCT personId, eventId, FLOOR(age_at_comp / 10) * 10 AS age_category
FROM
(
  -- Derived table contains senior results, including age at the start of the competition
  -- Index hint (USE INDEX) ensures that MySQL / MariaDB uses the optimal query execution plan
  -- i.e. Persons ("WHERE" limits to seniors) -> Results.personId -> Competitions.id
  SELECT r.personId, r.eventId,
    TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM Persons AS p USE INDEX ()
  JOIN Results AS r ON r.personId = p.id AND best > 0
  JOIN Competitions AS c ON c.id = r.competitionId
  WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  AND p.subid = 1
  HAVING age_at_comp >= 40
) AS senior_results;

-- Determine "implicit" seniors - e.g. "over 50" also counts as "over 40", etc
DROP TEMPORARY TABLE IF EXISTS seniors_2;
CREATE TEMPORARY TABLE seniors_2 AS
SELECT DISTINCT personId, eventId, a.age_category
FROM seniors_1 AS s
JOIN (SELECT 40 AS age_category UNION ALL SELECT 50 UNION ALL SELECT 60 UNION ALL SELECT 70 UNION ALL SELECT 80 UNION ALL SELECT 90 UNION ALL SELECT 100) AS a ON a.age_category <= s.age_category;

/*
   List senior counts - one record per event, per age category
*/

-- Final query is a simple aggregation
SELECT eventId, age_category, COUNT(DISTINCT personId) AS numPersons
FROM seniors_2
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
