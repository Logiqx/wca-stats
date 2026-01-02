/* 
    Script:   Best Single, Worst Average
    Created:  2019-08-10
    Author:   Michael George / 2015GEOR02

    Purpose:  Best single for worst avg, f.e: .74 2x2 single but 7 second average (any puzzle not just 2x2)
    Link:     https://www.facebook.com/groups/439995439706174/permalink/882245468814500/
*/

/*
    Create combined ranks table
*/

DROP TEMPORARY TABLE IF EXISTS ranks_combined;

CREATE TEMPORARY TABLE ranks_combined AS
SELECT s.person_id, s.event_id, s.best AS pr_single, a.best AS pr_average
FROM ranks_single AS s
JOIN ranks_average AS a ON a.person_id = s.person_id AND a.event_id = s.event_id;

ALTER TABLE ranks_combined ADD UNIQUE INDEX ranks_combined_event_id_person_id (event_id, person_id);

/*
    List PR singles where there is nobody with a faster single / slower average
*/

SELECT CONCAT(e.name, ' - ', p.name, ' - ', IF(event_id != '333fm', ROUND(pr_single / 100, 2), pr_single), ' - ', ROUND(pr_average / 100, 2)) AS result
FROM ranks_combined AS c1
JOIN events AS e ON e.id = c1.event_id
JOIN persons AS p ON p.wca_id = c1.person_id
WHERE NOT EXISTS
(
    SELECT 1
    FROM ranks_combined AS c2
    WHERE c2.event_id = c1.event_id
    AND c2.pr_single <= c1.pr_single
    AND c2.pr_average > c1.pr_average
)
ORDER BY event_id, pr_single;

/*
    List PR average where there is nobody with a faster average / slower single
*/

SELECT CONCAT(e.name, ' - ', p.name, ' - ', IF(event_id != '333fm', ROUND(pr_single / 100, 2), pr_single), ' - ', ROUND(pr_average / 100, 2)) AS result
FROM ranks_combined AS c1
JOIN events AS e ON e.id = c1.event_id
JOIN persons AS p ON p.wca_id = c1.person_id
WHERE NOT EXISTS
(
    SELECT 1
    FROM ranks_combined AS c2
    WHERE c2.event_id = c1.event_id
    AND c2.pr_average <= c1.pr_average
    AND c2.pr_single > c1.pr_single
)
ORDER BY event_id, pr_single;

/*
    Experimental query using CTE
*/

WITH cte AS
(
    SELECT s.event_id, s.person_id, s.best AS pr_single, a.best AS pr_average
    FROM ranks_single AS s
    JOIN ranks_average AS a ON a.event_id = s.event_id AND a.person_id = s.person_id
)
SELECT event_id, person_id, IF(event_id != '333fm', ROUND(pr_single / 100, 2), pr_single) AS pr_single, ROUND(pr_average / 100, 2) AS pr_average
FROM cte AS c1
WHERE NOT EXISTS
(
    SELECT 1
    FROM cte AS c2
    WHERE c2.event_id = c1.event_id
    AND c2.pr_single <= c1.pr_single
    AND c2.pr_average > c1.pr_average
)
ORDER BY event_id, pr_single;
