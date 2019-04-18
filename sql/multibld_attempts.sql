/* 
    Script:   MultiBLD attempts
    Created:  2019-04-18
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Request by Mark Adams to determine the best strategy for 9 points

              Do more people get 10/11, 11/11 or 9/9?
              Do you have it as a percentage of those who have attempted 11 and 9?

    Note:     This query only considers successful attempts
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

SELECT attempted, solved, missed, points, num_persons,
    FORMAT(100.0 * num_persons / SUM(num_persons) OVER(PARTITION BY attempted), 2) AS pct_persons
FROM 
(
    SELECT
        99 - FLOOR(best / 10000000) + (best % 100) * 2 AS attempted,
        99 - FLOOR(best / 10000000) + (best % 100) AS solved,
        best % 100 AS missed,
        99 - FLOOR(best / 10000000) AS points,
        COUNT(*) AS num_persons
    FROM Results
    WHERE eventId = '333mbf'
    AND best > 0
    GROUP BY attempted, solved
) tmp_multi
ORDER BY attempted, solved DESC;