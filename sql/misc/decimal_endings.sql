/* 
    Script:   Decimal Endings
    Created:  2019-07-23
    Author:   Michael George / 2015GEOR02

    Purpose:  What’s the most common decimal endings for times? Overall? By category (decimals .xx, .x(x+1), .x(x-1), .x0, and any other cool ones you can think of)?
    Link:     https://www.facebook.com/groups/439995439706174/permalink/870741636631550/
*/

SELECT LPAD(MOD(best, 100), 2, 0) AS mod100, COUNT(*) AS num_results, IF(best % 25 IN (1, 4, 7, 10, 12, 14, 17, 20, 23, 24), '*', '') AS gen2_issue
FROM Results
WHERE best BETWEEN 1 AND 59999
AND eventId NOT IN ('333fm', '333mbf', '333mbo')
GROUP BY mod100
ORDER BY num_results DESC;
