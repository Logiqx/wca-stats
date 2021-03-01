/* 
    Script:   UK cutoffs
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Analyse the UK cutoffs

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SET @countryId = 'United Kingdom';
SET @continentId = '_Europe';


/*
    Determine cutoffs for current year
*/

DROP TEMPORARY TABLE IF EXISTS cutoffs;

CREATE TEMPORARY TABLE cutoffs AS
SELECT countryId, year, event_id AS eventId, CAST(JSON_EXTRACT(cutoff, "$.attemptResult") AS DECIMAL(10,0)) AS csecs, COUNT(*) AS numComps
FROM wca_dev.rounds AS r
JOIN wca_dev.competition_events AS ce ON ce.id = competition_event_id
JOIN wca_dev.Competitions AS c ON c.id = competition_id
JOIN wca_dev.Formats AS f ON f.id = format_id
WHERE number = 1
AND cutoff IS NOT NULL
AND year = YEAR(CURDATE())
GROUP BY countryId, event_id, year, csecs;

ALTER TABLE cutoffs ADD INDEX cutoffs(countryId, eventId);

/*
    Summarise cutoffs for current year
*/

SELECT *
FROM cutoffs
WHERE numComps > 1
ORDER BY eventId, csecs, countryId;

SELECT year, eventId, csecs, numComps,
	SUM(numComps) OVER (PARTITION BY year, eventId ORDER BY csecs ROWS UNBOUNDED PRECEDING) AS cumComps,
    ROUND(100 * SUM(numComps) OVER (PARTITION BY year, eventId ORDER BY csecs ROWS UNBOUNDED PRECEDING) / SUM(numComps) OVER (PARTITION BY year, eventId), 2) AS pctComps
FROM
(
	SELECT year, eventId, csecs, SUM(numComps) AS numComps
	FROM cutoffs
	WHERE numComps > 1
	GROUP BY eventId, csecs
) AS t
ORDER BY eventId, csecs;

/*
    Compare cutoffs to WR/CR/NR
*/

SELECT year, e.name AS eventName, RIGHT(LEFT(sec_to_time(csecs / 100), 8), 5) AS cutoff,
    ROUND(csecs / wr, 2) AS ratioWr, ROUND(csecs / cr, 2) AS ratioCr, ROUND(csecs / nr, 2) AS ratioNr, numComps
FROM cutoffs AS c
JOIN
(
    SELECT eventId, MIN(best) AS wr
    FROM wca_dev.RanksAverage
    GROUP BY eventId
) AS t2 ON t2.eventId = c.eventId
JOIN
(
    SELECT eventId, MIN(best) AS cr
    FROM wca_dev.RanksAverage AS ra
    JOIN wca_dev.Persons AS p ON p.id = ra.personId
    JOIN wca_dev.Countries AS c ON c.id = p.countryId
    WHERE c.continentId = @continentId
    GROUP BY eventId
) AS t3 ON t3.eventId = c.eventId
JOIN
(
    SELECT eventId, MIN(best) AS nr
    FROM wca_dev.RanksAverage AS ra
    JOIN wca_dev.Persons AS p ON p.id = ra.personId
    WHERE p.countryId = @countryId
    GROUP BY eventId
) AS t4 ON t4.eventId = c.eventId
JOIN wca_dev.Events AS e ON e.id = c.eventId
WHERE countryId = @countryId
ORDER BY ratioWr DESC, e.rank;

/*
    Compare cutoffs to top 5% of the WCA averages (excludes people with just a single)
*/

SELECT year, e.name AS eventName, RIGHT(LEFT(sec_to_time(csecs / 100), 8), 5) AS cutoff,
    ROUND(csecs / wr, 2) AS ratioWr, ROUND(csecs / cr, 2) AS ratioCr, ROUND(csecs / nr, 2) AS ratioNr, numComps
FROM cutoffs AS c
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS wr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM wca_dev.RanksAverage AS ra
    ) AS t
    WHERE vigintile = 1
    GROUP BY eventId
) AS t2 ON t2.eventId = c.eventId
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS cr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM wca_dev.RanksAverage AS ra
        JOIN wca_dev.Persons AS p ON p.id = ra.personId
        JOIN wca_dev.Countries AS c ON c.id = p.countryId
        WHERE c.continentId = @continentId
    ) AS t
    WHERE vigintile = 1
    GROUP BY eventId
) AS t3 ON t3.eventId = c.eventId
JOIN
(
    SELECT eventId, vigintile, MAX(best) AS nr
    FROM
    (
        SELECT eventId, NTILE(20) OVER (PARTITION BY eventId ORDER BY best) AS vigintile, best
        FROM wca_dev.RanksAverage AS ra
        JOIN wca_dev.Persons AS p ON p.id = ra.personId
        WHERE p.countryId = @countryId
    ) AS t
    WHERE vigintile = 1
    GROUP BY eventId
) AS t4 ON t4.eventId = c.eventId
JOIN wca_dev.Events AS e ON e.id = c.eventId
WHERE countryId = @countryId
ORDER BY ratioWr DESC, e.rank;

/*
    Determine percentile of all of the cutoffs
    
    Note: Needs to be run after senior_ratios.sql which creates SeniorRanksCombined and WcaRanksCombined
          Link - https://github.com/Logiqx/wca-stats/blob/master/sql/seniors/senior_ratios.sql
*/

SELECT c.eventId,
    RIGHT(LEFT(sec_to_time(csecs / 100), 8), 5) AS cutoff,
    ROUND(100 * t1.centile, 1) AS seniorCentile, ROUND(100 * t2.centile, 1) AS worldCentile
FROM cutoffs AS c
JOIN
(
    SELECT c.eventId, MAX(t.centile) AS centile
    FROM cutoffs AS c
    JOIN
    (
        SELECT eventId, CUME_DIST() OVER (PARTITION BY eventId ORDER BY best) AS centile, best
        FROM SeniorRanksCombined
    ) AS t ON t.eventId = c.eventId AND t.best < c.csecs
    WHERE countryId = @countryId
    GROUP BY c.eventId
) AS t1 ON t1.eventId = c.eventId
JOIN
(
    SELECT c.eventId, MAX(t.centile) AS centile
    FROM cutoffs AS c
    JOIN
    (
        SELECT eventId, CUME_DIST() OVER (PARTITION BY eventId ORDER BY best) AS centile, best
        FROM WcaRanksCombined
    ) AS t ON t.eventId = c.eventId AND t.best < c.csecs
    WHERE countryId = @countryId
    GROUP BY c.eventId
) AS t2 ON t2.eventId = c.eventId
JOIN wca_dev.Events AS e ON e.id = c.eventId
WHERE countryId = @countryId
ORDER BY seniorCentile DESC;
