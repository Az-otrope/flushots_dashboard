-- code 5302: seasonal flu vaccine; Filter year 2022
-- 'patient' col links with 'id' col in 'pt' table
-- A patient may have multiple flu shots in a year -> choose the earliest time
with flu_shot_2022 as
(
	SELECT
		patient,
		MIN(date) AS earliest_flu_shot_2022
	FROM immunizations
	WHERE code = '5302' 
		AND date BETWEEN '2022-01-01 00:00' AND '2022-12-31 23:59'
	GROUP BY patient
),

-- Filter out inactive patients: dead, inactive > 2 years (encounters table)
-- EPOCH extracts the seconds, divides by seconds in a month (2592000 seconds) to get the age in month
active_patients as
(
	SELECT DISTINCT patient
	FROM encounters e
	JOIN patients pt
		ON e.patient = pt.id
	WHERE start BETWEEN '2020-01-01 00:00' AND '2022-12-31 23:59' -- active patients
		AND pt.deathdate IS NULL
		AND EXTRACT(EPOCH FROM age('2022-12-31', pt.birthdate)) / 2592000 >= 6 --more than 6 months old to get flu shots
)

SELECT
	pt.birthdate,
	pt.race,
	pt.county,
	pt.id,
	pt.first,
	pt.last,
	EXTRACT(YEAR FROM age('12-31-2022', birthdate)) as age,
	CASE WHEN flu.patient IS NOT NULL THEN 1
	ELSE 0
	END AS flu_shot_2022, -- indicate got flu shot or not
	flu.earliest_flu_shot_2022
FROM patients pt
LEFT JOIN flu_shot_2022 AS flu
	ON pt.id = flu.patient
WHERE 1=1
	AND pt.id IN (SELECT patient FROM active_patients)