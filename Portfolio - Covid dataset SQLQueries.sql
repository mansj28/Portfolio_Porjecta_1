-- Display all the data for covid deaths from Feb 2020 to Feb 2022
SELECT * FROM PorfolioProject..CovidDeaths
ORDER BY 3,4

-- Display all the data for covid vaccines from Feb 2020 to Feb 2022
SELECT * FROM PorfolioProject..CovidVaccines
ORDER BY 3,4

-- Display all the data for country and it's population
SELECT * FROM PorfolioProject..location_pop
ORDER BY 2 DESC

-- Join covid deaths and population data
CREATE VIEW 
[Coviddeathpop] AS
SELECT c.*, p.population
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location

-- Looking at total cases and total deaths
SELECT location, total_deaths, total_cases, ROUND(((total_deaths/total_cases)*100),2) as percent_death
FROM PorfolioProject..CovidDeaths
ORDER BY 1,2 DESC

-- Looking at percentage of total cases for the population in the United States for each day
-- Shows percentage of population that tested positive
SELECT c.location, Convert(DATE, c.date), c.total_cases, p.population, ROUND(((total_cases/population)*100),4) as percent_cases
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location
WHERE c.location like '%States%'
ORDER BY 1

-- Looking at percentage of total cases in the United States for each month for the given years
SELECT c.location, YEAR(c.date) as "Year", MONTH(c.date) as "Month", SUM(c.total_cases) as total_cases
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location
WHERE c.location like '%States%'
GROUP BY c.location, YEAR(c.date), MONTH(c.date)
ORDER BY 1

-- Looking at the countries with highest infection rate compared to the population
SELECT c.location, MAX(c.total_cases) as total_cases, ROUND(MAX((total_cases/population)*100),2) as percent_pop_infected
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location
GROUP BY c.location, p.population
ORDER BY percent_pop_infected DESC

-- Showing countries with highest death count per population by continent for the given years
SELECT c.continent, c.location, MAX(c.total_deaths) as total_deaths , p.population, ROUND(MAX((total_deaths/population)*100),2) as percent_pop_death
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location
WHERE c.continent IS NOT NULL
GROUP BY c.continent, c.location, p.population
ORDER BY percent_pop_death DESC

-- Global numbers - Death percentage by continent

SELECT c.continent, YEAR(c.date), SUM(cast(c.total_deaths as int)) as total_deaths , ROUND(((SUM(cast(c.total_deaths as int))/MAX(population))*100),2) as percent_pop_death
FROM PorfolioProject..CovidDeaths c LEFT JOIN
PorfolioProject..location_pop p ON
c.location = p.location
WHERE c.continent IS NOT NULL
GROUP BY c.continent, YEAR(c.date)
ORDER BY percent_pop_death DESC

-- Use a CTE 
WITH V_D AS
(
	SELECT v.location, v.date, v.total_vaccinations,
	d.total_deaths, d.total_cases, p.population
	FROM PorfolioProject..CovidVaccines v
	JOIN PorfolioProject..CovidDeaths d
	ON v.location = d.location
	AND v.date = d.date
	JOIN PorfolioProject..location_pop p
	ON v.location = p.location
)
SELECT * FROM V_D
ORDER BY 1 

-- Rolling number of new vaccinations by continent and date 
SELECT v.location, v.date, v.new_vaccinations, p.population,
SUM(CAST(v.new_vaccinations AS float)) over (partition by d.location order by d.location,  d.date) as "rolling_total_vaccines"
FROM PorfolioProject..CovidVaccines v
JOIN PorfolioProject..CovidDeaths d
ON v.location = d.location
AND v.date = d.date
JOIN PorfolioProject..location_pop p
ON v.location = p.location
WHERE d.continent IS NOT NULL

-- Rolling vaccines and vaccination percentage vs population using CTE
WITH rpv AS
(
	SELECT v.location, v.date, v.new_vaccinations, p.population,
	SUM(CAST(v.new_vaccinations AS float)) over (partition by d.location order by d.location,  d.date) as "rolling_total_vaccines"
	FROM PorfolioProject..CovidVaccines v
	JOIN PorfolioProject..CovidDeaths d
	ON v.location = d.location
	AND v.date = d.date
	JOIN PorfolioProject..location_pop p
	ON v.location = p.location
	WHERE d.continent IS NOT NULL
)
SELECT *, ROUND((rolling_total_vaccines/population),4) as "rolling_vaccine_percent" FROM rpv
ORDER BY location, rolling_vaccine_percent

-- Temp table
SELECT v.location, v.date, v.new_vaccinations, p.population,
	SUM(CAST(v.new_vaccinations AS float)) over (partition by d.location order by d.location,  d.date) as "rolling_total_vaccines"
	INTO #PercentPopulationVaccinated
	FROM PorfolioProject..CovidVaccines v
	JOIN PorfolioProject..CovidDeaths d
	ON v.location = d.location
	AND v.date = d.date
	JOIN PorfolioProject..location_pop p
	ON v.location = p.location
	WHERE d.continent IS NOT NULL

SELECT *, ROUND((rolling_total_vaccines/population),4) as "rolling_vaccine_percent" FROM #PercentPopulationVaccinated
ORDER BY location, rolling_vaccine_percent

-- Creating view to store data for later

CREATE VIEW PercentPopulationVaccinated AS
SELECT v.location, v.date, v.new_vaccinations, p.population,
SUM(CAST(v.new_vaccinations AS float)) over (partition by d.location order by d.location,  d.date) as "rolling_total_vaccines"
FROM PorfolioProject..CovidVaccines v
JOIN PorfolioProject..CovidDeaths d
ON v.location = d.location
AND v.date = d.date
JOIN PorfolioProject..location_pop p
ON v.location = p.location
WHERE d.continent IS NOT NULL