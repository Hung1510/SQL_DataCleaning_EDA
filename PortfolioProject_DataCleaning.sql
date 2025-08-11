-- SQL Project - Data Cleaning

SELECT * 
FROM world_layoffs.layoffs;



-- create a staging table where will work in and clean the data,  want a table with the raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# check for duplicates

SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
-- look at oda to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'
;


-- these are  duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

WITH DELETE_CTE AS 
(
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE ls
FROM world_layoffs.layoffs_staging ls
JOIN DELETE_CTE dc
    ON ls.company = dc.company
    AND ls.location = dc.location
    AND ls.industry = dc.industry
    AND ls.total_laid_off <=> dc.total_laid_off
    AND ls.percentage_laid_off <=> dc.percentage_laid_off
    AND ls.`date` <=> dc.`date`
    AND ls.stage = dc.stage
    AND ls.country = dc.country
    AND ls.funds_raised_millions <=> dc.funds_raised_millions
WHERE dc.row_num > 1;


WITH DELETE_CTE AS (
    SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
           ) AS row_num
    FROM world_layoffs.layoffs_staging
)
DELETE ls
FROM world_layoffs.layoffs_staging ls
JOIN DELETE_CTE dc
    ON ls.company = dc.company
    AND ls.location = dc.location
    AND ls.industry = dc.industry
    AND ls.total_laid_off <=> dc.total_laid_off
    AND ls.percentage_laid_off <=> dc.percentage_laid_off
    AND ls.`date` <=> dc.`date`
    AND ls.stage = dc.stage
    AND ls.country = dc.country
    AND ls.funds_raised_millions <=> dc.funds_raised_millions
WHERE dc.row_num > 1;


-- Add row_num column to layoffs_staging
ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;

-- Select from layoffs_staging to verify
SELECT *
FROM world_layoffs.layoffs_staging;

-- Create layoffs_staging2 table
CREATE TABLE `world_layoffs`.`layoffs_staging2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT,
    `row_num` INT
);

-- Insert data into layoffs_staging2 with row_num
INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`, `row_num`)
SELECT 
    `company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Delete rows where row_num >= 2
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

-- Standardize Data
-- Set empty industry values to NULL
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Populate NULL industry values where possible
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Standardize Crypto industry variations
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- Remove trailing periods from country
UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- Handle date column: Set empty or invalid dates to NULL
UPDATE world_layoffs.layoffs_staging2
SET `date` = NULL
WHERE `date` = '' OR `date` IS NULL;

-- Convert valid dates to DATE format
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL;

-- Modify date column to DATE type
ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Verify data
SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Check distinct industries
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

-- Check distinct countries
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

-- Check for NULL or empty industries
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
   OR industry = ''
ORDER BY industry;

-- Delete rows where both total_laid_off and percentage_laid_off are NULL
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop row_num column
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

-- Final verification
SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Export cleaned data to CSV
SELECT * FROM world_layoffs.layoffs_staging2;
--  use Workbench's export wizard on this combined result set






























