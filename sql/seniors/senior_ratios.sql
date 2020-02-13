/* 
    Script:   Senior Ratios
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Compare the top 5% of seniors against the top 5% of the WCA
    Link:     https://www.facebook.com/groups/1604105099735401/permalink/2141271242685448/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

/*
    Copy / paste of code from senior rankings - extract_senior_rankings.sql

    Note: This SQL can only be run against the senior rankings database - privately maintained by Michael George
*/

DROP TEMPORARY TABLE IF EXISTS SeniorRanks;

CREATE TEMPORARY TABLE SeniorRanks AS
SELECT eventId, resultType, ageCategory, personId, best, RANK() OVER (PARTITION BY eventId, resultType, ageCategory ORDER BY best) AS rankNo
FROM
(
    -- Additional brackets added for clarity
    (
        -- Actual results
        SELECT eventId, resultType, seq AS ageCategory, personId, MIN(best) AS best
        FROM
        (
            SELECT r.eventId, 'average' AS resultType, r.personId, r.average AS best,
                TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
            FROM Seniors AS p
            JOIN wca.Results AS r ON r.personId = p.personId AND average > 0
            JOIN wca.Competitions AS c ON c.id = r.competitionId
            WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
            HAVING age_at_comp >= 40
            UNION ALL
            SELECT r.eventId, 'single' AS resultType, r.personId, r.best,
                TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
            FROM Seniors AS p
            JOIN wca.Results AS r ON r.personId = p.personId AND best > 0
            JOIN wca.Competitions AS c ON c.id = r.competitionId
            WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
            HAVING age_at_comp >= 40
        ) AS t
        JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
        GROUP BY eventId, resultType, ageCategory, personId
    )
    UNION ALL
    (
        -- Fake results
        SELECT sv.eventId, sv.resultType, sv.ageCategory, fakeId AS personId, fakeResult AS best
        FROM SeniorFakes AS sf
        JOIN SeniorViews AS sv ON sv.viewId = sf.viewId
    )
) AS t;

ALTER TABLE SeniorRanks ADD INDEX SeniorRanks(eventId, ageCategory, personId);

/*
    Combined rankings for seniors - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS SeniorRanksCombined;

CREATE TEMPORARY TABLE SeniorRanksCombined AS
(
    SELECT personId, eventId, best
    FROM SeniorRanks AS sr1
    WHERE ageCategory = '40'
    AND resultType = 'average'
    AND eventId NOT IN ('444bf', '555bf')
)
UNION ALL
(
    SELECT personId, eventId,
        CASE 
            WHEN eventId = '333fm' THEN best * 100
            WHEN eventId = '333mbf' THEN FLOOR(best / 10000000)
            ELSE best
        END AS best
    FROM SeniorRanks AS sr2
    WHERE ageCategory = '40'
    AND resultType = 'single'
    AND NOT EXISTS
    (
        SELECT 1
        FROM SeniorRanks AS sr3
        WHERE sr3.eventId NOT IN ('444bf', '555bf')
        AND sr3.eventId = sr2.eventId
        AND sr3.ageCategory = sr2.ageCategory
        AND sr3.resultType = 'average'
        AND sr3.personId = sr2.personId
    )
);

ALTER TABLE SeniorRanksCombined ADD INDEX (eventId);

/*
    Combined rankings for WCA  - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS WcaRanksCombined;

CREATE TEMPORARY TABLE WcaRanksCombined AS
(
    SELECT personId, eventId, best
    FROM wca.RanksAverage AS ra1
    WHERE eventId NOT IN ('444bf', '555bf')
)
UNION ALL
(
    SELECT personId, eventId,
        CASE 
            WHEN eventId = '333fm' THEN best * 100
            WHEN eventId = '333mbf' THEN FLOOR(best / 10000000)
            ELSE best
        END AS best
    FROM wca.RanksSingle AS rs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM wca.RanksAverage AS ra2
        WHERE ra2.eventId NOT IN ('444bf', '555bf')
        AND ra2.eventId = rs.eventId
        AND ra2.personId = rs.personId
    )
);

ALTER TABLE WcaRanksCombined ADD INDEX (eventId);

/*
    Compare top 5%
*/

SELECT e.name AS eventName,
    CASE
        WHEN e.id = '333fm' THEN ROUND(sr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - sr
        ELSE RIGHT(LEFT(sec_to_time(sr / 100), 11), 8)
    END AS seniorResult,
    CASE
        WHEN e.id = '333fm' THEN ROUND(wr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - wr
        ELSE RIGHT(LEFT(sec_to_time(wr / 100), 11), 8)
    END AS wcaResult,
    ROUND(sr / wr, 2) AS ratio
FROM wca.Events AS e
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS sr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM SeniorRanksCombined AS scr
    ) AS t
    WHERE vigintile = 1
    GROUP BY eventId
) AS t1 ON t1.eventId = e.id
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM WcaRanksCombined AS wcr
    ) AS t
    WHERE vigintile = 1
    GROUP BY eventId
) AS t2 ON t2.eventId = t1.eventId
ORDER BY ratio, e.rank;

/*
    Compare all vigintiles
*/

SELECT e.name AS eventName, t1.vigintile * 5 AS vigintile,
    CASE
        WHEN e.id = '333fm' THEN ROUND(sr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - sr
        ELSE RIGHT(LEFT(sec_to_time(sr / 100), 11), 8)
    END AS seniorResult,
    CASE
        WHEN e.id = '333fm' THEN ROUND(wr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - wr
        ELSE RIGHT(LEFT(sec_to_time(wr / 100), 11), 8)
    END AS wcaResult,
    ROUND(sr / wr, 2) AS ratio
FROM wca.Events AS e
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS sr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM SeniorRanksCombined AS scr
    ) AS t
    GROUP BY eventId, vigintile
) AS t1 ON t1.eventId = e.id
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM WcaRanksCombined AS wcr
    ) AS t
    GROUP BY eventId, vigintile
) AS t2 ON t2.eventId = t1.eventId AND t2.vigintile = t1.vigintile
ORDER BY eventName, vigintile;
