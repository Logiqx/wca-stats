/* 
    Script:   Single Rank / Average Rank
    Created:  2019-08-11
    Author:   Michael George / 2015GEOR02

    Purpose:  highest 10 values of someones single rank / their average rank
    Link:     https://www.facebook.com/groups/439995439706174/permalink/882804448758602/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SELECT CONCAT(e.name, ' - ', t.rank, ' - ', p.name, ' - ', rankSingle, '/', rankAverage, ' (',
    IF(e.id != '333fm', ROUND(bestSingle / 100, 2), bestSingle), ' single, ', ROUND(bestAverage / 100, 2), ' average)') AS result
FROM
(
    SELECT s.personId, s.eventId,
        s.worldRank AS rankSingle, a.worldRank AS rankAverage,
        s.best AS bestSingle, a.best AS bestAverage,
        RANK() OVER (PARTITION BY eventId ORDER BY s.worldRank / a.worldRank DESC) AS rank
    FROM RanksSingle AS s
    JOIN RanksAverage AS a ON a.personId = s.personId AND a.eventId = s.eventId
) AS t
JOIN Events AS e ON e.id = t.eventId
JOIN Persons AS p ON p.id = t.personId
WHERE t.rank <= 10
ORDER BY e.rank, t.rank;
