/* 
    Script:   Senior Participation
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Show senior participation
*/

-- Note: Hacked 3BLD because only 60% of people who have attempted it have a success

SELECT runDate, e.name AS eventName, ROUND(100 * SUM(groupSize) / 2000 / IF(eventId = '333bf', 0.6, 1), 2) AS pctSeniors
FROM wca_ipy.SeniorStats AS ss
JOIN wca.Events AS e ON e.id = ss.eventId
WHERE resultType = 'single'
AND ageCategory = 40
AND eventId NOT IN ('333ft', 'mmagic', 'magic', '333mbo')
GROUP BY runDate, eventId
ORDER BY pctSeniors DESC;
