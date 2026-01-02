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

DROP TEMPORARY TABLE IF EXISTS senior_ranks;

CREATE TEMPORARY TABLE senior_ranks AS
SELECT event_id, result_type, age_category, person_id, best, RANK() OVER (PARTITION BY event_id, result_type, age_category ORDER BY best) AS rank_no
FROM
(
    -- Additional brackets added for clarity
    (
        -- Actual results
        SELECT event_id, result_type, seq AS age_category, person_id, MIN(best) AS best
        FROM
        (
            SELECT r.event_id, 'average' AS result_type, r.person_id, r.average AS best,
                TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
            FROM seniors AS p
            JOIN wca.results AS r ON r.person_id = p.person_id AND average > 0
            JOIN wca.competitions AS c ON c.id = r.competition_id
            WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
            HAVING age_at_comp >= 40
            UNION ALL
            SELECT r.event_id, 'single' AS result_type, r.person_id, r.best,
                TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp
            FROM seniors AS p
            JOIN wca.results AS r ON r.person_id = p.person_id AND best > 0
            JOIN wca.competitions AS c ON c.id = r.competition_id
            WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
            HAVING age_at_comp >= 40
        ) AS t
        JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
        GROUP BY event_id, result_type, age_category, person_id
    )
    UNION ALL
    (
        -- Fake results
        SELECT sv.event_id, sv.result_type, sv.age_category, fake_id AS person_id, fake_result AS best
        FROM senior_fakes AS sf
        JOIN senior_views AS sv ON sv.view_id = sf.view_id
    )
) AS t;

ALTER TABLE senior_ranks ADD INDEX senior_ranks(event_id, age_category, person_id);

/*
    Combined rankings for seniors - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS senior_ranks_combined;

CREATE TEMPORARY TABLE senior_ranks_combined AS
(
    SELECT person_id, event_id, best
    FROM senior_ranks AS sr1
    WHERE age_category = '40'
    AND result_type = 'average'
    AND event_id NOT IN ('444bf', '555bf')
)
UNION ALL
(
    SELECT person_id, event_id,
        CASE 
            WHEN event_id = '333fm' THEN best * 100
            WHEN event_id = '333mbf' THEN FLOOR(best / 10000000)
            ELSE best
        END AS best
    FROM senior_ranks AS sr2
    WHERE age_category = '40'
    AND result_type = 'single'
    AND NOT EXISTS
    (
        SELECT 1
        FROM senior_ranks AS sr3
        WHERE sr3.event_id NOT IN ('444bf', '555bf')
        AND sr3.event_id = sr2.event_id
        AND sr3.age_category = sr2.age_category
        AND sr3.result_type = 'average'
        AND sr3.person_id = sr2.person_id
    )
);

ALTER TABLE senior_ranks_combined ADD INDEX (event_id);

/*
    Combined rankings for WCA  - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS wca_ranks_combined;

CREATE TEMPORARY TABLE wca_ranks_combined AS
(
    SELECT person_id, event_id, best
    FROM wca.ranks_average AS ra1
    WHERE event_id NOT IN ('444bf', '555bf')
)
UNION ALL
(
    SELECT person_id, event_id,
        CASE 
            WHEN event_id = '333fm' THEN best * 100
            WHEN event_id = '333mbf' THEN FLOOR(best / 10000000)
            ELSE best
        END AS best
    FROM wca.ranks_single AS rs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM wca.ranks_average AS ra2
        WHERE ra2.event_id NOT IN ('444bf', '555bf')
        AND ra2.event_id = rs.event_id
        AND ra2.person_id = rs.person_id
    )
);

ALTER TABLE wca_ranks_combined ADD INDEX (event_id);

/*
    Compare top 5%
*/

SELECT e.name AS event_name,
    CASE
        WHEN e.id = '333fm' THEN ROUND(sr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - sr
        ELSE RIGHT(LEFT(sec_to_time(sr / 100), 11), 8)
    END AS senior_result,
    CASE
        WHEN e.id = '333fm' THEN ROUND(wr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - wr
        ELSE RIGHT(LEFT(sec_to_time(wr / 100), 11), 8)
    END AS wca_result,
    ROUND(sr / wr, 2) AS ratio
FROM wca.events AS e
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS sr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM senior_ranks_combined AS scr
    ) AS t
    WHERE vigintile = 1
    GROUP BY event_id
) AS t1 ON t1.event_id = e.id
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM wca_ranks_combined AS wcr
    ) AS t
    WHERE vigintile = 1
    GROUP BY event_id
) AS t2 ON t2.event_id = t1.event_id
ORDER BY ratio, e.rank;

/*
    Compare all vigintiles
*/

SELECT e.name AS event_name, t1.vigintile * 5 AS vigintile,
    CASE
        WHEN e.id = '333fm' THEN ROUND(sr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - sr
        ELSE RIGHT(LEFT(sec_to_time(sr / 100), 11), 8)
    END AS senior_result,
    CASE
        WHEN e.id = '333fm' THEN ROUND(wr / 100, 2)
        WHEN e.id = '333mbf' THEN 99 - wr
        ELSE RIGHT(LEFT(sec_to_time(wr / 100), 11), 8)
    END AS wca_result,
    ROUND(sr / wr, 2) AS ratio
FROM wca.events AS e
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS sr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM senior_ranks_combined AS scr
    ) AS t
    GROUP BY event_id, vigintile
) AS t1 ON t1.event_id = e.id
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM wca_ranks_combined AS wcr
    ) AS t
    GROUP BY event_id, vigintile
) AS t2 ON t2.event_id = t1.event_id AND t2.vigintile = t1.vigintile
ORDER BY event_name, vigintile;
