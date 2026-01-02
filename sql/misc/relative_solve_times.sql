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

DROP TEMPORARY TABLE IF EXISTS ranks_combined;

CREATE TEMPORARY TABLE ranks_combined AS
(
    SELECT event_id, person_id, best
    FROM ranks_average
    WHERE event_id NOT IN ('333bf', '444bf', '555bf')
)
UNION ALL
(
    SELECT event_id, person_id, best
    FROM ranks_single AS rs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM ranks_average AS ra2
        WHERE ra2.event_id NOT IN ('333bf', '444bf', '555bf')
        AND ra2.event_id = rs.event_id
        AND ra2.person_id = rs.person_id
    )
);

ALTER TABLE ranks_combined ADD PRIMARY KEY (event_id, person_id);

/*
    Add vigintiles
*/

DROP TEMPORARY TABLE IF EXISTS ranks_combined_extra;

CREATE TEMPORARY TABLE ranks_combined_extra AS
SELECT event_id, person_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
FROM ranks_combined;

ALTER TABLE ranks_combined_extra ADD PRIMARY KEY (event_id, person_id);

/*
    Define the event comparisons
*/

DROP TEMPORARY TABLE IF EXISTS event_comparisons;

CREATE TEMPORARY TABLE event_comparisons
(
    `event_id` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
    `base_id` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL
);

INSERT INTO event_comparisons VALUES
('222', '333'), ('444', '333'), ('555', '444'), ('666', '555'), ('777', '666'),
('pyram', '333'), ('skewb', '333'), ('clock', '333'), ('sq1', '333'), ('minx', '333'),
('333oh', '333'), ('333ft', '333'), ('333bf', '333'), ('444bf', '444'), ('555bf', '555');

/*
    Do the event comparisons
*/

SELECT e.name AS event_name, vigintile * 5 AS centile,
    RIGHT(LEFT(sec_to_time(AVG(rce.best) / 100), 11), 8) AS avg1,
    RIGHT(LEFT(sec_to_time(AVG(rc.best) / 100), 11), 8) AS avg2,
    AVG(rce.best) / AVG(rc.best) AS ratio
FROM event_comparisons AS ec
JOIN events AS e ON e.id = ec.event_id
JOIN ranks_combined_extra AS rce ON rce.event_id = ec.event_id
JOIN ranks_combined AS rc ON rc.event_id = ec.base_id AND rc.person_id = rce.person_id
GROUP BY e.id, centile
ORDER BY e.rank, centile;
