/* 
    Script:   MultiBLD attempts
    Created:  2019-04-18
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Request by Mark Adams to determine the best strategy for 9 points

              Do more people get 10/11, 11/11 or 9/9?
              Do you have it as a percentage of those who have attempted 11 and 9?
              Can you do I want a result of 7 points and can attempt up to 13 cubes?

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
              This query only considers successful attempts
              DNF results do not record how many cubes were attempted / solved
*/

/*
    Explanation of MBLD results
    
    best          = 0DDTTTTTMM
    points        = 99 - DD
    missed        = MM
    solved        = difference + missed
    attempted     = solved + missed
    timeInSeconds = TTTTT
*/

SET @target = 7;
SET @max_cubes = 13;

SELECT *
FROM
(
    SELECT attempted, solved, missed, points, num_results,
        SUM(num_results) OVER(PARTITION BY attempted ORDER BY solved DESC ROWS UNBOUNDED PRECEDING) AS tot_num_results,
        FORMAT(100.0 * num_results / SUM(num_results) OVER(PARTITION BY attempted), 2) AS pct_results,
        FORMAT(100.0 * SUM(num_results) OVER(PARTITION BY attempted ORDER BY solved DESC ROWS UNBOUNDED PRECEDING) /
            SUM(num_results) OVER(PARTITION BY attempted), 2) AS tot_pct_results
    FROM
    (
        SELECT
            99 - FLOOR(best / 10000000) + (best % 100) * 2 AS attempted,
            99 - FLOOR(best / 10000000) + (best % 100) AS solved,
            best % 100 AS missed,
            99 - FLOOR(best / 10000000) AS points,
            COUNT(*) AS num_results
        FROM Results
        WHERE eventId = '333mbf'
        AND best > 0
        GROUP BY attempted, solved
    ) t1
) t2
WHERE points BETWEEN @target AND @target + 1
AND attempted <= @max_cubes
ORDER BY attempted, solved DESC;
