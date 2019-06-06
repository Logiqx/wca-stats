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
    SELECT r.personId,
      TIMESTAMPDIFF(YEAR,
        DATE_FORMAT(CONCAT(p.year, "-", p.month, "-", p.day), "%Y-%m-%d"),
        DATE_FORMAT(CONCAT(c.year, "-", c.month, "-", c.day), "%Y-%m-%d")) AS age_at_comp
    FROM Results AS r
    INNER JOIN Competitions AS c ON r.competitionId = c.id
    INNER JOIN Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 20
    WHERE best > 0
    HAVING age_at_comp >= 20
  ) AS tmp_results
) AS tmp_persons
GROUP BY age_band
ORDER BY age_band;
