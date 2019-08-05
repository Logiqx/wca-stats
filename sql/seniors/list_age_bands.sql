/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of people in each senior age band - 40+, 50+, 60+, etc
*/

SELECT eventId, age_category, COUNT(DISTINCT personId) AS num_persons
FROM
(
  SELECT r.personId, r.eventId, TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM Persons AS p
  JOIN Results AS r ON r.personId = p.id AND best > 0
  JOIN Competitions AS c ON c.id = r.competitionId
  WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  AND p.subid = 1
  HAVING age_at_comp >= 40
) AS t
JOIN (SELECT 40 AS age_category UNION ALL SELECT 50 UNION ALL SELECT 60 UNION ALL SELECT 70 UNION ALL SELECT 80 UNION ALL SELECT 90 UNION ALL SELECT 100) AS a ON age_category <= age_at_comp
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
