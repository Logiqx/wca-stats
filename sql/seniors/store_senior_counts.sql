/* 
    Script:   List Over 40s Counts
    Created:  2019-06-06
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Count the number of people over the age of 40 with competition results, pre-cutoff date
*/

SET @cutoff = '2014-02-01';

SELECT DATE(@cutoff) AS cutoff_date, event_id, result_type, age_category, COUNT(*) AS num_seniors
FROM
(
    SELECT event_id, 'single' AS result_type, person_id,
        MAX(FLOOR(TIMESTAMPDIFF(YEAR,
            DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
            DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS age_category
    FROM wca.results AS r
    INNER JOIN wca.competitions AS c ON r.competition_id = c.id AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') <= @cutoff
    INNER JOIN wca.persons AS p ON r.person_id = p.wca_id AND p.sub_id = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    WHERE best > 0
    GROUP BY event_id, person_id
    HAVING age_category >= 40
    UNION ALL
    SELECT event_id, 'average' AS result_type, person_id,
        MAX(FLOOR(TIMESTAMPDIFF(YEAR,
            DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
            DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) / 10) * 10) AS age_category
    FROM wca.results AS r
    INNER JOIN wca.competitions AS c ON r.competition_id = c.id AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') <= @cutoff
    INNER JOIN wca.persons AS p ON r.person_id = p.wca_id AND p.sub_id = 1 AND p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    WHERE average > 0
    GROUP BY event_id, person_id
    HAVING age_category >= 40
) AS tmp_persons
GROUP BY event_id, result_type, age_category
ORDER BY event_id, result_type, age_category;
