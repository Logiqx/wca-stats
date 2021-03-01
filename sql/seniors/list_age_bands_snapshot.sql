/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of known people in each senior age band - 40+, 50+, 60+, etc
*/

SET @cutoff = CURDATE();

SELECT @cutoff AS cutoff, eventId, seq AS age_category, COUNT(DISTINCT personId) AS num_singles, COUNT(DISTINCT IF(average > 0, personId, NULL)) AS num_averages
FROM
(
    SELECT r.personId, r.eventId, r.average, TIMESTAMPDIFF(YEAR,
        DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
        DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
    FROM wca.Persons AS p
    JOIN wca.Results AS r ON r.personId = p.id AND best > 0
    JOIN wca.Competitions AS c ON c.id = r.competitionId AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') < @cutoff
    WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    AND p.subid = 1
    HAVING age_at_comp >= 40
) AS t
JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
GROUP BY eventId, age_category
ORDER BY eventId, age_category;
