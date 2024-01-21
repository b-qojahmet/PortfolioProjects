-- 1. CLEANING DATA IN ANIME TABLE
--1.1 RENAMING THE COLUMN 'Score' TO 'PublicationDateTime'
EXEC sp_rename 'anime.Score', 'PublicationDateTime', 'COLUMN'


-- 1.2. CREATING SEPARATE COLUMNS 'PublicationDate' AND 'PublicationTime' from 'PublicationDateTime' COLUMN
ALTER TABLE anime
ADD PublicationDate Date,
PublicationTime Time

UPDATE anime
SET PublicationDate = CONVERT(Date, PublicationDateTime),
PublicationTime = CONVERT(Time, PublicationDateTime)
SELECT * FROM anime

-- 1.3 LOOKING FOR DUPLICATES AND DELETING THEM
SELECT *
FROM anime
WHERE Title IN(
	SELECT Title
	FROM anime
	GROUP BY Title
	HAVING COUNT(*)>1)

WITH animeCTE AS(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY Title ORDER BY (SELECT NULL)) AS RowNum
FROM anime)

DELETE FROM animeCTE
WHERE RowNum > 1


-- 1.4. SEPARATING THE 'Aired' COLUMN INTO 2 NEW COLUMNS 'StartofAiring' AND 'EndofAiring' AND GIVING A SPECIFIC DATE FORMAT
ALTER TABLE anime
ADD StartofAiring DATE
ALTER TABLE anime
ADD EndofAiring DATE

UPDATE anime
SET 
StartofAiring = CASE WHEN Aired LIKE '% to %' THEN 
TRY_CONVERT(DATE, SUBSTRING(Aired, 1, CHARINDEX(' to ', Aired) - 1), 103)
ELSE TRY_CONVERT(DATE, Aired, 103)
END,
EndofAiring =  CASE WHEN Aired LIKE '% to %' THEN 
TRY_CONVERT(DATE, SUBSTRING(Aired, CHARINDEX(' to ', Aired) + 4, LEN(Aired)), 103)
ELSE NULL
END;


-- 1.5. CHECKING THE DATA TYPE IN EACH COLUMN 
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'anime'


-- 2. LOOKING INTO CORRELATIONS IN anime
-- 2.1. Popularity VS Episodes. CALCULATING THE CORRELATION COEFFICIENT MANUALLY BY PEARSON'S METHOD 
SELECT
(COUNT(*) * SUM(Popularity*Episodes) - SUM(Popularity) * SUM(Episodes)) / 
NULLIF(SQRT(COUNT(*) * SUM(Popularity*Popularity) - POWER(SUM(Popularity), 2)) * 
SQRT(COUNT(*) * SUM(Episodes*Episodes) - POWER(SUM(Episodes), 2)), 0) AS CorrelationCoefficient
FROM anime;
-- THE RESULT IS 0.05 WHICH SUGGESTS A SLIGHT CORRELATION BETWEEN ANIME'S POPULARITY AND NUMBER OF EPISODES


-- 2.2. Rating vs Popularity
SELECT Rating, AVG(Popularity) AS AveragePopularity
FROM anime
GROUP BY Rating
ORDER BY AveragePopularity DESC


-- 3. SEEING TOPS
-- 3.1. TOP 10 STUDIOS BY COUNT
SELECT TOP 10 Studios, COUNT(*) AS StudioCount
FROM anime
GROUP BY Studios
ORDER BY StudioCount DESC


-- 3.2. TOP 10 PRODUCERS BY COUNT
SELECT TOP 10 Producer, COUNT(*) ProducerCount
FROM(
SELECT TRIM(VALUE) AS Producer
FROM anime
CROSS APPLY
STRING_SPLIT(REPLACE(REPLACE(Producers, '[', ''), ']', ''), ',') AS ProducersSplit)
AS ProducersTable
GROUP BY Producer
ORDER BY ProducerCount DESC


-- 3.3. TOP 10 MOST POPULAR ANIME
SELECT TOP 10 Title, Popularity, Vote
FROM anime
ORDER BY Popularity DESC


-- 4. USEFUL INSIGHTS
-- 4.1. SOURCE OF ANIME BY COUNT AND PERCENT
SELECT DISTINCT Source FROM anime

SELECT 
Source, COUNT(*) AS SourceCount, COUNT(*)*100/SUM(COUNT(*)) OVER() AS PercentofTotal
FROM anime
GROUP BY Source
ORDER BY SourceCount DESC


