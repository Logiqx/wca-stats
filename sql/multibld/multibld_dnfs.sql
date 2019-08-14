/* 
    Script:   MultiBLD DNFs
    Created:  2019-04-18
    Author:   Michael George / 2015GEOR02
   
    Purpose:  Estimate number of cubes attempted in MultBLD DNFs

    Notes:    Requires MySQL 8.0.2 (2017-07-17) or MariaDB 10.2.0 (2016-04-19) or newer for window functions
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

SELECT (CASE WHEN best > 0 THEN 99 - FLOOR(best / 10000000) + (best % 100) * 2 ELSE NULL END) AS attempted, COUNT(*)
FROM Results r
WHERE eventId = '333mbf'
GROUP BY attempted
ORDER BY attempted;

SELECT attempted, COUNT(*)
FROM
(
	SELECT personId, MIN(CASE WHEN best > 0 THEN 99 - FLOOR(best / 10000000) + (best % 100) * 2 ELSE NULL END) AS attempted
	FROM Results r
	WHERE eventId = '333mbf'
	GROUP BY personId
    HAVING attempted IS NOT NULL
	ORDER BY personId
) AS t
GROUP BY attempted
ORDER BY attempted;



SET @weight_last = 0; -- 1.0;
SET @weight_max = 0; -- 0.25;
SET @weight_next = 1; -- 1.25;
SET @weight_min = 0; -- 0.25;

SELECT attempted,
	AVG(last_preceding - attempted) AS diff_preceding,
	AVG(next_following - attempted) AS diff_following,
	AVG(estimated - attempted) AS diff_combined,
	-- FORMAT(ABS(AVG(attempted - last_preceding)) / ABS(AVG(attempted - next_following)), 3) AS ratio,
	AVG(ABS(attempted - last_preceding)) AS abs_diff_preceding,
    AVG(ABS(attempted - next_following)) AS abs_diff_following,
    AVG(ABS(attempted - estimated)) AS abs_diff_combined
    -- FORMAT(AVG(ABS(attempted - last_preceding)) / AVG(ABS(attempted - next_following)),3) AS abs_ratio
FROM 
(
	-- SELECT personId, `year`, `month`, `day`, attempted, last_preceding, max_preceding, next_following, min_following,
	SELECT attempted, last_preceding, max_preceding, next_following, min_following,
	(
		ROUND(CASE
			WHEN COALESCE(last_preceding, max_preceding, next_following, min_following) IS NOT NULL
			THEN (COALESCE(last_preceding, 0) * @weight_last + COALESCE(max_preceding, 0) * @weight_max +
				COALESCE(next_following, 0) * @weight_next + COALESCE(min_following, 0) * @weight_min) / 
				(
					CASE WHEN last_preceding IS NULL THEN 0 ELSE @weight_last END + 
					CASE WHEN max_preceding IS NULL THEN 0 ELSE @weight_max END +
					CASE WHEN next_following IS NULL THEN 0 ELSE @weight_next END +
					CASE WHEN min_following IS NULL THEN 0 ELSE @weight_min END
				)
	   END)
	) AS estimated
	FROM
	(
		SELECT personId, `year`, `month`, `day`, attempted,
			LAG(attempted) OVER (
				PARTITION BY personId
				ORDER BY `year`, `month`, `day`
				ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS last_preceding,
			MAX(attempted) OVER (
				PARTITION BY personId
				ORDER BY `year`, `month`, `day`
				ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS max_preceding,
			LEAD(attempted) OVER (
				PARTITION BY personId
				ORDER BY `year`, `month`, `day`
				ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS next_following,
			MIN(attempted) OVER (
				PARTITION BY personId
				ORDER BY `year`, `month`, `day`
				ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS min_following
		FROM
		(
			-- Successful MultiBLD attempts
			SELECT personId, c.year, c.month, c.day,
				(CASE WHEN best > 0 THEN 99 - FLOOR(best / 10000000) + (best % 100) * 2 ELSE NULL END) AS attempted
			FROM Results r
			INNER JOIN Competitions AS c ON r.competitionId = c.id
			WHERE eventId = '333mbf'
			AND	best > 0
			-- AND personId = '2004GALL02'
			-- ORDER BY personId, c.year, c.month, c.day
		) t1
		-- WHERE attempted = 48
	) t2
) t3
WHERE attempted >= 1
-- AND next_following != attempted -- 1022 of 3736
-- AND last_preceding != attempted
GROUP BY attempted
ORDER BY attempted
-- ORDER BY personId, `year`, `month`, `day`
;

SELECT
(
	ROUND(
		CASE
			WHEN next_following IS NULL THEN last_preceding
			WHEN COALESCE(last_preceding, max_preceding, next_following, min_following) IS NOT NULL
			THEN (COALESCE(last_preceding, 0) * @weight_last + COALESCE(max_preceding, 0) * @weight_max +
				COALESCE(next_following, 0) * @weight_next + COALESCE(min_following, 0) * @weight_min) / 
				(
					CASE WHEN last_preceding IS NULL THEN 0 ELSE @weight_last END + 
					CASE WHEN max_preceding IS NULL THEN 0 ELSE @weight_max END +
					CASE WHEN next_following IS NULL THEN 0 ELSE @weight_next END +
					CASE WHEN min_following IS NULL THEN 0 ELSE @weight_min END
				)
		END
	)
) AS estimated, COUNT(*)
FROM
(
	SELECT personId, `year`, `month`, `day`,
		attempted, asc_partition, desc_partition,
		FIRST_VALUE(attempted) OVER wp AS last_preceding,
		MAX(attempted) OVER wp AS max_preceding,
		LAST_VALUE(attempted) OVER wf AS next_following,
		MIN(attempted) OVER wf AS min_following
	FROM
	(
		SELECT personId, c.year, c.month, c.day,
			(CASE WHEN best > 0 THEN 99 - FLOOR(best / 10000000) + (best % 100) * 2 ELSE NULL END) AS attempted,
			SUM(CASE WHEN best > 0 THEN 1 ELSE 0 END) OVER
				(PARTITION BY personId ORDER BY c.year, c.month, c.day) as asc_partition,
			SUM(CASE WHEN best > 0 THEN 1 ELSE 0 END) OVER
				(PARTITION BY personId ORDER BY c.year DESC, c.month DESC, c.day DESC) as desc_partition
		FROM Results r
		INNER JOIN Competitions AS c ON r.competitionId = c.id
		WHERE eventId = '333mbf'
		ORDER BY personId, c.year, c.month, c.day
	) t1
    WINDOW w AS (PARTITION BY personId ORDER BY `year`, `month`, `day`),
        wp AS (w ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),
		wf AS (w ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING)
) t2
WHERE attempted IS NULL
GROUP BY estimated
ORDER BY estimated
-- ORDER BY personId, `year`, `month`, `day`;
;
