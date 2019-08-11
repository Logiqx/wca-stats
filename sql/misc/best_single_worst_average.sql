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

DROP TEMPORARY TABLE IF EXISTS RanksCombined;

CREATE TEMPORARY TABLE RanksCombined AS
SELECT s.personId, s.eventId, s.best AS pr_single, a.best AS pr_average
FROM RanksSingle AS s
JOIN RanksAverage AS a ON a.personId = s.personId AND a.eventId = s.eventId;

ALTER TABLE RanksCombined ADD UNIQUE INDEX RanksCombined_eventId_personId (eventId, personId);

/*
    List PR singles where there is nobody with a faster single / slower average
*/

SELECT CONCAT(e.name, ' - ', p.name, ' - ', IF(eventId != '333fm', ROUND(pr_single / 100, 2), pr_single), ' - ', ROUND(pr_average / 100, 2)) AS result
FROM RanksCombined AS c1
JOIN Events AS e ON e.id = c1.eventId
JOIN Persons AS p ON p.id = c1.personId
WHERE NOT EXISTS
(
	SELECT 1
    FROM RanksCombined AS c2
    WHERE c2.eventId = c1.eventId
 	AND c2.pr_single <= c1.pr_single
    AND c2.pr_average > c1.pr_average
)
ORDER BY eventId, pr_single;

/*
    List PR average where there is nobody with a faster average / slower single
*/

SELECT CONCAT(e.name, ' - ', p.name, ' - ', IF(eventId != '333fm', ROUND(pr_single / 100, 2), pr_single), ' - ', ROUND(pr_average / 100, 2)) AS result
FROM RanksCombined AS c1
JOIN Events AS e ON e.id = c1.eventId
JOIN Persons AS p ON p.id = c1.personId
WHERE NOT EXISTS
(
	SELECT 1
    FROM RanksCombined AS c2
    WHERE c2.eventId = c1.eventId
    AND c2.pr_average <= c1.pr_average
 	AND c2.pr_single > c1.pr_single
)
ORDER BY eventId, pr_single;

/*
    Experimental query using CTE
*/

WITH cte AS
(
	SELECT s.eventId, s.personId, s.best AS pr_single, a.best AS pr_average
    FROM RanksSingle AS s
    JOIN RanksAverage AS a ON a.eventId = s.eventId AND a.personId = s.personId
)
SELECT eventId, personId, IF(eventId != '333fm', ROUND(pr_single / 100, 2), pr_single) AS pr_single, ROUND(pr_average / 100, 2) AS pr_average
FROM cte AS c1
WHERE NOT EXISTS
(
	SELECT 1
    FROM cte AS c2
    WHERE c2.eventId = c1.eventId
	AND c2.pr_single <= c1.pr_single
    AND c2.pr_average > c1.pr_average
)
ORDER BY eventId, pr_single;
