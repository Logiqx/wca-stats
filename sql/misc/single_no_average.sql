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
    SELECT s.*, RANK() OVER (PARTITION BY event_id ORDER BY best) AS rank
    FROM ranks_single AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ranks_average AS a
        WHERE a.person_id = s.person_id AND a.event_id = s.event_id
    )
) AS t
JOIN events AS e ON e.id = t.event_id
JOIN persons AS p ON p.id = t.person_id
WHERE t.rank = 1
ORDER BY e.rank;
