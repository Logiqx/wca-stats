/* 
    Script:   New Cubers (pre-August)
    Created:  2019-08-05
    Author:   Michael George / 2015GEOR02

    Purpose:  Number of new cubers per year including 2019 only up to the date August 1
    Link:     https://www.facebook.com/groups/439995439706174/permalink/878883005817413/
*/

-- Single step
SELECT LEFT(personId, 4) AS regYear, COUNT(DISTINCT personId) AS numPersons
FROM Results AS r
JOIN Competitions AS c ON c.id = r.competitionId AND c.year = LEFT(personId, 4) AND c.month < 8
GROUP BY regYear
ORDER BY regYear;

-- Multiple steps... should the query optimizer use a filesort on the whole results table during the above query
CREATE TEMPORARY TABLE TinyResults AS
SELECT DISTINCT personId, LEFT(personId, 4) AS regYear, competitionId
FROM Results;

SELECT regYear, COUNT(DISTINCT personId) AS numPersons
FROM TinyResults AS r
JOIN Competitions AS c ON c.id = r.competitionId AND c.year = regYear AND c.month < 8
GROUP BY regYear
ORDER BY regYear;
