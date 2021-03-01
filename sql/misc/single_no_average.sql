/* 
    Script:   Single No Average
    Created:  2019-08-10
    Author:   Michael George / 2015GEOR02

    Purpose:  Fastest single without average/mean (for every event)
    Link:     https://www.facebook.com/groups/439995439706174/permalink/881784605527253/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SELECT CONCAT(e.name, ' - ', p.name, ' - ', IF(e.id != '333fm', ROUND(t.best / 100, 2), t.best)) AS result
FROM
(
    SELECT s.*, RANK() OVER (PARTITION BY eventId ORDER BY best) AS rank
    FROM RanksSingle AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM RanksAverage AS a
        WHERE a.personId = s.personId AND a.eventId = s.eventId
    )
) AS t
JOIN Events AS e ON e.id = t.eventId
JOIN Persons AS p ON p.id = t.personId
WHERE t.rank = 1
ORDER BY e.rank;
