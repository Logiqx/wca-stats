/* 
    Script:   List Over 40s Counts
    Created:  2019-06-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results, pre-cutoff date
*/

SET @cutoff = '2014-02-01';

SELECT DATE(@cutoff) AS cutoffDate, eventId, resultType, ageCategory, COUNT(*) AS numSeniors
FROM
(
    SELECT eventId, 'single' AS resultType, personId,
        MAX(FLOOR(TIMESTAMPDIFF(YEAR,
            DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
            DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS ageCategory
    FROM wca.Results AS r
    INNER JOIN wca.Competitions AS c ON r.competitionId = c.id AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') <= @cutoff
    INNER JOIN wca.Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    WHERE best > 0
    GROUP BY eventId, personId
    HAVING ageCategory >= 40
    UNION ALL
    SELECT eventId, 'average' AS resultType, personId,
        MAX(FLOOR(TIMESTAMPDIFF(YEAR,
            DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
            DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS ageCategory
    FROM wca.Results AS r
    INNER JOIN wca.Competitions AS c ON r.competitionId = c.id AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') <= @cutoff
    INNER JOIN wca.Persons AS p ON r.personId = p.id AND p.subid = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    WHERE average > 0
    GROUP BY eventId, personId
    HAVING ageCategory >= 40
) AS tmp_persons
GROUP BY eventId, resultType, ageCategory
ORDER BY eventId, resultType, ageCategory;
