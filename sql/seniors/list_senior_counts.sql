/* 
    Script:   List Over 40s Counts
    Created:  2019-07-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results
*/

/*
   Create temporary table(s) containing "senior bests" - one record per person, per event, per age category
   This starts with the query from extract_senior_results.sql
*/

-- First temporary table only contains actual results - "age category" based on "age at competition"
DROP TEMPORARY TABLE IF EXISTS senior_bests_1;
CREATE TEMPORARY TABLE senior_bests_1 AS
SELECT eventId, personId, FLOOR(age_at_comp / 10) * 10 AS age_category,
  MIN(best) AS best_single, MIN(IF(average > 0, average, NULL)) AS best_average
FROM
(
  -- Derived table lists senior results, including age at the start of the competition
  -- Index hint (USE INDEX) ensures that MySQL / MariaDB uses an optimal query execution plan
  -- Persons (only seniors) -> Results.personId -> Competitions.id
  SELECT r.eventId, r.personId, r.best, r.average,
    TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM Results AS r
  INNER JOIN Competitions AS c ON r.competitionId = c.id
  INNER JOIN Persons AS p USE INDEX () ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  WHERE best > 0
  HAVING age_at_comp >= 40
) AS senior_results
GROUP BY eventId, personId, age_category;

-- Final query is a simple aggregation - one record per event, per age category
SELECT eventId, age_category, COUNT(DISTINCT personId) AS numSingles, COUNT(DISTINCT IF(best_average, personId, NULL)) AS numAverages
FROM
(
  -- Derived table contains backdated results - "over 50" also counts as "over 40", etc
  SELECT eventId, personId, a.age_category, MIN(best_single) AS best_single, MIN(best_average) AS best_average
  FROM senior_bests_1 AS s
  JOIN (SELECT DISTINCT age_category FROM senior_bests_1) AS a ON a.age_category <= s.age_category
  GROUP BY eventId, personId, age_category
) AS senior_bests
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
