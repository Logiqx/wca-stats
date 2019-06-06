/* 
    Script:   Extract Over 40s Counts
    Created:  2019-06-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results
*/

SELECT eventId, COUNT(DISTINCT singleId) AS numSingleIds, COUNT(DISTINCT averageId) AS numAverageIds
FROM
(
  SELECT r.eventId, r.personId AS singleId, IF(average > 0, personId, NULL) AS averageId,
    TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
  FROM Results AS r
  INNER JOIN Competitions AS c ON r.competitionId = c.id
  INNER JOIN Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  HAVING age_at_comp >= 40
) AS tmp_persons
GROUP BY eventId
ORDER BY numSingleIds DESC, numAverageIds DESC;
