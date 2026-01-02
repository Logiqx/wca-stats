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

DROP TEMPORARY TABLE IF EXISTS winners;

CREATE TEMPORARY TABLE winners AS
SELECT competition_id, person_id, DATE_FORMAT(CONCAT(c.year + IF(c.end_month < c.month, 1, 0), '-', c.end_month, '-', c.end_day), '%Y-%m-%d') AS end_date, best
FROM results AS r1
JOIN round_types AS rt ON rt.id = round_type_id AND rt.final = 1
JOIN competitions AS c ON c.id = competition_id
WHERE event_id = '333'
AND best > 0
AND pos = 1;

ALTER TABLE winners ADD INDEX winners_person_id_end_date (person_id, end_date);

/*
    Identify losers at every competition
*/

DROP TEMPORARY TABLE IF EXISTS losers;

CREATE TEMPORARY TABLE losers AS
SELECT DISTINCT competition_id, person_id, DATE_FORMAT(CONCAT(c.year + IF(c.end_month < c.month, 1, 0), '-', c.end_month, '-', c.end_day), '%Y-%m-%d') AS end_date
FROM wca.results AS r
JOIN competitions AS c ON c.id = competition_id
WHERE event_id = '333'
AND NOT EXISTS
(
    SELECT 1
    FROM winners AS w
    WHERE w.competition_id = r.competition_id
    AND w.person_id = r.person_id
);

ALTER TABLE losers ADD INDEX losers_person_id_end_date (person_id, end_date);

/*
    The "world records" can only be set by people who haven't "quit"
*/

SELECT c1.name AS comp_name, p.name AS person_name, c2.name AS person_country, ROUND(best / 100, 2) AS wr
FROM winners AS w1
JOIN persons AS p ON p.id = w1.person_id
JOIN competitions AS c1 ON c1.id = w1.competition_id
JOIN countries AS c2 ON c2.id = c1.country_id
WHERE NOT EXISTS
(
    SELECT 1
    FROM winners AS w2
    WHERE w2.end_date <= w1.end_date
    AND w2.best < w1.best
)
AND NOT EXISTS
(
    SELECT 1
    FROM losers AS l
    WHERE l.person_id = w1.person_id
    AND l.end_date <= w1.end_date
)
ORDER BY end_date;
