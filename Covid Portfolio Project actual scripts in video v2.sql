SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
Order by 1,2

-- Looking at Total Cases vs Total Deaths
Select Location, date, total_cases, total_deaths,  (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0))*100 AS death_percentage
From PortfolioProject..CovidDeaths$
Where location like '%states%' AND continent IS NOT NULL
Order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, date, population, total_cases, (NULLIF(CAST(total_cases AS FLOAT), 0)/population)*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths$
Where location = 'United States' AND continent IS NOT NULL
Order by 1,2

-- Looking at countries with highest infection rate compared to population
Select Location, population, max(total_cases) as HighestInfectionCount, MAX((NULLIF(CAST(total_cases AS FLOAT), 0)/population))*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths$
--Where location = 'United States'
WHERE continent IS NOT NULL
GROUP BY location, population
Order by PercentPopulationInfected DESC

-- Let's break this down by continent 
Select location, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
From PortfolioProject..CovidDeaths$
--Where location = 'United States'
WHERE continent IS NULL AND location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
Order by TotalDeathCount DESC

-- Showing the Continents with Highest Death Count per Population
Select continent, MAX(CAST(total_deaths AS float)) AS TotalDeathCount
From PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL 
GROUP BY continent
Order by TotalDeathCount DESC

-- Global Numbers
SELECT SUM(CAST(new_cases AS float)) AS total_cases, SUM(CAST(new_deaths AS float)) AS total_deaths, SUM(CAST(new_deaths AS float)/NULLIF(CAST(new_cases AS float), 0))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Total Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3

-- Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac

-- TEMP table
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualisations 
DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 2,3

SELECT * FROM PercentPopulationVaccinated