/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of people in each age band
*/

SELECT age_band, COUNT(DISTINCT personId)
FROM
(
  SELECT DISTINCT personId, FLOOR(age_at_comp / 5) * 5 AS age_band
  FROM
  (
    -- Derived table contains senior results, including age at the start of the competition
    -- Index hint (USE INDEX) ensures that MySQL / MariaDB uses the optimal query execution plan
    -- i.e. Persons ("WHERE" limits to seniors) -> Results.personId -> Competitions.id
    SELECT r.personId,
      TIMESTAMPDIFF(YEAR,
        DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
        DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
    FROM Persons AS p USE INDEX ()
    JOIN Results AS r ON r.personId = p.id AND best > 0
    JOIN Competitions AS c ON c.id = r.competitionId
    WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 30
    AND p.subid = 1
    HAVING age_at_comp >= 30
  ) AS tmp_results
) AS tmp_persons
GROUP BY age_band
ORDER BY age_band;
