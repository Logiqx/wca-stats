/* 
    Script:   List Over 40s Counts
    Created:  2019-07-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results
*/

SELECT eventId, t.age_category, COUNT(DISTINCT personId) AS numSingles, COUNT(DISTINCT IF(best_average, personId, NULL)) AS numAverages
FROM
(
  SELECT personId, eventId, FLOOR(age_at_comp / 10) * 10 AS age_category,
    MIN(best) AS best_single, MIN(IF(average > 0, average, NULL)) AS best_average
  FROM
  (
    SELECT r.personId, r.eventId, r.best, r.average, TIMESTAMPDIFF(YEAR,
        DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
        DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
    FROM Persons AS p USE INDEX ()
    JOIN Results AS r ON r.personId = p.id AND best > 0
    JOIN Competitions AS c ON c.id = r.competitionId
    WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    AND p.subid = 1
    HAVING age_at_comp >= 40
  ) AS t
  GROUP BY personId, eventId, age_category
) AS t
JOIN (SELECT 40 AS age_category UNION ALL SELECT 50 UNION ALL SELECT 60 UNION ALL SELECT 70 UNION ALL SELECT 80 UNION ALL SELECT 90 UNION ALL SELECT 100) AS a ON a.age_category <= t.age_category
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
