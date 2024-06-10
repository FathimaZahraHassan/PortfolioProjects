/* 
	SQL Data Exploration
*/

SELECT *
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Select data columns we use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Analyze Total Cases vs Total Deaths
-- Rough estimates show likelihood of death if contact with covid base country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS NUMERIC) / CAST(total_cases AS NUMERIC))*100 AS death_percentage
FROM Public."CovidDeaths"
--WHERE location ILIKE '%states%' AND
WHERE continent IS NOT NULL
ORDER BY 1, 2 

-- Sum of deaths compared to cases 
SELECT location, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY 1, 2 

-- Total death counts by location
SELECT location, SUM(CAST(new_deaths AS int)) AS Total_Death_Count
FROM Public."CovidDeaths"
WHERE continent IS null 
AND location NOT IN ('World', 'European Union', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY Total_Death_Count DESC
		  
-- Analyze Total Cases vs Population
-- Shows what percentage of population got covid
SELECT location, date, population, total_cases, (CAST(total_cases AS NUMERIC) / CAST(population AS NUMERIC))*100 AS population_infected
FROM Public."CovidDeaths"
-- WHERE location ILIKE '%states%'
ORDER BY 1, 2

-- Finding countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_cases, MAX((CAST(total_cases AS NUMERIC) / CAST(population AS NUMERIC)))*100 AS population_infected
FROM Public."CovidDeaths"
--WHERE location ILIKE '%states%'
GROUP BY location, population
ORDER BY population_infected DESC

-- Finding countries with highest death count per population 
SELECT location, population, MAX(total_deaths) AS highest_deaths, MAX((CAST(total_deaths AS NUMERIC) / CAST(population AS NUMERIC)))*100 AS population_death_percentage
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population_death_percentage DESC

-- Finding death counts by continent
SELECT continent, MAX(total_deaths) AS total_death_counts
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_counts DESC

-- Analyzing total cases compared to dates
SELECT CONCAT(EXTRACT('Year' FROM date),'-',EXTRACT('MONTH' FROM date)) AS date, SUM(total_cases) AS total_cases
FROM Public."CovidDeaths"
GROUP BY CONCAT(EXTRACT('Year' FROM date),'-',EXTRACT('MONTH' FROM date)) 
ORDER BY CONCAT(EXTRACT('Year' FROM date),'-',EXTRACT('MONTH' FROM date))

-- Analyzing total vaccinations vs people fully vaccinated
SELECT location, SUM(total_vaccinations) AS vaccination_count, SUM(people_fully_vaccinated) AS fully_vac
FROM Public."CovidVaccinations"
GROUP BY location
ORDER BY location

-- Global Numbers 
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases))*100 AS total_death_percentage 
FROM Public."CovidDeaths"
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1 DESC

-- Joining Tables
SELECT *
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
ON dea.location = vac.location
AND dea.date = vac.date

-- Looking at total population vs vaccinations using CTE
WITH popvsvac (continent, location, date, population, new_vaccinations, rolling_vaccinated_individuals)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								 dea.date) AS 	rolling_vaccinated_individuals
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--AND dea.location ILIKE '%africa%'
)
SELECT *, (rolling_vaccinated_individuals / population)*100 AS vaccinated_population
FROM popvsvac

-- Temp Table 
DROP TABLE IF EXISTS VacPopulationPercentage;
CREATE TEMP TABLE VacPopulationPercentage
(
continent varchar(255),
location varchar(255),
date date,
population numeric,
new_vaccinated numeric,
rolling_vaccinated_individuals numeric	
);	

INSERT INTO VacPopulationPercentage
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								 dea.date) AS 	rolling_vaccinated_individuals
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
ON dea.location = vac.location
AND dea.date = vac.date;
--WHERE dea.continent IS NOT NULL;

SELECT *, (rolling_vaccinated_individuals / population)*100 AS vaccinated_population
FROM VacPopulationPercentage

-- Looking at location vs total people had boosters using subqueries
SELECT DISTINCT date, continent, location, SUM(total_boosters) OVER (PARTITION BY location ORDER BY location) AS rolling_boosters
FROM Public."CovidVaccinations"
WHERE location in (
      SELECT location
      FROM Public."CovidDeaths" 
      WHERE continent IS NOT NULL
      GROUP BY continent, location)

-- Creating views to store data for visualizations
CREATE VIEW VacPopulationPercentage AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,
								 dea.date) AS 	rolling_vaccinated_individuals
FROM Public."CovidDeaths" dea
JOIN Public."CovidVaccinations" vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM VacPopulationPercentage