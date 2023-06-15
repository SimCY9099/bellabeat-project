-- SELECT THE DATA -- 
-- 1. DAILY ACTIVITY --
WITH new_daily_activity AS 
(
SELECT 
    Id,
    ActivityDate AS Date,
    TotalSteps,
    SUM(CAST(VeryActiveMinutes AS smallint) + CAST(FairlyActiveMinutes AS smallint) + CAST(LightlyActiveMinutes AS smallint) + CAST(SedentaryMinutes AS smallint)) AS TotalMinute,
    ROUND(TotalDistance, 2) AS Distance,
    calories
FROM daily_activity
WHERE 
	TotalSteps != 0 AND TotalDistance != 0 
GROUP BY 
    Id,
    ActivityDate,
    TotalSteps,
    TotalDistance,
    calories
),

-- 1.5 ACTIVE DAILY ACTIVITIES -- 
daily_active_activity AS
(
SELECT 
    Id,
    ActivityDate AS Date,
    SUM(CAST(VeryActiveMinutes AS smallint) + CAST(FairlyActiveMinutes AS smallint) + CAST(LightlyActiveMinutes AS smallint)) AS TotalActiveMinute,
    ROUND(SUM(VeryActiveDistance + ModeratelyActiveDistance + LightActiveDistance), 2) AS TotalActiveDistance,
	Calories
FROM daily_activity
WHERE 
    TotalSteps != 0 AND TotalDistance != 0 
GROUP BY 
    Id,
    ActivityDate,
	Calories
),

-- 2. DAILY INTENSITIES -- 
new_daily_intensities AS
(
SELECT 
	Id,
	ActivityDay AS Date,
	SedentaryMinutes,
	LightlyActiveMinutes,
	FairlyActiveMinutes,
	VeryActiveMinutes,
	ROUND(SedentaryActiveDistance, 2) AS SedentaryActiveDistance,
	ROUND(LightActiveDistance, 2) AS LightActiveDistance,
	ROUND(ModeratelyActiveDistance, 2) AS ModeratelyActiveDistance,
	ROUND(VeryActiveDistance, 2) AS VeryActiveDistance
FROM 
	daily_intensities
WHERE 
	LightActiveDistance + ModeratelyActiveDistance + VeryActiveDistance != 0 AND 
	LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes != 0 
),

-- 2.5 ACTTVE DAILY INTENSITIES -- 
active_daily_intensities AS 
(
SELECT 
	Id,
	ActivityDay AS Date,
	LightlyActiveMinutes,
	FairlyActiveMinutes,
	VeryActiveMinutes,
	ROUND(LightActiveDistance, 2) AS LightActiveDistance,
	ROUND(ModeratelyActiveDistance, 2) AS ModeratelyActiveDistance,
	ROUND(VeryActiveDistance, 2) AS VeryActiveDistance
FROM 
	daily_intensities
WHERE 
	LightActiveDistance + ModeratelyActiveDistance + VeryActiveDistance != 0 AND 
	LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes != 0 
),

-- 3. SLEEP DAY --
new_sleep_day AS
(
SELECT 
	Id,
	CONVERT(date, SleepDay) AS Date,
	TotalSleepRecords,
	TotalMinutesAsleep,
	TotalTimeInBed
FROM 
	sleep_day
),

-- 4. WEIGHT LOG INFO --
new_weight_loginfo AS 
(
SELECT
	ID AS Id, 
	CONVERT(date, Date) AS Date,
	ROUND(WeightKg, 2) AS WeightKg,
	ROUND(BMI, 2) AS BMI,
	LogId,
	CASE WHEN IsManualReport = 1 THEN 'YES'		
		 WHEN IsManualReport = 0 THEN 'NO'
	END AS ManualReport
FROM
	weight_loginfo
),

-- 5. HOUR INTENSITIES -- 

hour_intensities AS (
SELECT DISTINCT 
	Id,
	ActivityHour,
	TotalIntensity,
	ROUND(AverageIntensity, 2) AS Average_Hour_Intensities
FROM hourly_intensities
ORDER BY Id
),
 
-- ANALIZE THE DATA --

updated_daily_activity AS 
(
SELECT 
    Id,
    CASE DATEPART(DW, ActivityDate)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS Weekday,
    TotalSteps,
    SUM(CAST(VeryActiveMinutes AS smallint) + CAST(FairlyActiveMinutes AS smallint) + CAST(LightlyActiveMinutes AS smallint) + CAST(SedentaryMinutes AS smallint)) AS TotalMinute,
    ROUND(TotalDistance, 2) AS Distance,
    calories
FROM daily_activity
WHERE 
	TotalSteps != 0 AND TotalDistance != 0 
GROUP BY 
    Id,
	DATEPART(DW, ActivityDate),
    TotalSteps,
    TotalDistance,
    calories
),
-- THE AVERAGE MINUTES, CALORIES, STEPS , DISTANCE BY EACH MEMBER AND DAY -- 
avg_daily_activity AS 
(
SELECT
	Id,
	Weekday,
	AVG(TotalSteps) AS AvgSteps,
	AVG(TotalMinute) AS AvgMinutes,
	AVG(calories) AS AvgCalories
FROM 
	updated_daily_activity
GROUP BY
	Id,
	Weekday
),

-- AVG ACTIVE DAILY ACTIVITY --
avg_active_daily_activity AS 
(
SELECT 
    Id,
    CASE DATEPART(DW, Date)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END AS Weekday,
    AVG(TotalActiveMinute) AS AvgActiveMinutes,
    AVG(TotalActiveDistance) AS AvgActiveDistance,
    AVG(Calories) AS AvgCalories
FROM daily_active_activity
GROUP BY
    Id,
    Date
HAVING
    AVG(TotalActiveMinute) != 0 AND
    AVG(TotalActiveDistance) != 0
)


