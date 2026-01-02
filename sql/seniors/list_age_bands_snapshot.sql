/* 
    Script:   List age bands
    Created:  2019-02-19
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List the number of known people in each senior age band - 40+, 50+, 60+, etc
*/

SET @cutoff = CURDATE();

SELECT @cutoff AS cutoff, event_id, seq AS age_category, COUNT(DISTINCT person_id) AS num_singles, COUNT(DISTINCT IF(average > 0, person_id, NULL)) AS num_averages
FROM
(
    SELECT r.person_id, r.event_id, r.average, TIMESTAMPDIFF(YEAR,
        DATE_FORMAT(CONCAT(p.year, '-', p.month, '-', p.day), '%Y-%m-%d'),
        DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
    FROM wca.persons AS p
    JOIN wca.results AS r ON r.person_id = p.id AND best > 0
    JOIN wca.competitions AS c ON c.id = r.competition_id AND DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') < @cutoff
    WHERE p.year > 0 AND p.year <= YEAR(CURDATE()) - 40
    AND p.sub_id = 1
    HAVING age_at_comp >= 40
) AS t
JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
GROUP BY event_id, age_category
ORDER BY event_id, age_category;
