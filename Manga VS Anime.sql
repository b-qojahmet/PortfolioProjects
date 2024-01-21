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

