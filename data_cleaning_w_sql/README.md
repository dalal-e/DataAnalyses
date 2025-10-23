The purpose of this project is to explore data insights from housing data provided from the city of Nashville
This project uses Excel and SQL to clean data.

# Table of Contents
1. Data source
2. Pre-processing
3. Analyses
	1. Cases vis-à-vis Deaths
	2. Cases vis-à-vis Population
	3. Countries with highest case count
	4. Countries with highest death count
	5. Case count by continent
	6. Cases vis-à-vis Vaccination
4. Download file & Push to Github repository

## Data Source

Link to data: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx

## Data Processing
1. Import data into SQL
2. Cleaning data using SQL queries
```sql
-- remove sale date
select saledate, convert(date, saledate)
from portfolioproject.dbio.nashvillehousing;

update nashvillehousing
set alde date = convert(date, saledate);

-- OR

alter table nashvillehousing
add saledateconverted date;

update nashvillehousing
set saledateconverted = convert(date, saledate);
```


3. renamed sheet to nashville_housing
4. Standardize date format
5. Populate Property Address data
```sql
select propertyaddress
from portfolioproject.dbo.nashvillehousing
where propertyaddress is null;

select * from portfolioproject.dbo.nashvillehousing
where propertyaddress is null;

select * from portfolioproject.dbo.nashvillehousing
order by ParceID;

-- notice there are duplicate parceids. to deal with nulls in property addresses, use the value in property address of one parce id to popoulate the other. requires a join

select a.parceid, a.propertyaddress, b.parceid, b.propertyaddress
from portfolioproject.db.nashvillehousing a
join portfolioproject.dbo.nashvillehousing b
	on a.parceid = b.parceid
	and a.[unique id] <> b.[unique.id]; -- don't want clashes

select a.parceid, a.propertyaddress, b.parceid, b.propertyaddress
from portfolioproject.db.nashvillehousing a
join portfolioproject.dbo.nashvillehousing b
	on a.parceid = b.parceid
	and a.[unique id] <> b.[unique.id]
where a.propertyaddress is null; --shows problem records

select a.parceid, a.propertyaddress, b.parceid, b.propertyaddress, isnull(a.propertyaddress,b.propertyaddress)
from portfolioproject.db.nashvillehousing a
join portfolioproject.dbo.nashvillehousing b
	on a.parceid = b.parceid
	and a.[unique id] <> b.[unique.id]
where a.propertyaddress is null;

update a
set propertyaddress = isnull(a.propertyaddress,b.propertyaddress)
from portfolioproject.db.nashvillehousing a
join portfolioproject.dbo.nashvillehousing b
	on a.parceid = b.parceid
	and a.[unique id] <> b.[unique.id]
where a.propertyaddress is null;

select a.parceid, a.propertyaddress, b.parceid, b.propertyaddress, isnull(a.propertyaddress,b.propertyaddress)
from portfolioproject.db.nashvillehousing a
join portfolioproject.dbo.nashvillehousing b
	on a.parceid = b.parceid
	and a.[unique id] <> b.[unique.id]
where a.propertyaddress is null;
```

3. Breaking out Address into Individual Columns (Address, City, State)
```sql
select propertyaddress 
from portfolioproject.dbo.nashvillehousing
;

select
substring(propertyaddress, 1, CHARINDEX(',', PropertyAddress)) as address
from portfolioproject.dbo.nashvillehousing;

--- NOTE: substring(column to search, where to start, where to end)
--- following extracts the phrase after the comma

select
substring(propertyaddress, 1, CHARINDEX(',', PropertyAddress) - 1) as address,
substring(propertyaddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as address
from portfolioproject.dbo.nashvillehousing;



--- create columns 
alter table nashvillehousing
add PropertySplitAddress varchar(255);

update nashvillehousing
set propertysplitaddress = substring(propertyaddress, 1, CHARINDEX(',', PropertyAddress) - 1);

alter table nashvillehousing
add PropertySplitCity varchar(255);

update nashvillehousing
set propertysplitcity = substring(propertyaddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


--- OWNER ADDRESS

select owneraddress
from portfolioproject.dbo.nashvillehousing;

--- can use former method, but will use another

select
parsename(replace(owneraddress, ',', '.'), 3)
select
parsename(replace(owneraddress, ',', '.'), 2)
select
parsename(replace(owneraddress, ',', '.'), 1)
from portfolioproject.dbo.nashvillehousing;

alter table nashvillehousing
add OwnerSplitAddress varchar(255);

update nashvillehousing
set Ownersplitaddress = parsename(replace(owneraddress, ',', '.'), 3);

alter table nashvillehousing
add Ownersplitcity varchar(255);

update nashvillehousing
set Ownersplitcity = parsename(replace(owneraddress, ',', '.'), 2);

alter table nashvillehousing
add Ownersplitstate varchar(255);

update nashvillehousing
set Ownersplitstate = parsename(replace(owneraddress, ',', '.'), 1);
```
3. Change Y and N  to Yes and No t0 Sol
```sql
select distinct(soldasvacant)
from portfolioproject.dbo.nashvillehousing
group by soldasvacant
order by 2;
---method 1
update nashvillehousing
set soldasvacant = "No"
where soldasvacant = "N";

update nashvillehousing
set soldasvacant = "Yes"
where soldasvacant = "Y";

---method 2
select soldasvacant,
case when soldasvacant = 'Y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	else soldasvacant
	end
from portfolioproject.dbo.nashvillehousing;

update nashvillehousing
set soldasvacant=
case when soldasvacant = 'Y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	else soldasvacant
	end
;

```
3. Remove duplicates
```sql
---method one: use cte & row numbr

with dups as (
select *
	row_number() over (partition by parcelid, propertyaddress, saleprice, saledate, legalreference, order by uniqueid) as row_num
from portfolioproject.dbo.nashvillehousing
order by parcelid)

select * from dups
where row_num > 1
order by propertyaddress;

delete from dups
where row_num > 1
order by propertyaddress;
```

3. Delete Unused columns
```sql
alter table portfolioproject.dbo.nashvillehousing
drop column owneraddress, taxdistrict, propertyaddress, saledate
```
