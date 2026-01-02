/* 
    Script:   Senior SOR
    Created:  2020-02-16
    Author:   Michael George / 2015GEOR02

    Purpose:  Senior Sum of Ranks (confirming work by Sander Kaspers)

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

/*
    Copy / paste / hack of code from senior rankings - extract_senior_rankings.sql

    Note: This SQL can only be run against the senior rankings database - privately maintained by Michael George
*/

DROP TEMPORARY TABLE IF EXISTS senior_ranks;

CREATE TEMPORARY TABLE senior_ranks AS
SELECT event_id, result_type, seq AS age_category, person_id, hidden, MIN(best) AS best
FROM
(
    SELECT r.event_id, 'average' AS result_type, r.person_id, r.average AS best,
        TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp, hidden
    FROM seniors AS p
    JOIN wca.results AS r ON r.person_id = p.person_id AND average > 0
    JOIN wca.competitions AS c ON c.id = r.competition_id
    WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
    HAVING age_at_comp >= 40
    UNION ALL
    SELECT r.event_id, 'single' AS result_type, r.person_id, r.best,
        TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp, hidden
    FROM seniors AS p
    JOIN wca.results AS r ON r.person_id = p.person_id AND best > 0
    JOIN wca.competitions AS c ON c.id = r.competition_id
    WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
    HAVING age_at_comp >= 40
) AS t
JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
GROUP BY event_id, result_type, age_category, person_id;

ALTER TABLE senior_ranks ADD INDEX senior_ranks(event_id, age_category, person_id);

SELECT seq, num_seniors
FROM seq_1_to_6000 AS s
LEFT JOIN
(
	SELECT floor(best / 100) AS mod_best, COUNT(*) as num_seniors
	FROM senior_ranks
	WHERE event_id = 'skewb'
	AND result_type = 'average'
	GROUP BY mod_best
) AS t ON mod_best = seq;

/*
    Combined rankings for seniors - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS senior_ranks_combined;

CREATE TEMPORARY TABLE senior_ranks_combined AS
(
    SELECT person_id, event_id, RANK() OVER (PARTITION BY event_id ORDER BY best) AS rank_no, best, hidden
    FROM senior_ranks AS sr1
    WHERE age_category = '40'
    AND result_type = 'average'
    -- AND hidden = 'n'
    AND event_id NOT IN ('333fm', '333bf', '444bf', '555bf', '333mbf') -- use singles
    AND event_id NOT IN ('333ft', 'magic', 'mmagic') -- legacy events
)
UNION ALL
(
    SELECT person_id, event_id, RANK() OVER (PARTITION BY event_id ORDER BY best) AS rank_no, best, hidden
    FROM senior_ranks AS sr2
    WHERE age_category = '40'
    -- AND hidden = 'n'
    AND result_type = 'single'
    AND event_id IN ('333fm', '333bf', '444bf', '555bf', '333mbf')
);

ALTER TABLE senior_ranks_combined ADD INDEX (event_id);

/*
    Max Ranks
*/

DROP TEMPORARY TABLE IF EXISTS max_ranks;

CREATE TEMPORARY TABLE max_ranks AS
SELECT event_id, MAX(rank_no) AS max_rank, COUNT(*) AS num_persons
FROM senior_ranks_combined
GROUP BY event_id;

ALTER TABLE max_ranks ADD INDEX (event_id);

SELECT @sum_ranks := SUM(max_rank) AS sum_ranks FROM max_ranks;

DROP TEMPORARY TABLE IF EXISTS event_weights;

CREATE TEMPORARY TABLE event_weights AS
(
	SELECT event_id, 1.00000 * SUM(max_rank) / @sum_ranks AS event_weight
	FROM max_ranks
	GROUP BY event_id
);

SELECT SUM(event_weight)
FROM event_weights;

/*
    The calculations
*/

SELECT sr.event_id, person_id, hidden,
	(max_rank + 1 - rank_no) / @sum_ranks * 10 AS score,
    max_rank / @sum_ranks AS ew,
    (max_rank - rank_no + 1) / max_rank * 100 AS up,
    (max_rank - rank_no + 1) / max_rank * 100 * max_rank / (@sum_ranks * 100) AS wp
FROM senior_ranks_combined AS sr
JOIN max_ranks AS mr ON mr.event_id = sr.event_id;

SELECT t.*, p.name, p.country_id
FROM
(
	SELECT RANK() OVER (ORDER BY score DESC) as rank_no, t.*
	FROM
	(
		SELECT person_id, hidden, SUM(1.0000 * (max_rank + 1 - rank_no) / @sum_ranks * 10) AS score,
			SUM((max_rank - rank_no + 1) / max_rank * 100 * max_rank / (@sum_ranks * 100)) AS score2
		FROM senior_ranks_combined AS sr
		JOIN max_ranks AS mr ON mr.event_id = sr.event_id
		GROUP BY person_id
	) AS t
	ORDER BY rank_no
) AS t
JOIN wca.persons AS p ON p.wca_id = t.person_id
WHERE hidden = 'n';