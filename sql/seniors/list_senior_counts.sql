/* 
    Script:   List Over 40s Counts
    Created:  2019-06-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results
*/

SELECT eventId, resultType, ageCategory, COUNT(*)
FROM
(
  SELECT eventId, 'single' AS resultType, personId,
    MAX(FLOOR(TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS ageCategory
  FROM Results AS r
  INNER JOIN Competitions AS c ON r.competitionId = c.id
  INNER JOIN Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  WHERE best > 0
  GROUP BY eventId, personId
  HAVING ageCategory >= 40
  UNION ALL
  SELECT eventId, 'average' AS resultType, personId,
    MAX(FLOOR(TIMESTAMPDIFF(YEAR,
      DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
      DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS ageCategory
  FROM Results AS r
  INNER JOIN Competitions AS c ON r.competitionId = c.id
  INNER JOIN Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
  WHERE average > 0
  GROUP BY eventId, personId
  HAVING ageCategory >= 40
) AS tmp_persons
GROUP BY eventId, resultType, ageCategory
ORDER BY eventId, resultType, ageCategory;
