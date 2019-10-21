/* 
    Script:   4BLD at First Comp
    Created:  2019-10-21
    Author:   Michael George / 2015GEOR02

    Purpose:  How many competitors have a 4BLD success at their very first competition?
    Link:     https://www.facebook.com/groups/439995439706174/permalink/935796790126034/
*/

SELECT p.id, p.name, p.countryId, compName, compDate, round, pos, best
FROM
(
    SELECT personId, MIN(DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS firstComp
    FROM Results AS r
    JOIN Competitions AS c ON c.id = r.competitionId
    GROUP BY personId
) AS t1
JOIN (
    SELECT personId, c.name AS compName, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') AS compDate, rt.name AS round, pos, SEC_TO_TIME(best / 100) AS best
    FROM Results AS r
    JOIN Competitions AS c ON c.id = r.competitionId
    JOIN RoundTypes AS rt ON rt.id = r.roundTypeId
    WHERE eventId = '444bf' AND best > 0
) AS t2 ON t2.personId = t1.personId AND t2.compDate = t1.firstComp
JOIN Persons AS p ON p.id = t2.personId
ORDER BY compDate;
