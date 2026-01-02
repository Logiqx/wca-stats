/* 
    Script:   4BLD at First Comp
    Created:  2019-10-21
    Author:   Michael George / 2015GEOR02

    Purpose:  How many competitors have a 4BLD success at their very first competition?
    Link:     https://www.facebook.com/groups/439995439706174/permalink/935796790126034/
*/

SELECT p.wca_id, p.name, p.country_id, comp_name, comp_date, round, pos, best
FROM
(
    SELECT person_id, MIN(DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS first_comp
    FROM results AS r
    JOIN competitions AS c ON c.id = r.competition_id
    GROUP BY person_id
) AS t1
JOIN (
    SELECT person_id, c.name AS comp_name, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') AS comp_date, rt.name AS round, pos, SEC_TO_TIME(best / 100) AS best
    FROM results AS r
    JOIN competitions AS c ON c.id = r.competition_id
    JOIN round_types AS rt ON rt.id = r.round_type_id
    WHERE event_id = '444bf' AND best > 0
) AS t2 ON t2.person_id = t1.person_id AND t2.comp_date = t1.first_comp
JOIN persons AS p ON p.wca_id = t2.person_id
ORDER BY comp_date;
