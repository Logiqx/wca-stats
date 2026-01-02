/* 
    Script:   Most UK Comps
    Created:  2019-10-14
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List competitors who have attended the most UK comps
*/

-- UK comps
SELECT RANK() OVER (ORDER BY num_comps DESC) AS pos, id, CONCAT(name, ' (', country_id, ')'), num_comps
FROM
(
    SELECT p.id, p.name, p.country_id, COUNT(DISTINCT r.competition_id) AS num_comps
    FROM persons AS p
    JOIN results AS r ON r.person_id = p.id
    JOIN competitions AS c ON c.id = r.competition_id AND c.country_id = 'United Kingdom'
    GROUP BY p.id
) AS t
ORDER BY pos;

-- Worldwide comps
SELECT RANK() OVER (ORDER BY num_comps DESC) AS pos, id, CONCAT(name, ' (', country_id, ')'), num_comps
FROM
(
    SELECT p.id, p.name, p.country_id, COUNT(DISTINCT r.competition_id) AS num_comps
    FROM persons AS p
    JOIN results AS r ON r.person_id = p.id
    WHERE p.country_id = 'United Kingdom'
    GROUP BY p.id
) AS t
ORDER BY pos;
