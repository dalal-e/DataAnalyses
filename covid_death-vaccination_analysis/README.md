# Covid Death and Vaccination Analysis

## Project Overview

This project analyzes the relationship between COVID-19 case counts, death rates, vaccination rates, and population data for various countries and continents. By leveraging publicly available datasets, the analysis aims to uncover patterns, trends, and insights related to the pandemic's progression and its impact on different regions of the world. This project also explores how vaccination campaigns correlate with death rates and case counts. To visualize the data I found, I used Tableau.


---

## Table of Contents

1. [Data Source](#data-source)
2. [Pre-processing](#pre-processing)
3. [Analyses](#analyses)
    - [Cases vs Deaths](#cases-vs-deaths)
    - [Cases vs Population](#cases-vs-population)
    - [Countries with Highest Case Count](#countries-with-highest-case-count)
    - [Countries with Highest Death Count](#countries-with-highest-death-count)
    - [Case Count by Continent](#case-count-by-continent)
    - [Cases vs Vaccination](#cases-vs-vaccination)
4. [Download File & Push to GitHub Repository](#download-file-push-to-github-repository)
5. [Visualize Death and Vaccination Analysis in Tableau]

---

## Data Source

This project uses Our World in Data's dataset which tracks  COVID-19 deaths and vaccinations:
https://ourworldindata.org/covid-deaths

---

## Pre-processing

Before analysis, the datasets were cleaned and processed. I broke down the original dataset into two
further sheets: one containing death and cases data, and the other containing vaccination data. In SQL,
I will use joins to do more complex analysis.

Here are the key steps:

### 1. **Loading the Datasets**
- Imported the datasets into **Excel** for initial data manipulation.
- The **Population** field was moved to column **E** to ensure proper alignment.
- Removed unnecessary columns and saved the datasets as `.xlsx` files.
- This makes the first sheet for death and Covid cases
- For the second sheet, I removed every column which was in the first column

### 2. **Importing Data into SQL**
- The cleaned Excel files were imported into a **SQL Server database**.
- Queries were used to verify successful data import.

To verify the data was loaded correctly, the following queries were run:
```sql
select * from covid_deaths_project.covid_deaths order by 3, 4;
select * from covid_deaths_project.covid_vaccinations order by 3, 4;


Only the essential columns (location, date, total_cases, new_cases, total_deaths, and population) were selected for analysis.

## Analyses

This analysis compares the number of COVID-19 cases to the number of deaths in each country. The goal is to calculate the Death Percentage (the percentage of people who died after contracting COVID-19).

### Cases vs Deaths
select location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 as DeathPercentage
from covid_deaths_project.covid_deaths
order by 1, 2;

### Cases vs Population
select location, date, total_cases, population, (total_cases / population) * 100 as PercentageInfected
from covid_deaths_project.covid_deaths
where location like "%states%"
order by 1, 2;

### Countries with the Highest Case Count
This query identifies the countries with the highest number of COVID-19 cases relative to their population.

In SQL:
```sql
select location, date, max(total_cases) as highestinfectioncount, population, max((total_cases / population)) as percentpopulationinfected
from covid_deaths_project.covid_deaths
group by location, population
order by percentpopulationinfected desc;
```

### Countries with Highest Death Count
This analysis identifies the countries with the highest death count from COVID-19.

In SQL:
```sql
select location, max(cast(total_deaths as int)) as totaldeathcount
from covid_deaths_project.covid_deaths
group by location
order by totaldeathcount desc;
```

### Case Count by Continent
This analysis groups countries by continent and ranks them based on the total death count from COVID-19.

In SQL:
```sql
select continent, max(cast(total_deaths as int)) as totaldeathcount
from covid_deaths_project.covid_deaths
where continent is not null
group by continent
order by totaldeathcount desc;
```

###Cases vs Vaccination
This analysis explores the correlation between vaccination rates and the number of COVID-19 cases. By calculating the percentage of the population vaccinated, we can compare this data with case counts and deaths.

In SQL:
```sql
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated,
    (rollingpeoplevaccinated / population) * 100 as PercentageVaccinated
from covid_deaths_project.covid_deaths dea
join covid_deaths_project.covid_vaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2, 3;
```

To store this data for future analysis and visualization, a view was created:
```sql
create view percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
    sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from covid_deaths_project.covid_deaths dea
join covid_deaths_project.covid_vaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null;
```

## Download File & Push to Github Repository
Once the analysis is complete, the dataset was pushed to a Github repository:

In CLI:
```bash
git add .
git commit -m "Initial commit of data analysis project"
git push origin main
```


## Tableau Visualization

Create four visuals in Tableau

1. In MySQL, uses previous queries, run, press ctrl shift c, copies the data in results, go to excel and insert it into new sheet, and save as "Tableau Table 1", "Tableau Table 2", etc.
2. Deal with nulls. Do
	1. ctrl h, find nulls
	2. replace with 0

In Tableau
1. Click microsoft excel in left panel
2. Go to sheet 2, insert tables 2-4
3. go to sheet 1,  
	1. drag sum(total cases) to columns, also total deaths, death percentage
4. For sheet 2
	1. total death count in rows, location in columns
	2. sort them by right clicking location and sort
	3. rename table from location to continent
	4. consider changing axis, right click y axis
5. For sheet three (map)
	1. location change to geographic role country/region
	2. drag long to col, lat to row
	3. drag location, percent population infected to marks, change percent population to color
	4. click color in marks to edit colors. 
6. For sheet four
	1. date in col, percent population in rows
	2. change date to month
	3. location to marks, filter to select large countries
	4. locaiton to marks again, labels
	5. add predictive analysis, go to analysis, click forecast
7. Create dashboard
