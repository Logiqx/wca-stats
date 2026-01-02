/* 
    Script:   Senior Participation
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Show senior participation
*/

-- Note: Hacked 3BLD because only 60% of people who have attempted it have a success

SELECT run_date, e.name AS event_name, ROUND(100 * SUM(group_size) / 2000 / IF(event_id = '333bf', 0.6, 1), 2) AS pct_seniors
FROM wca_ipy.senior_stats AS ss
JOIN wca.events AS e ON e.id = ss.event_id
WHERE result_type = 'single'
AND age_category = 40
AND event_id NOT IN ('333ft', 'mmagic', 'magic', '333mbo')
GROUP BY run_date, event_id
ORDER BY pct_seniors DESC;
