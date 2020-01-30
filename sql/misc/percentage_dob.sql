/* 
    Script:   Percentage DOB
    Created:  2020-01-30
    Author:   Michael George / 2015GEOR02

    Purpose:  Report what percentage of profiles have a DOB
*/

SELECT countryId, 100 * SUM(IF(year > 0, 1, 0)) / COUNT(*) AS pctDob
FROM Persons
WHERE subid = 1
GROUP BY countryId
ORDER BY countryId;

SELECT LEFT(id, 4) AS regYear, 100 * SUM(IF(year > 0, 1, 0)) / COUNT(*) AS pctDob
FROM Persons
WHERE subid = 1
GROUP BY regYear
ORDER BY regYear;
