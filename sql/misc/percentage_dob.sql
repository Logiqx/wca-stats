/* 
    Script:   Percentage DOB
    Created:  2020-01-30
    Author:   Michael George / 2015GEOR02

    Purpose:  Report what percentage of profiles have a DOB
*/

SELECT country_id, 100 * SUM(IF(year > 0, 1, 0)) / COUNT(*) AS pct_dob
FROM persons
WHERE sub_id = 1
GROUP BY country_id
ORDER BY country_id;

SELECT LEFT(id, 4) AS reg_year, 100 * SUM(IF(year > 0, 1, 0)) / COUNT(*) AS pct_dob
FROM persons
WHERE sub_id = 1
GROUP BY reg_year
ORDER BY reg_year;
