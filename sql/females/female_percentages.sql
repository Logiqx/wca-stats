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
        SELECT DISTINCT person_id
        FROM results
    ) AS tmp_results
    INNER JOIN persons AS p ON tmp_results.person_id = p.wca_id AND p.sub_id = 1
) AS tmp;

-- Females per competition - 8.60%

SELECT CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competition_id,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competition_id, person_id
        FROM results
    ) AS tmp_results
    INNER JOIN persons AS p ON tmp_results.person_id = p.wca_id AND p.sub_id = 1
    GROUP BY tmp_results.competition_id
) AS c;

-- Results in pct_female_by_country.csv

SELECT c.name AS country, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competition_id, c.country_id, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competition_id, person_id
        FROM results
    ) AS tmp_results
    INNER JOIN competitions AS c ON tmp_results.competition_id = c.id
    INNER JOIN persons AS p ON tmp_results.person_id = p.wca_id AND p.sub_id = 1
    GROUP BY tmp_results.competition_id
) AS tmp_comps
INNER JOIN countries AS c ON tmp_comps.country_id = c.id
GROUP BY country;

-- Results in pct_female_by_year.csv

SELECT year, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competition_id, c.country_id, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competition_id, person_id
        FROM results
    ) AS tmp_results
    INNER JOIN competitions AS c ON tmp_results.competition_id = c.id
    INNER JOIN persons AS p ON tmp_results.person_id = p.wca_id AND p.sub_id = 1
    GROUP BY tmp_results.competition_id
) AS tmp_comps
GROUP BY year;

-- Results in pct_female_by_country_year.csv

SELECT c.name AS country, year, CAST(AVG(100.0 * num_females / num_persons) AS DECIMAL(10,2)) AS pct_females
FROM
(
    SELECT tmp_results.competition_id, c.country_id, c.year,
        SUM(CASE WHEN p.gender = 'm' THEN 1 ELSE 0 END) AS num_males,
        SUM(CASE WHEN p.gender = 'f' THEN 1 ELSE 0 END) AS num_females,
        SUM(CASE WHEN p.gender IN ('m', 'f') THEN 1 ELSE 0 END) AS num_persons
    FROM
    (
        SELECT DISTINCT competition_id, person_id
        FROM results
    ) AS tmp_results
    INNER JOIN competitions AS c ON tmp_results.competition_id = c.id
    INNER JOIN persons AS p ON tmp_results.person_id = p.wca_id AND p.sub_id = 1
    GROUP BY tmp_results.competition_id
) AS tmp_comps
INNER JOIN countries AS c ON tmp_comps.country_id = c.id
GROUP BY country, year;
