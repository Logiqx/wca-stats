/* 
    Script:   Sub-X average, Sup-Y single
    Created:  2019-07-14
    Author:   Michael George / 2015GEOR02

    Purpose:  Feel free to tag that group about seeing yourself in the results, but am I the first person to get a sup-20 that isn’t a DNF in a sub-8 3x3 average?
    Link:     https://www.facebook.com/groups/439995439706174/permalink/865405397165174/
*/

SELECT FLOOR(average / 100) + 1 AS subXAvg, COUNT(*) AS numAverages, MAX(ROUND(value1 / 100)), MAX(ROUND(value2 / 100, 2)), MAX(ROUND(value3 / 100, 2)), MAX(ROUND(value4 / 100, 2)), MAX(ROUND(value5 / 100, 2))
FROM Results AS r
WHERE eventId = '333'
AND average > 0
AND average < 2000
GROUP BY subXAvg;

SELECT average / 100, CONCAT(r.personName, ', ', c.name, ' - ', ROUND(value1 / 100, 2), ' ', ROUND(value2 / 100, 2), ' ', ROUND(value3 / 100, 2), ' ', ROUND(value4 / 100, 2), ' ', ROUND(value5 / 100, 2), ' = ', ROUND(average / 100, 2)) AS output
FROM Results AS r
JOIN Competitions AS c ON c.id = r.competitionId
WHERE eventId = '333'
AND average > 0
AND average < 800
AND (value1 >= 2000 OR value2 >= 2000 OR value3 >= 2000 OR value4 >= 2000 OR value5 >= 2000);

SELECT average / 100, CONCAT(r.personName, ', ', c.name, ' - ', ROUND(value1 / 100, 2), ' ', ROUND(value2 / 100, 2), ' ', ROUND(value3 / 100, 2), ' ', ROUND(value4 / 100, 2), ' ', ROUND(value5 / 100, 2), ' = ', ROUND(average / 100, 2)) AS output
FROM Results AS r
JOIN Competitions AS c ON c.id = r.competitionId
WHERE eventId = '333'
AND average > 0
AND average < 1000
AND (value1 >= 6000 OR value2 >= 6000 OR value3 >= 6000 OR value4 >= 6000 OR value5 >= 6000);
