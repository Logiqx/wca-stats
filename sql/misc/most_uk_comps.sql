/* 
    Script:   Most UK Comps
    Created:  2019-10-14
    Author:   Michael George / 2015GEOR02
   
    Purpose:  List competitors who have attended the most UK comps
*/

-- UK comps
SELECT RANK() OVER (ORDER BY numComps DESC) AS pos, id, CONCAT(name, ' (', countryId, ')'), numComps
FROM
(
	SELECT p.id, p.name, p.countryId, COUNT(DISTINCT r.competitionId) AS numComps
	FROM Persons AS p
	JOIN Results AS r ON r.personId = p.id
    JOIN Competitions AS c ON c.id = r.competitionId AND c.countryId = 'United Kingdom'
	GROUP BY p.id
) AS t
ORDER BY pos;

-- Worldwide comps
SELECT RANK() OVER (ORDER BY numComps DESC) AS pos, id, CONCAT(name, ' (', countryId, ')'), numComps
FROM
(
	SELECT p.id, p.name, p.countryId, COUNT(DISTINCT r.competitionId) AS numComps
	FROM Persons AS p
	JOIN Results AS r ON r.personId = p.id
    WHERE p.countryId = 'United Kingdom'
	GROUP BY p.id
) AS t
ORDER BY pos;