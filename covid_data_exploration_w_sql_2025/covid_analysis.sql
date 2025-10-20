/*
Covid 19 Data Exploration 

Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select *
from covid_deaths 
where continent is not null 
order by 3,4


-- select Data to pre-explore

select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
where continent is not null 
order by 1,2


-- Cases vis-a-vis Deaths
-- Shows likelihood of dying if you contract covid in your country

select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from covid_deaths
where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vis-a-vis Population
-- Shows what percentage of population infected with Covid

select location, date, population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
from covid_deaths
--Where location like '%states%'
order by 1,2


-- Countries with Covid Cases vis-a-vis Population

select location, population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
from covid_deaths
--where location like '%states%'
group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
from covid_deaths
--where location like '%states%'
where continent is not null 
group by Location
order by TotalDeathCount desc



-- Case count by continent

-- Showing contintents with the highest death count per population

select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
from covid_deaths
--Where location like '%states%'
where continent is not null 
group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(New_Cases)*100 as DeathPercentage
from covid_deaths
--where location like '%states%'
where continent is not null 
--group By date
order by 1,2



-- Total Population vis-a-vis Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid_deaths dea
join covid_vaccinations vac
	n dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Calculation on Partition By in previous query

with popvac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid_deaths dea
join covid_vaccinations vac
	n dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

Create Table population_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid_deaths dea
join covid_vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from population_vaccinated




-- creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from covid_deaths dea
Join covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

