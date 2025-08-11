-- EDA
-- explore the data and find trends or patterns or anything interesting 


SELECT * 
FROM world_layoffs.layoffs_staging2;

-- EASIER QUERIES

SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;


-- Looking at Percentage to see how big these layoffs were
SELECT MAX(percentage_laid_off),  MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off IS NOT NULL;

-- Which companies had 1 which is basically 100 percent of they company laid off
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1;
-- these are mostly startups it looks like who all went out of business during this time

-- if we order by funcs_raised_millions we can see how big some of these companies were
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE  percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- BritishVolt looks like an EV company, Quibi! I recognize that company - wow raised like 2 billion dollars and went under - ouch




-- SOMEWHAT TOUGHER AND MOSTLY USING GROUP BY
-- Companies with the biggest single Layoff

SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- Companies with the most Total Layoffs
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;


-- by location
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- this it total in the past 3 years or in the dataset

SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;


SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;


SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;






-- TOUGHER QUERIES

-- Earlier we looked at Companies with the most Layoffs. Now let's look at that per year. It's a little more difficult.
-- I want to look at 

WITH Company_Year AS 
(
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
  SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- Rolling Total of Layoffs Per Month
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

-- now use it in a CTE so we can query off of it
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;

-- export the EDA
-- Combined EDA results with section identifiers

-- Combined EDA results with proper GROUP BY handling
(
    -- Basic Statistics Section
    SELECT 
        'basic_stats' AS analysis_section,
        'Max Single Layoff' AS metric_name,
        MAX(total_laid_off) AS metric_value,
        NULL AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM world_layoffs.layoffs_staging2
    
    UNION ALL
    
    SELECT 
        'basic_stats' AS analysis_section,
        'Max Percentage Laid Off' AS metric_name,
        MAX(percentage_laid_off) AS metric_value,
        NULL AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM world_layoffs.layoffs_staging2
    WHERE percentage_laid_off IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'basic_stats' AS analysis_section,
        'Min Percentage Laid Off' AS metric_name,
        MIN(percentage_laid_off) AS metric_value,
        NULL AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM world_layoffs.layoffs_staging2
    WHERE percentage_laid_off IS NOT NULL
)

UNION ALL

-- Top Companies Section (using a derived table for proper grouping)
(
    SELECT 
        'top_companies' AS analysis_section,
        'Top Company' AS metric_name,
        total_layoffs AS metric_value,
        company AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM (
        SELECT 
            company,
            SUM(total_laid_off) AS total_layoffs
        FROM world_layoffs.layoffs_staging2
        GROUP BY company
        ORDER BY total_layoffs DESC
        LIMIT 10
    ) AS top_companies
)

UNION ALL

-- Yearly Totals Section
(
    SELECT 
        'yearly_totals' AS analysis_section,
        'Yearly Total' AS metric_name,
        yearly_sum AS metric_value,
        year AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM (
        SELECT 
            YEAR(date) AS year,
            SUM(total_laid_off) AS yearly_sum
        FROM world_layoffs.layoffs_staging2
        GROUP BY YEAR(date)
    ) AS yearly_data
)

UNION ALL

-- Rolling Totals Section
(
    SELECT 
        'rolling_totals' AS analysis_section,
        'Rolling Total' AS metric_name,
        rolling_sum AS metric_value,
        month_year AS detail_1,
        NULL AS detail_2,
        NULL AS detail_3
    FROM (
        SELECT 
            DATE_FORMAT(date, '%Y-%m') AS month_year,
            SUM(SUM(total_laid_off)) OVER (ORDER BY DATE_FORMAT(date, '%Y-%m')) AS rolling_sum
        FROM world_layoffs.layoffs_staging2
        GROUP BY DATE_FORMAT(date, '%Y-%m')
    ) AS rolling_data
)

ORDER BY 
    FIELD(analysis_section, 'basic_stats', 'top_companies', 'yearly_totals', 'rolling_totals'),
    CASE WHEN analysis_section = 'top_companies' THEN -metric_value ELSE metric_value END;

--  use Workbench's export wizard on this combined result set










































