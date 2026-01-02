/* 
    Script:   New Cubers (pre-August)
    Created:  2019-08-05
    Author:   Michael George / 2015GEOR02

    Purpose:  Number of new cubers per year including 2019 only up to the date August 1
    Link:     https://www.facebook.com/groups/439995439706174/permalink/878883005817413/
*/

-- Single step
SELECT LEFT(person_id, 4) AS reg_year, COUNT(DISTINCT person_id) AS num_persons
FROM results AS r
JOIN competitions AS c ON c.id = r.competition_id AND c.year = LEFT(person_id, 4) AND c.month < 8
GROUP BY reg_year
ORDER BY reg_year;

-- Multiple steps... should the query optimizer use a filesort on the whole results table during the above query
CREATE TEMPORARY TABLE tiny_results AS
SELECT DISTINCT person_id, LEFT(person_id, 4) AS reg_year, competition_id
FROM results;

SELECT reg_year, COUNT(DISTINCT person_id) AS num_persons
FROM tiny_results AS r
JOIN competitions AS c ON c.id = r.competition_id AND c.year = reg_year AND c.month < 8
GROUP BY reg_year
ORDER BY reg_year;
