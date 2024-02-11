-- DATASET 1. MANGA

-- 1. CLEANING DATA IN MANGA TABLE
-- 1.1. LOOKING FOR DUPLICATES 
SELECT Title, COUNT(*) AS Duplicates
FROM manga
GROUP BY Title
HAVING COUNT(*) > 1;

SELECT *
FROM manga
WHERE Title IN (
	SELECT Title
	FROM manga
	GROUP BY Title
	HAVING COUNT(*)>1)
-- THE ANALYSIS HAS SHOWN THAT WE SHOULD NOT DELETE THE DUPLICATES 

-- 1.2. HANDLING MISSING VALUES. CONVERTING EMPTY '[]' VALUES INTO NULL
UPDATE manga
SET
	Genres = NULLIF(Genres, '[]'),
	Themes = NULLIF(Themes, '[]'),
	Demographics = NULLIF(Demographics, '[]')

-- 1.3. CHECKING THE DATA TYPE OF EACH COLUMN 
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'manga'

-- 1.4. RENAMING THE COLUMN 'Score' TO 'PublicationDateTime'
EXEC sp_rename 'manga.Score', 'PublicationDateTime', 'COLUMN'

-- 1.5. CREATING SEPARATE COLUMNS 'PublicationDate' AND 'PublicationTime' from 'PublicationDateTime' COLUMN
ALTER TABLE manga
ADD PublicationDate Date,
PublicationTime Time;

UPDATE manga
SET PublicationDate = CONVERT(Date, PublicationDateTime),
PublicationTime = CONVERT(Time, PublicationDateTime)
-- THIS MUST BE WRONG DATA. SEE NEXT STEP 1.6

-- 1.6. SEPARATING 'Published' COLUMN INTO 2 NEW COLUMNS 'PublishedFrom' AND 'PublishedTo' AND GIVING A SPECIFIC DATE FORMAT
ALTER TABLE manga
ADD PublishedFrom DATE
ALTER TABLE manga
ADD PublishedTo Date

UPDATE manga
SET
PublishedFrom = CASE WHEN Published LIKE '% to %' THEN
TRY_CONVERT(DATE, SUBSTRING(Published, 1, CHARINDEX(' to ', Published)-1), 103)
ELSE TRY_CONVERT(DATE, Published, 103)
END,
PublishedTo = CASE WHEN Published LIKE '% to %' THEN
TRY_CONVERT(DATE, SUBSTRING(Published, CHARINDEX(' to ', Published)+4, LEN(Published)),103)
ELSE NULL
END

-- 2. LOOKING INTO CORRELATIONS IN manga 
-- 2.1. Favorite VS Popularity. CALCULATING THE CORRELATION COEFFICIENT MANUALLY BY PEARSON'S METHOD 
SELECT
(COUNT(*) * SUM(Favorite * Popularity) - SUM(Favorite) * SUM(Popularity)) /
SQRT((COUNT(*) * SUM(Favorite * Favorite) - POWER(SUM(Favorite), 2)) * (COUNT(*) * SUM(Popularity * Popularity) - POWER(SUM(Popularity), 2))) AS CorrelationCoefficient
FROM manga;
-- THE RESULT IS -0,43 WHICH SUGGESTS THAT SOMEONE'S FAVOURITE MANGA ISN'T USUALLY POPULAR WHILE POPULAR MANGA TENDS TO BE LESS FAVOURITE BY READER

-- 3. SEEING TOPS
-- 3.1. TOP 10 GENRES IN manga
SELECT TOP 10
VALUE AS Genres,
COUNT(*) AS GenresCount
FROM manga
CROSS APPLY
STRING_SPLIT(REPLACE(REPLACE(Genres,'[', ''), ']', ''), ',') AS GenresSplit
GROUP BY VALUE
ORDER BY GenresCount DESC

-- 3.2. TOP 10 RANKED MANGA BY GENRE
SELECT TOP 10 Title, Ranked, Genres
FROM manga
ORDER BY Ranked 

-- 3.3 TOP LONGEST MANGA BY DAYS, MONTHS, YEARS
SELECT TOP 10 Title, Chapters, Status,
DATEDIFF(DAY, PublishedFrom, CASE WHEN PublishedTo IS NOT NULL THEN PublishedTo ELSE GETDATE() END) AS Days,
DATEDIFF(MONTH, PublishedFrom, CASE WHEN PublishedTo IS NOT NULL THEN PublishedTo ELSE GETDATE() END) AS Months,
DATEDIFF(YEAR, PublishedFrom, CASE WHEN PublishedTo IS NOT NULL THEN PublishedTo ELSE GETDATE() END) AS Years
FROM manga
ORDER BY Days DESC

-- 3.4 TOP 10 MOST POPULAR MANGA BY SERIALIZATION (PUBLISHER) AND AUTHOR
SELECT TOP 10 Title, Popularity, Serialization, Author
FROM manga
ORDER BY Popularity DESC


-- DATASET 2. ANIME

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


-- MANGA VS ANIME 
  
-- 1. WHAT % Of MANGA GET ANIME ADAPTATION?
SELECT
COUNT(DISTINCT m.Title) AS TotalPopularManga,
COUNT(DISTINCT CASE WHEN a.Title IS NOT NULL THEN m.Title END) AS MangaWithAnime,
COUNT(DISTINCT CASE WHEN a.Title IS NOT NULL THEN m.Title END) * 100.0 / COUNT(DISTINCT m.Title) AS PercentageWithAnime
FROM manga m
LEFT JOIN anime a ON m.Title = a.Title
WHERE m.Popularity IS NOT NULL 
-- RESULT: ONLY 4.4% OF MANGA GET ANIME ADAPTATION

-- 2. NUMBER OF MANGA CHAPTERS VS NUMBER OF ANIME ADAPTATION'S EPISODES VS AVERAGE NUMBER OF CHAPTERS COVERED PER EPISODE 
SELECT m.Title, SUM(m.Chapters) AS TotalMangaChapters, SUM(a.Episodes) AS TotalAnimeEpisodes, ROUND(AVG(m.Chapters/a.Episodes),1) AS AvergeChaptersPerEpisode
FROM manga m
LEFT JOIN anime a ON m.Title = a.Title
WHERE m.Status = 'Finished' AND a.Status = 'Finished Airing' AND m.Chapters IS NOT NULL AND a.Episodes IS NOT NULL AND a.Episodes > 0
GROUP BY m.Title
ORDER BY TotalMangaChapters DESC

-- 3. AVERAGE NUMBER OF ANIME EPISODES BY MANGA GENRE
WITH MangaGenres AS(
SELECT DISTINCT TRIM(VALUE) AS Genre
FROM manga
CROSS APPLY
STRING_SPLIT(REPLACE(REPLACE(Genres, '[', ''), ']', ''), ',')
WHERE Status = 'Finished')

SELECT mg.Genre, AVG(CAST(a.Episodes AS FLOAT)) AS AverageAnimeEpisodes
FROM MangaGenres mg
LEFT JOIN anime a ON 1=1
WHERE a.Status = 'Finished Airing' AND a.Episodes IS NOT NULL
GROUP BY mg.Genre
ORDER BY AverageAnimeEpisodes DESC

-- 4. COMPARING MANGA'S POPULARITY VS ITS ANIME ADAPTATION
WITH MangaAnimePopularity AS(
SELECT m.Title, m.Popularity AS MangaPopularity, a.Popularity AS AnimePopularity
FROM manga m
LEFT JOIN
anime a ON m.Title = a.Title
WHERE m.Popularity IS NOT NULL AND a.Popularity IS NOT NULL)

SELECT Title, MangaPopularity, AnimePopularity
FROM MangaAnimePopularity

-- 5. AMOUNT OF TIME (IN DAYS) BETWEEN MANGA'S FIRST PUBLICATION AND THE DAY IT IS FIRST AIRED
SELECT AVG(DATEDIFF(DAY, m.PublishedFrom, a.StartofAiring)) AS AverageDaysToAiring
FROM manga m
LEFT JOIN anime a ON m.Title = a.Title
WHERE m.PublishedFrom IS NOT NULL AND a.StartofAiring IS NOT NULL
-- THE RESULT IS 1319 DAYS - THE AMOUNT OF TIME ON AVERAGE IT TAKES MANGA TO BE FIRST AIRED
