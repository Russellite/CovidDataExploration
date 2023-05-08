/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
	From PortfolioProject..CovidDeaths
	Where continent is not null 
	order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if one contracts covid in a country, say Brazil

Select Location, date, total_cases, total_deaths, 
	(Convert(float, total_deaths) / Convert(float, total_cases))*100 as DeathPercentage
	From PortfolioProject..CovidDeaths
	Where location = 'Brazil'
	and continent is not null 
	order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  
	(total_cases/population)*100 as PercentPopulationInfected
	From PortfolioProject..CovidDeaths
	order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,
	Max((convert(float, total_cases)/population))*100 as PercentPopulationInfected
	From PortfolioProject..CovidDeaths
	Group by Location, Population
	order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(convert(float, Total_deaths)) as TotalDeathCount
	From PortfolioProject..CovidDeaths
	Where continent is not null 
	Group by Location
	order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(convert(float, Total_deaths)) as TotalDeathCount
	From PortfolioProject..CovidDeaths
	Where continent is not null 
	Group by continent
	order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, 
	SUM(convert(float, new_deaths)) as total_deaths, 
	SUM(convert(float, new_deaths))/SUM(New_Cases)*100 as DeathPercentage
	From PortfolioProject..CovidDeaths
	where continent is not null 
	order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(convert(float,cv.new_vaccinations)) 
	OVER (Partition by cd.Location Order by cd.location, cd.Date) 
	as RollingPeopleVaccinated
	From PortfolioProject..CovidDeaths cd
	Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
	where cd.continent is not null 
	order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
	Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(convert(float,cv.new_vaccinations)) 
	OVER (Partition by cd.Location Order by cd.location, cd.Date) 
	as RollingPeopleVaccinated
	From PortfolioProject..CovidDeaths cd
	Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
	where cd.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(convert(float,cv.new_vaccinations)) 
	OVER (Partition by cd.Location Order by cd.location, cd.Date) 
	as RollingPeopleVaccinated
	From PortfolioProject..CovidDeaths cd
	Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
	where cd.continent is not null 
	order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(convert(float,cv.new_vaccinations)) 
	OVER (Partition by cd.Location Order by cd.location, cd.Date) 
	as RollingPeopleVaccinated
	From PortfolioProject..CovidDeaths cd
	Join PortfolioProject..CovidVaccinations cv
	On cd.location = cv.location
	and cd.date = cv.date
	where cd.continent is not null 
