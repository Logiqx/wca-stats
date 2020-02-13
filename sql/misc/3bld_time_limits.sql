/* 
    Script:   3BLD time limits
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Determine 3BLD time limits
*/

SELECT year, countryId, JSON_EXTRACT(time_limit, "$.centiseconds") / 6000 AS num_mins, COUNT(*)
FROM wca_dev.rounds AS r
JOIN wca_dev.competition_events AS ce ON ce.id = competition_event_id
JOIN wca_dev.Competitions AS c ON c.id = competition_id
JOIN wca_dev.Formats AS f ON f.id = format_id
WHERE event_id = '333bf'
AND time_limit IS NOT NULL
GROUP BY year, countryId, num_mins
ORDER BY year DESC, COUNT(*) DESC;
