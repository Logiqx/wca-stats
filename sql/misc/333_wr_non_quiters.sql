/* 
    Script:   3x3x3 WR Non-quiters
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02
   
    Purpose:  3x3 world record progression but every time a person doesn't win 3x3 at a competition they just quit and never compete again
    Link:     https://www.facebook.com/groups/439995439706174/permalink/1037000483338997/
    
    Notes:    Use the field "best" for singles and "average" for erm, everages
    
    Singles:
    - World Rubik's Cube Championship 1982    Minh Thai    Hungary    22.95
    - World Rubik's Games Championship 2003    Dan Knights    Canada    18.76
    - Melbourne Cube Day 2010    Feliks Zemdegs    Australia    6.77
    - Kubaroo Open 2011    Feliks Zemdegs    Australia    6.24
    - Melbourne Winter Open 2011    Feliks Zemdegs    Australia    5.66

    Averages:
    - World Rubik's Games Championship 2003    Dan Knights    Canada    20.00
    - Melbourne Summer Open 2010    Feliks Zemdegs    Australia    9.21
    - New Zealand Championships 2010    Feliks Zemdegs    New Zealand    8.52
    - Melbourne Summer Open 2011    Feliks Zemdegs    Australia    7.87
    - Melbourne Winter Open 2011    Feliks Zemdegs    Australia    7.64
*/

/*
    Identify winners at every competition
*/

DROP TEMPORARY TABLE IF EXISTS Winners;

CREATE TEMPORARY TABLE Winners AS
SELECT competitionId, personId, DATE_FORMAT(CONCAT(c.year + IF(c.endMonth < c.month, 1, 0), '-', c.endMonth, '-', c.endDay), '%Y-%m-%d') AS endDate, best
FROM Results AS r1
JOIN RoundTypes AS rt ON rt.id = roundTypeId AND rt.final = 1
JOIN Competitions AS c ON c.id = competitionId
WHERE eventId = '333'
AND best > 0
AND pos = 1;

ALTER TABLE Winners ADD INDEX Winners_personId_endDate (personId, endDate);

/*
    Identify losers at every competition
*/

DROP TEMPORARY TABLE IF EXISTS Losers;

CREATE TEMPORARY TABLE Losers AS
SELECT DISTINCT competitionId, personId, DATE_FORMAT(CONCAT(c.year + IF(c.endMonth < c.month, 1, 0), '-', c.endMonth, '-', c.endDay), '%Y-%m-%d') AS endDate
FROM wca.Results AS r
JOIN Competitions AS c ON c.id = competitionId
WHERE eventId = '333'
AND NOT EXISTS
(
    SELECT 1
    FROM Winners AS w
    WHERE w.competitionId = r.competitionId
    AND w.personId = r.personId
);

ALTER TABLE Losers ADD INDEX Losers_personId_endDate (personId, endDate);

/*
    The "world records" can only be set by people who haven't "quit"
*/

SELECT c1.name AS compName, p.name AS personName, c2.name AS personCountry, ROUND(best / 100, 2) AS wr
FROM Winners AS w1
JOIN Persons AS p ON p.id = w1.personId
JOIN Competitions AS c1 ON c1.id = w1.competitionId
JOIN Countries AS c2 ON c2.id = c1.countryId
WHERE NOT EXISTS
(
    SELECT 1
    FROM Winners AS w2
    WHERE w2.endDate <= w1.endDate
    AND w2.best < w1.best
)
AND NOT EXISTS
(
    SELECT 1
    FROM Losers AS l
    WHERE l.personId = w1.personId
    AND l.endDate <= w1.endDate
)
ORDER BY endDate;
