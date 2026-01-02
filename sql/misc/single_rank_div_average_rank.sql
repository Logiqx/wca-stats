/* 
    Script:   Single Rank / Average Rank
    Created:  2019-08-11
    Author:   Michael George / 2015GEOR02

    Purpose:  highest 10 values of someones single rank / their average rank
    Link:     https://www.facebook.com/groups/439995439706174/permalink/882804448758602/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SELECT CONCAT(e.name, ' - ', t.rank, ' - ', p.name, ' - ', rank_single, '/', rank_average, ' (',
    IF(e.id != '333fm', ROUND(best_single / 100, 2), best_single), ' single, ', ROUND(best_average / 100, 2), ' average)') AS result
FROM
(
    SELECT s.person_id, s.event_id,
        s.world_rank AS rank_single, a.world_rank AS rank_average,
        s.best AS best_single, a.best AS best_average,
        RANK() OVER (PARTITION BY event_id ORDER BY s.world_rank / a.world_rank DESC) AS rank
    FROM ranks_single AS s
    JOIN ranks_average AS a ON a.person_id = s.person_id AND a.event_id = s.event_id
) AS t
JOIN events AS e ON e.id = t.event_id
JOIN persons AS p ON p.id = t.person_id
WHERE t.rank <= 10
ORDER BY e.rank, t.rank;
