/* 
    Script:   Female Percentages
    Created:  2019-03-08
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Request by Adam Greenwood in WCA Statistics
              
              I'm sorry if this has been asked before but what is the average percentage of female competitors per competition?
              It's well established that the percentage of females in the data base is ~ 10% but if the average female competes
              a significantly different amount of times than the average male the result would be different.
*/

-- Females with results - 9.82%

SELECT CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT personId
        FROM Results
    ) AS tmp_results
    INNER JOIN Persons AS p ON tmp_results.personId = p.id AND p.subid = 1
) AS tmp;

-- Females per competition - 8.60%

SELECT CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competitionId,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competitionId, personId
        FROM Results
    ) AS tmp_results
    INNER JOIN Persons AS p ON tmp_results.personId = p.id AND p.subid = 1
    GROUP BY tmp_results.competitionId
) AS c;

-- Results in female_pct_by_country.csv

SELECT c.name AS country, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competitionId, c.countryId, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competitionId, personId
        FROM Results
    ) AS tmp_results
    INNER JOIN Competitions AS c ON tmp_results.competitionId = c.id
    INNER JOIN Persons AS p ON tmp_results.personId = p.id AND p.subid = 1
    GROUP BY tmp_results.competitionId
) AS tmp_comps
INNER JOIN Countries AS c ON tmp_comps.countryId = c.id
GROUP BY country;

-- Results in female_pct_by_year.csv

SELECT year, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competitionId, c.countryId, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competitionId, personId
        FROM Results
    ) AS tmp_results
    INNER JOIN Competitions AS c ON tmp_results.competitionId = c.id
    INNER JOIN Persons AS p ON tmp_results.personId = p.id AND p.subid = 1
    GROUP BY tmp_results.competitionId
) AS tmp_comps
GROUP BY year;

-- Results in female_pct_by_country_year.csv

SELECT c.name AS country, year, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competitionId, c.countryId, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competitionId, personId
        FROM Results
    ) AS tmp_results
    INNER JOIN Competitions AS c ON tmp_results.competitionId = c.id
    INNER JOIN Persons AS p ON tmp_results.personId = p.id AND p.subid = 1
    GROUP BY tmp_results.competitionId
) AS tmp_comps
INNER JOIN Countries AS c ON tmp_comps.countryId = c.id
GROUP BY country, year;
