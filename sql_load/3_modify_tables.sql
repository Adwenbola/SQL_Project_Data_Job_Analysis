/*
Count the number of unique companies that offer work from home (WFH)
 versus those requiring work to be on-site. Use the job_postings_fact table
  to count and compare the distinct companies based on their WFH policy (job_work_from_home).
*/


SELECT 
    COUNT(DISTINCT CASE WHEN job_work_from_home = TRUE THEN company_id END) AS wfh_companies,
    COUNT(DISTINCT CASE WHEN job_work_from_home = FALSE THEN company_id END) AS non_wfh_companies
FROM job_postings_fact;

SELECT 
    company_id,
    name AS company_name
FROM company_dim
WHERE company_id IN (
    SELECT company_id 
FROM job_postings_fact
WHERE job_no_degree_mention = TRUE
ORDER BY company_id
)

WITH campany_job_count AS (
    SELECT company_id, COUNT(company_id) as job_count
    FROM job_postings_fact
    GROUP BY company_id
)
SELECT company_dim.name, campany_job_count.job_count
FROM company_dim
LEFT JOIN campany_job_count
ON company_dim.company_id = campany_job_count.company_id
ORDER BY campany_job_count.job_count DESC;

WITH count_of_remote_jobs AS (
    SELECT company_id, COUNT(company_id) AS job_count
    FROM job_postings_fact
    WHERE job_work_from_home = TRUE
    GROUP BY company_id
);



WITH remote_skills_count AS (
    SELECT skill_id,
    COUNT(skill_id) AS skills_to_job
    FROM skills_job_dim
    JOIN job_postings_fact
    ON skills_job_dim.job_id = job_postings_fact.job_id
    WHERE job_work_from_home = TRUE AND job_title_short = 'Data Analyst'
    GROUP BY skill_id
)
SELECT remote_skills_count.skill_id, skills_dim.skills, remote_skills_count.skills_to_job
FROM remote_skills_count
JOIN skills_dim 
ON skills_dim.skill_id = remote_skills_count.skill_id
ORDER BY skills_to_job DESC
LIMIT 5;


/*
Identify the top 5 skills that are most frequently mentioned in job postings.
 Use a subquery to find the skill IDs with the highest counts in the skills_job_dim table
  and then join this result with the skills_dim table to get the skill names.
Hint
Focus on creating a subquery that identifies and ranks (ORDER BY in descending order)
 the top 5 skill IDs by their frequency (COUNT) of mention in job postings.
Then join this subquery with the skills table (skills_dim) to match IDs to skill names.
*/
SELECT skills_dim.skills
FROM skills_dim
JOIN (  SELECT skill_id, COUNT(skill_id) AS skills_count
        FROM skills_job_dim
        GROUP BY skill_id
        ORDER BY skills_count DESC
        LIMIT 5) AS top_skills
ON skills_dim.skill_id = top_skills.skill_id
 
SELECT skills_dim.skills
FROM skills_dim
INNER JOIN (
    SELECT 
        skill_id,
        COUNT(job_id) AS skill_count
    FROM skills_job_dim
    GROUP BY skill_id
    ORDER BY COUNT(job_id) DESC
    LIMIT 5
) AS top_skills ON skills_dim.skill_id = top_skills.skill_id
ORDER BY top_skills.skill_count DESC;
/*
Determine the size category ('Small', 'Medium', or 'Large') for each company by first identifying
the number of job postings they have. Use a subquery to calculate the total job postings per company.
A company is considered 'Small' if it has less than 10 job postings, 'Medium' if the number of job postings
is between 10 and 50, and 'Large' if it has more than 50 job postings. Implement a subquery to aggregate job
counts per company before classifying them based on size.
Hint
Aggregate job counts per company in the subquery. This involves grouping by company and counting job postings.
Use this subquery in the FROM clause of your main query.
In the main query, categorize companies based on the aggregated job counts from the subquery with a CASE statement.
The subquery prepares data (counts jobs per company), and the outer query classifies companies based on these counts.
*/
SELECT  company_id,
        name,       
CASE
    WHEN job_count < 10 THEN 'SMALL COMPAYNY'
    WHEN job_count BETWEEN 10 AND 50 THEN 'MEDIUM COMPANY'
    ELSE 'LARGE COMPANY'
END AS company_size_category
FROM (
        SELECT cd.company_id, cd.name, COUNT(jb.job_id) AS job_count
        FROM job_postings_fact jb
        JOIN company_dim cd
        ON jb.company_id = cd.company_id
        GROUP BY cd.company_id, cd.name        
) AS sub



/*
Identify companies with the most diverse (unique) job titles. Use a CTE to count 
the number of unique job titles per company, then select companies with the highest diversity
in job titles.
Hint
Use a CTE to count the distinct number of job titles for each company.
After identifying the number of unique job titles per company, join this result
with the company_dim table to get the company names.
Order your final results by the number of unique job titles in descending order to 
highlight the companies with the highest diversity.
Limit your results to the top 10 companies. This limit helps focus on the companies with
the most significant diversity in job roles. Think about how SQL determines which 
companies make it into the top 10 when there are ties in the number of unique job titles.
*/

WITH unique_title AS (
     SELECT company_id, COUNT(DISTINCT job_title) AS unique_title_count
     FROM job_postings_fact 
     GROUP BY company_id
) 
SELECT company_dim.name, unique_title.unique_title_count
FROM unique_title 
JOIN company_dim
ON unique_title.company_id = company_dim.company_id
ORDER BY unique_title_count DESC
LIMIT 10

 
 /*
Explore job postings by listing job id, job titles, company names, and their average salary rates, 
while categorizing these salaries relative to the average in their respective countries. Include 
the month of the job posted date. Use CTEs, conditional logic, and date functions, 
to compare individual salaries with national averages.
Hint
Define a CTE to calculate the average salary for each country. This will serve as a 
foundational dataset for comparison.
Within the main query, use a CASE WHEN statement to categorize each salary as 
'Above Average' or 'Below Average' based on its comparison (>) to the country's average salary 
calculated in the CTE.
To include the month of the job posting, use the EXTRACT function on the job posting date 
within your SELECT statement.
Join the job postings data (job_postings_fact) with the CTE to compare individual salaries 
to the average. Additionally, join with the company dimension (company_dim) table to get company 
names linked to each job posting.
 */

 WITH avg_salary_per_country AS (
    SELECT job_country, AVG(salary_year_avg) AS yearly_average_salary
    FROM job_postings_fact
    GROUP BY job_country
 )
 SELECT jb.job_id,
        jb.job_title, 
        cd.name,
        jb.salary_year_avg,       
CASE
    WHEN jb.salary_year_avg > avg_salary_per_country.yearly_average_salary THEN 'ABOVE AVERAGE'
    ELSE 'BELOW AVERAGE'
END AS salary_category,
EXTRACT(MONTH FROM jb.job_posted_date) AS posting_month
FROM job_postings_fact jb
JOIN company_dim cd
ON jb.company_id = cd.company_id
JOIN avg_salary_per_country
ON jb.job_country = avg_salary_per_country.job_country
ORDER BY posting_month DESC
 


-- Counts the distinct skills required for each company's job posting
WITH required_skills AS (
    SELECT
        companies.company_id,
        COUNT(DISTINCT skills_to_job.skill_id) AS unique_skills_required
    FROM
        company_dim AS companies 
    LEFT JOIN job_postings_fact as job_postings ON companies.company_id = job_postings.company_id
    LEFT JOIN skills_job_dim as skills_to_job ON job_postings.job_id = skills_to_job.job_id
    GROUP BY
        companies.company_id
),
-- Gets the highest average yearly salary from the jobs that require at least one skills 
max_salary AS (
    SELECT
        job_postings.company_id,
        MAX(job_postings.salary_year_avg) AS highest_average_salary
    FROM
        job_postings_fact AS job_postings
    WHERE
        job_postings.job_id IN (SELECT job_id FROM skills_job_dim)
    GROUP BY
        job_postings.company_id
)
-- Joins 2 CTEs with table to get the query
SELECT
    companies.name,
    required_skills.unique_skills_required as unique_skills_required, --handle companies w/o any skills required
    max_salary.highest_average_salary
FROM
    company_dim AS companies
LEFT JOIN required_skills ON companies.company_id = required_skills.company_id
LEFT JOIN max_salary ON companies.company_id = max_salary.company_id
ORDER BY
    companies.name;


SELECT job_title, company_id, job_location
FROM january_jobs
UNION
SELECT job_title, company_id, job_location
FROM february_jobs

/*
Create a unified query that categorizes job postings into two groups:
those with salary information (salary_year_avg or salary_hour_avg is not null) 
and those without it. Each job posting should be listed with its job_id, job_title, 
and an indicator of whether salary information is provided.

Hint
Use UNION ALL to merge results from two separate queries.
For the first query, filter job postings where either salary field is 
not null to identify postings with salary information.
For the second query, filter for postings where both salary fields are 
null to identify postings without salary information.
Include a custom field to indicate the presence or absence of salary information in the output.
When categorizing data, you can create a custom label directly in your query using string literals,
such as 'With Salary Info' or 'Without Salary Info'. These literals are manually inserted
values that indicate specific characteristics of each record. An example of this is as 
a new column in the query that doesn’t have salary information, put: 'Without Salary Info' 
AS salary_info. As the last column in the SELECT statement.
*/

SELECT job_id, job_title, salary_year_avg, salary_hour_avg, 'With_Salary_Info' AS salary_info
FROM job_postings_fact
WHERE (salary_year_avg IS NOT NULL OR salary_hour_avg IS NOT NULL)  
UNION ALL
SELECT job_id, job_title, salary_year_avg, salary_hour_avg, 'Without_Salary_Info' AS salary_info
FROM job_postings_fact
WHERE (salary_year_avg IS NULL AND salary_hour_avg IS NULL) 

/*
Retrieve the job id, job title short, job location, job via, skill and skill type for each job posting
from the first quarter (January to March). Using a subquery to combine job postings from the first quarter
(these tables were created in the Advanced Section - Practice Problem 6 Video) Only include postings with
an average yearly salary greater than $70,000.
Hint
Use UNION ALL to combine job postings from January, February, and March into a single dataset.
Apply a LEFT JOIN to include skills information, allowing for job postings without associated
skills to be included.
Filter the results to only include job postings with an average yearly salary above $70,000.*/

SELECT quarter_jobs.job_id,
       quarter_jobs.job_title,
       quarter_jobs.job_location, 
       quarter_jobs.job_via, 
       sd.skills,
       sd.type
FROM(
    SELECT *
    FROM january_jobs
    UNION ALL
    SELECT *
    FROM february_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS quarter_jobs
LEFT JOIN skills_job_dim sjd
ON quarter_jobs.job_id = sjd.job_id
LEFT JOIN skills_dim sd
ON sjd.skill_id = sd.skill_id
WHERE salary_year_avg > 70000

/*
Analyze the monthly demand for skills by counting the number of job postings for each skill
in the first quarter (January to March), utilizing data from separate tables for each month. 
Ensure to include skills from all job postings across these months. The tables for the first 
quarter job postings were created in Practice Problem 6.
Hint
Use UNION ALL to combine job postings from January, February, and March into a consolidated dataset.
Apply the EXTRACT function to obtain the year and month from job posting dates, even though the month 
will be implicitly known from the source table.
Group the combined results by skill to summarize the total postings for each skill across the first quarter.
Join with the skills dimension table to match skill IDs with skill names.
*/

SELECT 
        COUNT(quarter_jobs.job_id) job_count,
        sd.skills,
        EXTRACT(MONTH FROM quarter_jobs.job_posted_date) AS month,
        EXTRACT(YEAR FROM quarter_jobs.job_posted_date) AS year
FROM(
    SELECT *
    FROM january_jobs
    UNION ALL
    SELECT *
    FROM february_jobs
    UNION ALL
    SELECT *
    FROM march_jobs
) AS quarter_jobs
LEFT JOIN skills_job_dim sjd
ON quarter_jobs.job_id = sjd.job_id
LEFT JOIN skills_dim sd
ON sjd.skill_id = sd.skill_id
WHERE job_title_short = 'Data Analyst'
GROUP BY sd.skills,
         quarter_jobs.job_posted_date
ORDER BY job_count DESC, month