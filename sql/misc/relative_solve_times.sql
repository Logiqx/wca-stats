/* 
    Script:   Relative Solve Times
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Compare relative solve times across events
    Link:     https://www.speedsolving.com/threads/relative-solve-times-for-2x2x2-7x7x7.47405/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

/*
    Combined rankings - average where it exists (except BLD events), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS RanksCombined;

CREATE TEMPORARY TABLE RanksCombined AS
(
    SELECT eventId, personId, best
    FROM RanksAverage
    WHERE eventId NOT IN ('333bf', '444bf', '555bf')
)
UNION ALL
(
    SELECT eventId, personId, best
    FROM RanksSingle AS rs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM RanksAverage AS ra2
        WHERE ra2.eventId NOT IN ('333bf', '444bf', '555bf')
        AND ra2.eventId = rs.eventId
        AND ra2.personId = rs.personId
    )
);

ALTER TABLE RanksCombined ADD PRIMARY KEY (eventId, personId);

/*
    Add vigintiles
*/

DROP TEMPORARY TABLE IF EXISTS RanksCombinedExtra;

CREATE TEMPORARY TABLE RanksCombinedExtra AS
SELECT eventId, personId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
FROM RanksCombined;

ALTER TABLE RanksCombinedExtra ADD PRIMARY KEY (eventId, personId);

/*
    Define the event comparisons
*/

DROP TEMPORARY TABLE IF EXISTS EventComparisons;

CREATE TEMPORARY TABLE EventComparisons
(
    `eventId` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
    `baseId` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL
);

INSERT INTO EventComparisons VALUES
('222', '333'), ('444', '333'), ('555', '444'), ('666', '555'), ('777', '666'),
('pyram', '333'), ('skewb', '333'), ('clock', '333'), ('sq1', '333'), ('minx', '333'),
('333oh', '333'), ('333ft', '333'), ('333bf', '333'), ('444bf', '444'), ('555bf', '555');

/*
    Do the event comparisons
*/

SELECT e.name AS eventName, vigintile * 5 AS centile,
    RIGHT(LEFT(sec_to_time(AVG(rce.best) / 100), 11), 8) AS avg1,
    RIGHT(LEFT(sec_to_time(AVG(rc.best) / 100), 11), 8) AS avg2,
    AVG(rce.best) / AVG(rc.best) AS ratio
FROM EventComparisons AS ec
JOIN Events AS e ON e.id = ec.eventId
JOIN RanksCombinedExtra AS rce ON rce.eventId = ec.eventId
JOIN RanksCombined AS rc ON rc.eventId = ec.baseId AND rc.personId = rce.personId
GROUP BY e.id, centile
ORDER BY e.rank, centile;
