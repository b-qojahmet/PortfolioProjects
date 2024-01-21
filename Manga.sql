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

