/* 
    Script:   Sub-X average, Sup-Y single
    Created:  2019-07-14
    Author:   Michael George / 2015GEOR02

    Purpose:  Feel free to tag that group about seeing yourself in the results, but am I the first person to get a sup-20 that isn’t a DNF in a sub-8 3x3 average?
    Link:     https://www.facebook.com/groups/439995439706174/permalink/865405397165174/
*/

SELECT FLOOR(average / 100) + 1 AS sub_x_avg, COUNT(*) AS num_averages, MAX(ROUND(value1 / 100)), MAX(ROUND(value2 / 100, 2)), MAX(ROUND(value3 / 100, 2)), MAX(ROUND(value4 / 100, 2)), MAX(ROUND(value5 / 100, 2))
FROM results AS r
WHERE event_id = '333'
AND average > 0
AND average < 2000
GROUP BY sub_x_avg;

SELECT average / 100, CONCAT(r.person_name, ', ', c.name, ' - ', ROUND(value1 / 100, 2), ' ', ROUND(value2 / 100, 2), ' ', ROUND(value3 / 100, 2), ' ', ROUND(value4 / 100, 2), ' ', ROUND(value5 / 100, 2), ' = ', ROUND(average / 100, 2)) AS output
FROM results AS r
JOIN competitions AS c ON c.id = r.competition_id
WHERE event_id = '333'
AND average > 0
AND average < 800
AND (value1 >= 2000 OR value2 >= 2000 OR value3 >= 2000 OR value4 >= 2000 OR value5 >= 2000);

SELECT average / 100, CONCAT(r.person_name, ', ', c.name, ' - ', ROUND(value1 / 100, 2), ' ', ROUND(value2 / 100, 2), ' ', ROUND(value3 / 100, 2), ' ', ROUND(value4 / 100, 2), ' ', ROUND(value5 / 100, 2), ' = ', ROUND(average / 100, 2)) AS output
FROM results AS r
JOIN competitions AS c ON c.id = r.competition_id
WHERE event_id = '333'
AND average > 0
AND average < 1000
AND (value1 >= 6000 OR value2 >= 6000 OR value3 >= 6000 OR value4 >= 6000 OR value5 >= 6000);
