-- Create database

create database cleaning_w_sql_2025;

-- Import data (done with table import wizard)

-- Preview data
SELECT * 
FROM cleaning_w_sql_2025.layoffs_raw;



-- create new table where data will be cleaned & transformed
CREATE TABLE layoffs_clean LIKE cleaning_w_sql_2025.layoffs_raw;

INSERT layoffs_clean 
SELECT * FROM cleaning_w_sql_2025.layoffs_raw;

SELECT * FROM layoffs_clean;


-- Data cleaning procedure
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values & see if they can be filled
-- 4. Drop unnecessary fields & records



-- 1. Remove Duplicates

SELECT *
FROM cleaning_w_sql_2025.layoffs_clean;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		cleaning_w_sql_2025.layoffs_clean;



SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		cleaning_w_sql_2025.layoffs_clean
) duplicates
WHERE 
	row_num > 1;
    
-- Look at records to confirm
SELECT *
FROM cleaning_w_sql_2025.layoffs_clean
WHERE company = 'Oda'
;
-- FALSE POSITIVE: these are legitimate entries since funds_raise_millions data are different

-- these are real duplicates
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		cleaning_w_sql_2025.layoffs_clean
) duplicates
WHERE 
	row_num > 1;

-- delete where row number is greater than 1

-- now you may want to write it like this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		cleaning_w_sql_2025.layoffs_clean
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM cleaning_w_sql_2025.layoffs_clean
)
DELETE FROM cleaning_w_sql_2025.layoffs_clean
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

ALTER TABLE cleaning_w_sql_2025.layoffs_clean ADD row_num INT;


SELECT *
FROM cleaning_w_sql_2025.layoffs_clean
;

CREATE TABLE `cleaning_w_sql_2025`.`layoffs_clean2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `cleaning_w_sql_2025`.`layoffs_clean2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		cleaning_w_sql_2025.layoffs_clean;

-- now that we have this we can delete rows were row_num is greater than 2

DELETE FROM cleaning_w_sql_2025.layoffs_clean2
WHERE row_num >= 2;







-- 2. Standardize Data

SELECT * 
FROM cleaning_w_sql_2025.layoffs_clean2;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
SELECT DISTINCT industry
FROM cleaning_w_sql_2025.layoffs_clean2
ORDER BY industry;

SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- let's take a look at these
SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE company LIKE 'Bally%';
-- nothing wrong here
SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

-- we should set the blanks to nulls since those are typically easier to work with
UPDATE cleaning_w_sql_2025.layoffs_clean2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all null

SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate those nulls if possible

UPDATE layoffs_clean2 t1
JOIN layoffs_clean2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- and if we check it looks like Bally's was the only one without a populated row to populate this null values
SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- ---------------------------------------------------

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto
SELECT DISTINCT industry
FROM cleaning_w_sql_2025.layoffs_clean2
ORDER BY industry;

UPDATE layoffs_clean2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- now that's taken care of:
SELECT DISTINCT industry
FROM cleaning_w_sql_2025.layoffs_clean2
ORDER BY industry;

-- --------------------------------------------------
-- we also need to look at 

SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM cleaning_w_sql_2025.layoffs_clean2
ORDER BY country;

UPDATE layoffs_clean2
SET country = TRIM(TRAILING '.' FROM country);

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM cleaning_w_sql_2025.layoffs_clean2
ORDER BY country;


-- Let's also fix the date columns:
SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2;

-- we can use str to date to update this field
UPDATE layoffs_clean2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs_clean2
MODIFY COLUMN `date` DATE;


SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2;





-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values




-- 4. remove any columns and rows we need to

SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE total_laid_off IS NULL;


SELECT *
FROM cleaning_w_sql_2025.layoffs_clean2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM cleaning_w_sql_2025.layoffs_clean2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM cleaning_w_sql_2025.layoffs_clean2;

ALTER TABLE layoffs_clean2
DROP COLUMN row_num;


SELECT * 
FROM cleaning_w_sql_2025.layoffs_clean2;