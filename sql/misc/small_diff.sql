/* 
    Script:   Small Difference
    Created:  2019-07-14
    Author:   Michael George / 2015GEOR02

    Purpose:  Top 50, closest single to avg, example... single 13.00 avg 13.11, diff .11
    Link:     https://www.facebook.com/groups/439995439706174/permalink/867419693630411/
*/

SELECT p.name as person_name, e.name AS event_name, ROUND(rs.best / 100, 2) AS pr_single, ROUND(ra.best / 100, 2) AS pr_average, ROUND(ra.best / 100, 2) - ROUND(rs.best / 100, 2) AS diff
FROM ranks_single AS rs
JOIN ranks_average AS ra ON ra.person_id = rs.person_id AND ra.event_id = rs.event_id
JOIN persons AS p ON p.id = rs.person_id
JOIN events AS e ON e.id = rs.event_id
ORDER BY diff
LIMIT 50;
