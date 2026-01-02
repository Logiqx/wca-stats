/* 
    Script:   3BLD successful competitors
    Created:  2020-02-13
    Author:   Michael George / 2015GEOR02

    Purpose:  Determine what percentage of competitors have a success (~60%)
*/

SELECT @attempt := COUNT(DISTINCT person_id)
FROM wca.ranks_single
WHERE event_id = '333bf';

SELECT @success := COUNT(DISTINCT person_id)
FROM wca.results
WHERE event_id = '333bf';

SELECT 100 * @attempt / @success