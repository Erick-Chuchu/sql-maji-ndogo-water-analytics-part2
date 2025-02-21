-- MAJI NDOGO WATER PROJECT (Part II)

-- CLUSTERING DATA TO UNVEIL MAJI NDOGO'S WATER CRISIS

-- 1. Cleaning the Data

-- (a). Add a new column in the `employee` table for email address. 
-- Use the format: 'first_name.last_name.majindogowater.gov'
SELECT 	CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS email
FROM 	employee;

-- Update the change in the table
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),'@ndogowater.gov');

-- (b). Remove trailing spaces
-- Check the number of digits
SELECT 	LENGTH(phone_number) AS characters
FROM 	employee;

-- Trim the 'phone_number' column
SELECT 	TRIM(phone_number) AS trimmed_phone_number,
		LENGTH(TRIM(phone_number)) AS characters
FROM 	employee;

-- 2. Analysing Employees

-- (a). How many employees live in each town?
SELECT 	town_name,
		COUNT(employee_name) AS number_of_employees
FROM 	employee
GROUP BY town_name
ORDER BY 2 DESC; -- orders by the 2nd column which is number of employees in each town

-- (b). How many records did each employee collect?
SELECT 	assigned_employee_id,
		COUNT(assigned_employee_id) AS number_of_records
FROM 	visits
GROUP BY assigned_employee_id
ORDER BY 2 DESC;

-- 3. Analysing Locations

-- (a). How many records are there per town?
SELECT 	town_name,
		COUNT(location_id) AS number_of_records
FROM 	location
GROUP BY town_name
ORDER BY 2 DESC;
-- Most of the water sources are situated in small rural communities, scattered across Maji Ndogo.

-- (b). How many records are there per province?
SELECT 	province_name,
		COUNT(location_id) AS number_of_records
FROM 	location
GROUP BY province_name
ORDER BY 2 DESC;
-- Most of the provinces have a similar number of sources, so every province is well-represented in the survey.

-- A summarry table
SELECT 	province_name,
		town_name,
        COUNT(location_id) AS number_of_records
FROM 	location
GROUP BY province_name, town_name
ORDER BY 1, 3 DESC;
-- Every province and town has many documented sources thus reliable to make decision on. 

-- (c). How many records are for each location type?
SELECT 	location_type,
		COUNT(location_id) AS number_of_records
FROM 	location
GROUP BY location_type;

SELECT 23740 / (15910 + 23740) * 100;
-- About 60% of all water sources in the dataset are in rural communities.

-- 4. Diving into the Sources

-- (a). How many records are there for each source?
SELECT 	type_of_water_source,
		COUNT(source_id) AS number_of_records
FROM 	water_source
GROUP BY type_of_water_source
ORDER BY 2 DESC;

-- (b). How many people share particular types of water sources on average?
SELECT 	type_of_water_source,
		ROUND(AVG(number_of_people_served), 0) AS avg_people_served
FROM 	water_source
GROUP BY type_of_water_source
ORDER BY 2 DESC;
-- NOTE: The surveyors combined the data of many households together and added this as a single tap record, though actually has its own tap. 
-- Also, there is an average of 6 people living in a home. So 6 people actually share 1 tap (not 644 or 649).

-- (c). How many people are getting water from each type of source?
SELECT 	type_of_water_source,
		SUM(number_of_people_served) AS total_people_served,
		ROUND(SUM(number_of_people_served)/(SELECT SUM(number_of_people_served) AS total_people_served FROM water_source) * 100, 0) AS pct_people_served
FROM 	water_source
GROUP BY type_of_water_source
ORDER BY 2 DESC;

-- 5. Start of a Solution

-- (a). Rank source types based on number of people served.
SELECT 	type_of_water_source,
		SUM(number_of_people_served) AS total_people_served,
		RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population
FROM 	water_source
WHERE type_of_water_source != 'tap_in_home' -- Exclude the best source available since it needs no improvement
GROUP BY type_of_water_source;
 
 -- (b). Rank source based on number of people served.
SELECT 	source_id,
		type_of_water_source,
		number_of_people_served AS people_served,
		RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM 	water_source
WHERE type_of_water_source != 'tap_in_home'; -- Exclude the best source available since it needs no improvement

-- 6. Analysing Queues

-- (a). How long did the survey take?
SELECT 	TIMESTAMPDIFF(DAY, MIN(time_of_record), MAX(time_of_record)) AS days_taken,
		TIMESTAMPDIFF(MONTH, MIN(time_of_record), MAX(time_of_record)) AS months_taken,
        TIMESTAMPDIFF(YEAR, MIN(time_of_record), MAX(time_of_record)) AS years_taken
FROM 	visits;

-- (b). What is the average total queue time for water?
SELECT 	AVG(NULLIF(time_in_queue, 0)) AS avg_time_in_queue
FROM 	visits;

-- (c). What is the average queue time on different days?
SELECT 	DAYNAME(time_of_record) AS day_of_week,
		ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_time_in_queue
FROM 	visits
GROUP BY day_of_week;

-- (d). What is the average queue time at different times?
SELECT 	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
		ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_time_in_queue
FROM 	visits
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- (e). How can this information be communicated efficiently?
-- Summarize in a pivot table.
SELECT 	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
		ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue ELSE NULL END), 0) AS Monday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue ELSE NULL END), 0) AS Tuesday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue ELSE NULL END), 0) AS Wednesday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue ELSE NULL END), 0) AS Thursday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue ELSE NULL END), 0) AS Friday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue ELSE NULL END), 0) AS Saturday,
        ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue ELSE NULL END), 0) AS Sunday
FROM 	visits
WHERE 	time_in_queue != 0 -- This excludes other sources with 0 queue times.
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- 7. Reporting Insights

/*
Observations:
-> Queues are very long on Monday morning and Monday evening as people rush to get water.
-> Wednesday has the lowest queue times, but long queues on Wednesday evening.
-> People have to queue pretty much twice as long on Saturdays compared to the weekdays. It looks like people spend their Saturdays queueing
	for water, perhaps for the week's supply?
-> The shortest queues are on Sundays.

Start of the Plan:
-> Focus efforts on improving the water sources that affect the most people.
	- Most people will benefit if shared taps are improved first.
	- Wells are a good source of water, but many are contaminated. Fixing this will benefit a lot of people.
	- Fixing existing infrastructure will help many people. So they won't have to queue, thereby shorting queue times for others. 
	- Installing taps in homes will stretch resources too thin, so for now, if the queue times are low, there's no need to improve that source.
-> Most water sources are in rural areas. 
	- Ensure the teams know this as this means they will have to make these repairs/upgrades in rural areas 
		where road conditions, supplies, and labour are harder challenges to overcome.
*/

