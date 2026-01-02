/* 
    Script:   UK cutoffs
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Analyse the UK cutoffs

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SET @country_id = 'United Kingdom';
SET @continent_id = '_Europe';


/*
    Determine cutoffs for current year
*/

DROP TEMPORARY TABLE IF EXISTS cutoffs;

CREATE TEMPORARY TABLE cutoffs AS
SELECT country_id, year, event_id AS event_id, CAST(JSON_EXTRACT(cutoff, "$.attempt_result") AS DECIMAL(10,0)) AS c_secs, COUNT(*) AS num_comps
FROM wca_dev.rounds AS r
JOIN wca_dev.competition_events AS ce ON ce.id = competition_event_id
JOIN wca_dev.competitions AS c ON c.id = competition_id
JOIN wca_dev.formats AS f ON f.id = format_id
WHERE number = 1
AND cutoff IS NOT NULL
AND year = YEAR(CURDATE())
GROUP BY country_id, event_id, year, c_secs;

ALTER TABLE cutoffs ADD INDEX cutoffs(country_id, event_id);

/*
    Summarise cutoffs for current year
*/

SELECT *
FROM cutoffs
WHERE num_comps > 1
ORDER BY event_id, c_secs, country_id;

SELECT year, event_id, c_secs, num_comps,
	SUM(num_comps) OVER (PARTITION BY year, event_id ORDER BY c_secs ROWS UNBOUNDED PRECEDING) AS cum_comps,
    ROUND(100 * SUM(num_comps) OVER (PARTITION BY year, event_id ORDER BY c_secs ROWS UNBOUNDED PRECEDING) / SUM(num_comps) OVER (PARTITION BY year, event_id), 2) AS pct_comps
FROM
(
	SELECT year, event_id, c_secs, SUM(num_comps) AS num_comps
	FROM cutoffs
	WHERE num_comps > 1
	GROUP BY event_id, c_secs
) AS t
ORDER BY event_id, c_secs;

/*
    Compare cutoffs to WR/CR/NR
*/

SELECT year, e.name AS event_name, RIGHT(LEFT(sec_to_time(c_secs / 100), 8), 5) AS cutoff,
    ROUND(c_secs / wr, 2) AS ratio_wr, ROUND(c_secs / cr, 2) AS ratio_cr, ROUND(c_secs / nr, 2) AS ratio_nr, num_comps
FROM cutoffs AS c
JOIN
(
    SELECT event_id, MIN(best) AS wr
    FROM wca_dev.ranks_average
    GROUP BY event_id
) AS t2 ON t2.event_id = c.event_id
JOIN
(
    SELECT event_id, MIN(best) AS cr
    FROM wca_dev.ranks_average AS ra
    JOIN wca_dev.persons AS p ON p.id = ra.person_id
    JOIN wca_dev.countries AS c ON c.id = p.country_id
    WHERE c.continent_id = @continent_id
    GROUP BY event_id
) AS t3 ON t3.event_id = c.event_id
JOIN
(
    SELECT event_id, MIN(best) AS nr
    FROM wca_dev.ranks_average AS ra
    JOIN wca_dev.persons AS p ON p.id = ra.person_id
    WHERE p.country_id = @country_id
    GROUP BY event_id
) AS t4 ON t4.event_id = c.event_id
JOIN wca_dev.events AS e ON e.id = c.event_id
WHERE country_id = @country_id
ORDER BY ratio_wr DESC, e.rank;

/*
    Compare cutoffs to top 5% of the WCA averages (excludes people with just a single)
*/

SELECT year, e.name AS event_name, RIGHT(LEFT(sec_to_time(c_secs / 100), 8), 5) AS cutoff,
    ROUND(c_secs / wr, 2) AS ratio_wr, ROUND(c_secs / cr, 2) AS ratio_cr, ROUND(c_secs / nr, 2) AS ratio_nr, num_comps
FROM cutoffs AS c
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM wca_dev.ranks_average AS ra
    ) AS t
    WHERE vigintile = 1
    GROUP BY event_id
) AS t2 ON t2.event_id = c.event_id
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS cr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM wca_dev.ranks_average AS ra
        JOIN wca_dev.persons AS p ON p.id = ra.person_id
        JOIN wca_dev.countries AS c ON c.id = p.country_id
        WHERE c.continent_id = @continent_id
    ) AS t
    WHERE vigintile = 1
    GROUP BY event_id
) AS t3 ON t3.event_id = c.event_id
JOIN
(
    SELECT event_id, vigintile, MAX(best) AS nr
    FROM
    (
        SELECT event_id, NTILE(20) OVER (PARTITION BY event_id ORDER BY best) AS vigintile, best
        FROM wca_dev.ranks_average AS ra
        JOIN wca_dev.persons AS p ON p.id = ra.person_id
        WHERE p.country_id = @country_id
    ) AS t
    WHERE vigintile = 1
    GROUP BY event_id
) AS t4 ON t4.event_id = c.event_id
JOIN wca_dev.events AS e ON e.id = c.event_id
WHERE country_id = @country_id
ORDER BY ratio_wr DESC, e.rank;

/*
    Determine percentile of all of the cutoffs
    
    Note: Needs to be run after senior_ratios.sql which creates senior_ranks_combined and wca_ranks_combined
          Link - https://github.com/Logiqx/wca-stats/blob/master/sql/seniors/senior_ratios.sql
*/

SELECT c.event_id,
    RIGHT(LEFT(sec_to_time(c_secs / 100), 8), 5) AS cutoff,
    ROUND(100 * t1.centile, 1) AS senior_centile, ROUND(100 * t2.centile, 1) AS world_centile
FROM cutoffs AS c
JOIN
(
    SELECT c.event_id, MAX(t.centile) AS centile
    FROM cutoffs AS c
    JOIN
    (
        SELECT event_id, CUME_DIST() OVER (PARTITION BY event_id ORDER BY best) AS centile, best
        FROM senior_ranks_combined
    ) AS t ON t.event_id = c.event_id AND t.best < c.c_secs
    WHERE country_id = @country_id
    GROUP BY c.event_id
) AS t1 ON t1.event_id = c.event_id
JOIN
(
    SELECT c.event_id, MAX(t.centile) AS centile
    FROM cutoffs AS c
    JOIN
    (
        SELECT event_id, CUME_DIST() OVER (PARTITION BY event_id ORDER BY best) AS centile, best
        FROM wca_ranks_combined
    ) AS t ON t.event_id = c.event_id AND t.best < c.c_secs
    WHERE country_id = @country_id
    GROUP BY c.event_id
) AS t2 ON t2.event_id = c.event_id
JOIN wca_dev.events AS e ON e.id = c.event_id
WHERE country_id = @country_id
ORDER BY senior_centile DESC;
