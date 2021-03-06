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

DROP TEMPORARY TABLE IF EXISTS SeniorRanks;

CREATE TEMPORARY TABLE SeniorRanks AS
SELECT eventId, resultType, seq AS ageCategory, personId, hidden, MIN(best) AS best
FROM
(
    SELECT r.eventId, 'average' AS resultType, r.personId, r.average AS best,
        TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp, hidden
    FROM Seniors AS p
    JOIN wca.Results AS r ON r.personId = p.personId AND average > 0
    JOIN wca.Competitions AS c ON c.id = r.competitionId
    WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
    HAVING age_at_comp >= 40
    UNION ALL
    SELECT r.eventId, 'single' AS resultType, r.personId, r.best,
        TIMESTAMPDIFF(YEAR, dob, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d')) AS age_at_comp, hidden
    FROM Seniors AS p
    JOIN wca.Results AS r ON r.personId = p.personId AND best > 0
    JOIN wca.Competitions AS c ON c.id = r.competitionId
    WHERE YEAR(dob) <= YEAR(CURDATE()) - 40
    HAVING age_at_comp >= 40
) AS t
JOIN seq_40_to_100_step_10 ON seq <= age_at_comp
GROUP BY eventId, resultType, ageCategory, personId;

ALTER TABLE SeniorRanks ADD INDEX SeniorRanks(eventId, ageCategory, personId);

SELECT seq, numSeniors
FROM seq_1_to_6000 AS s
LEFT JOIN
(
	SELECT floor(best / 100) AS modBest, COUNT(*) as numSeniors
	FROM SeniorRanks
	WHERE eventId = 'skewb'
	AND resultType = 'average'
	GROUP BY modBest
) AS t ON modBest = seq;

/*
    Combined rankings for seniors - average where it exists (except 4BLD and 5BLD), otherwise single
*/

DROP TEMPORARY TABLE IF EXISTS SeniorRanksCombined;

CREATE TEMPORARY TABLE SeniorRanksCombined AS
(
    SELECT personId, eventId, RANK() OVER (PARTITION BY eventId ORDER BY best) AS rankNo, best, hidden
    FROM SeniorRanks AS sr1
    WHERE ageCategory = '40'
    AND resultType = 'average'
    -- AND hidden = 'n'
    AND eventId NOT IN ('333fm', '333bf', '444bf', '555bf', '333mbf') -- use singles
    AND eventId NOT IN ('333ft', 'magic', 'mmagic') -- legacy events
)
UNION ALL
(
    SELECT personId, eventId, RANK() OVER (PARTITION BY eventId ORDER BY best) AS rankNo, best, hidden
    FROM SeniorRanks AS sr2
    WHERE ageCategory = '40'
    -- AND hidden = 'n'
    AND resultType = 'single'
    AND eventId IN ('333fm', '333bf', '444bf', '555bf', '333mbf')
);

ALTER TABLE SeniorRanksCombined ADD INDEX (eventId);

/*
    Max Ranks
*/

DROP TEMPORARY TABLE IF EXISTS MaxRanks;

CREATE TEMPORARY TABLE MaxRanks AS
SELECT eventId, MAX(rankNo) AS maxRank, COUNT(*) AS numPersons
FROM SeniorRanksCombined
GROUP BY eventId;

ALTER TABLE MaxRanks ADD INDEX (eventId);

SELECT @sumRanks := SUM(maxRank) AS sumRanks FROM MaxRanks;

DROP TEMPORARY TABLE IF EXISTS eventWeights;

CREATE TEMPORARY TABLE eventWeights AS
(
	SELECT eventId, 1.00000 * SUM(maxRank) / @sumRanks AS eventWeight
	FROM MaxRanks
	GROUP BY eventId
);

SELECT SUM(eventWeight)
FROM eventWeights;

/*
    The calculations
*/

SELECT sr.eventId, personId, hidden,
	(maxRank + 1 - rankNo) / @sumRanks * 10 AS score,
    maxRank / @sumRanks AS ew,
    (maxRank - rankNo + 1) / maxRank * 100 AS up,
    (maxRank - rankNo + 1) / maxRank * 100 * maxRank / (@sumRanks * 100) AS wp
FROM SeniorRanksCombined AS sr
JOIN MaxRanks AS mr ON mr.eventId = sr.eventId;

SELECT t.*, p.name, p.countryId
FROM
(
	SELECT RANK() OVER (ORDER BY score DESC) as rankNo, t.*
	FROM
	(
		SELECT personId, hidden, SUM(1.0000 * (maxRank + 1 - rankNo) / @sumRanks * 10) AS score,
			SUM((maxRank - rankNo + 1) / maxRank * 100 * maxRank / (@sumRanks * 100)) AS score2
		FROM SeniorRanksCombined AS sr
		JOIN MaxRanks AS mr ON mr.eventId = sr.eventId
		GROUP BY personId
	) AS t
	ORDER BY rankNo
) AS t
JOIN wca.Persons AS p ON p.id = t.personId
WHERE hidden = 'n';