/* 
    Script:   Small Difference
    Created:  2019-07-14
    Author:   Michael George / 2015GEOR02

    Purpose:  Top 50, closest single to avg, example... single 13.00 avg 13.11, diff .11
    Link:     https://www.facebook.com/groups/439995439706174/permalink/867419693630411/
*/

SELECT p.name as personName, e.name AS eventName, ROUND(rs.best / 100, 2) AS prSingle, ROUND(ra.best / 100, 2) AS prAverage, ROUND(ra.best / 100, 2) - ROUND(rs.best / 100, 2) AS diff
FROM RanksSingle AS rs
JOIN RanksAverage AS ra ON ra.personId = rs.personId AND ra.eventId = rs.eventId
JOIN Persons AS p ON p.id = rs.personId
JOIN Events AS e ON e.id = rs.eventId
ORDER BY diff
LIMIT 50;
