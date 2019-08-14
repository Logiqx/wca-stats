/* 
    Script:   Longest BigBLD success streaks
    Created:  2019-08-14
    Author:   Michael George / 2015GEOR02

    Purpose:  Does anyone have code to find the list of people with longest 4BLD success streaks? Streaks need not still be ongoing.
              Top 10-20 people with streak length would be nice, but a histogram of streak length and number of people would also work.
    Link:     https://www.facebook.com/groups/439995439706174/permalink/884593238579723/

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
*/

SELECT e.name AS event, t.rank, p.id, p.name, c.name AS country, longestStreak
FROM
(
    SELECT eventId, personId, MAX(streakLen) AS longestStreak, RANK() OVER (PARTITION BY eventId ORDER BY MAX(streakLen) DESC) AS rank
    FROM
    (
        SELECT t.*, SUM(IF(result < 0, 0, 1)) OVER (PARTITION BY eventId, personId, streakNo) AS streakLen
        FROM
        (
            SELECT t.*, SUM(IF(result < 0, 1, 0)) OVER (PARTITION BY eventId, personId ORDER BY start_date, competitionId, roundNo, attempt ROWS UNBOUNDED PRECEDING) AS streakNo
            FROM
            (
                SELECT eventId, personId, competitionId, rt.rank AS roundNo, DATE_FORMAT(CONCAT(c.year, '-', c.month, '-', c.day), '%Y-%m-%d') AS start_date, seq AS attempt,
                    CASE
                        WHEN seq = 1 THEN value1
                        WHEN seq = 2 THEN value2
                        WHEN seq = 3 THEN value3
                        WHEN seq = 4 THEN value4
                        WHEN seq = 5 THEN value5
                    END AS result
                FROM Results AS r
                JOIN (SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) AS seq_1_to_5
                JOIN Competitions AS c ON c.id = r.competitionId
                JOIN RoundTypes AS rt ON rt.id = r.roundTypeId
                WHERE eventId IN ('444bf', '555bf')
                HAVING result NOT IN (0, -2)
            ) AS t
        ) AS t
    ) AS t
    GROUP BY eventId, personId
) AS t
JOIN Events AS e ON e.id = t.eventId
JOIN Persons AS p ON p.id = t.personId AND p.subid = 1
JOIN Countries AS c ON c.id = p.countryId
WHERE t.rank <= 20
ORDER BY e.rank, t.rank, p.id;
