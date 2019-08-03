/* 
    Script:   List Over 40s Counts
    Created:  2019-07-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results
*/

/*
   Create temporary table(s) containing "senior bests" - one record per person, per event, per age category
*/

-- Determine "explicit" senior bests - "age category" is based on "age at competition"
DROP TEMPORARY TABLE IF EXISTS senior_bests_1;
CREATE TEMPORARY TABLE senior_bests_1 AS
SELECT personId, eventId, FLOOR(age_at_comp / 10) * 10 AS age_category,
  MIN(best) AS best_single, MIN(IF(average > 0, average, NULL)) AS best_average
FROM
(
  -- Derived table contains senior results, including age at the start of the competition
  -- Index hint (USE INDEX) ensures that MySQL / MariaDB uses the optimal query execution plan
  -- i.e. Persons ("WHERE" limits to seniors) -> Results.personId -> Competitions.id
  SELECT r.personId, r.eventId, r.best, r.average,
    TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM Persons AS p USE INDEX ()
  JOIN Results AS r ON r.personId = p.id AND best > 0
  JOIN Competitions AS c ON c.id = r.competitionId
  WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  AND p.subid = 1
  HAVING age_at_comp >= 40
) AS senior_results
GROUP BY personId, eventId, age_category;

-- Determine "implicit" senior bests - e.g. "over 50" also counts as "over 40", etc
DROP TEMPORARY TABLE IF EXISTS senior_bests_2;
CREATE TEMPORARY TABLE senior_bests_2 AS
SELECT personId, eventId, a.age_category, MIN(best_single) AS best_single, MIN(best_average) AS best_average
FROM senior_bests_1 AS s
JOIN (SELECT 40 AS age_category UNION ALL SELECT 50 UNION ALL SELECT 60 UNION ALL SELECT 70 UNION ALL SELECT 80 UNION ALL SELECT 90) AS a ON a.age_category <= s.age_category
GROUP BY personId, eventId, age_category;

/*
   List senior counts - one record per event, per age category
*/

-- Final query is a simple aggregation
SELECT eventId, age_category,
  COUNT(DISTINCT personId) AS numSingles, COUNT(DISTINCT IF(best_average, personId, NULL)) AS numAverages
FROM senior_bests_2
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
