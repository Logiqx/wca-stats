/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of people in each senior age band - 40+, 50+, 60+, etc
*/

SELECT event_id, age_category, COUNT(DISTINCT person_id) AS num_singles, COUNT(DISTINCT IF(average > 0, person_id, NULL)) AS num_averages
FROM
(
  SELECT r.person_id, r.event_id, r.average, TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM persons AS p
  JOIN results AS r ON r.person_id = p.id AND best > 0
  JOIN competitions AS c ON c.id = r.competition_id
  WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  AND p.sub_id = 1
  HAVING age_at_comp >= 40
) AS t
JOIN (SELECT 40 AS age_category UNION ALL SELECT 50 UNION ALL SELECT 60 UNION ALL SELECT 70 UNION ALL SELECT 80 UNION ALL SELECT 90 UNION ALL SELECT 100) AS a ON age_category <= age_at_comp
GROUP BY event_id, age_category
ORDER BY event_id, age_category;
