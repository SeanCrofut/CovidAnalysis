-- Check Table

SELECT *
FROM CovidAnalysis..CovidDeaths$
ORDER BY 3, 4

-- Select Data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidAnalysis..CovidDeaths$
ORDER BY Location, date

-- Total Cases vs Total Deaths in the US

SELECT Location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths$
WHERE Location LIKE '%states%'
ORDER BY Location, date


-- Percentage of US Population with COVID

SELECT Location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM CovidAnalysis..CovidDeaths$
WHERE Location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY Location, date

-- Infection Rates by Country

SELECT Location, population, MAX(total_cases) AS MaxInfectionCount, MAX((total_cases/population)*100) AS InfectionRate
FROM CovidAnalysis..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY InfectionRate DESC

-- Death Rates by Country

SELECT Location, MAX(cast(total_deaths AS int)) AS MaxDeathCount, MAX((total_deaths/population)*100) AS DeathRate
FROM CovidAnalysis..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY DeathRate DESC

-- Death Counts by Continent

SELECT Location, MAX(cast(total_deaths AS int)) AS DeathCount
FROM CovidAnalysis..CovidDeaths$
WHERE continent IS NULL
GROUP BY Location
ORDER BY DeathCount DESC

-- Global Numbers for Death Rates by Date

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths,
	SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, total_cases;

-- Join with Vaccination Data
-- Keep a Running Total for Population vs Vaccinations
-- Use a CTE to get the percentage of people vaccinated as another column

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths$ dea
JOIN CovidAnalysis..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Create a View

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths$ dea
JOIN CovidAnalysis..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
