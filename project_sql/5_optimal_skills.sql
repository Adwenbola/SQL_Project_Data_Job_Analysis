# WHAT ARE THE MOST OPTIMAL SKILLS
WITH skills_demand AS (
    SELECT 
           sd.skill_id,
           sd.skills,
           COUNT(sjd.skill_id) AS skills_count
    FROM job_postings_fact jb 
    INNER JOIN skills_job_dim sjd
    ON jb.job_id = sjd.job_id
    INNER JOIN skills_dim sd
    ON sd.skill_id = sjd.skill_id
    WHERE jb.job_work_from_home = TRUE 
      AND jb.salary_year_avg IS NOT NULL
      AND jb.job_title_short = 'Data Analyst'
    GROUP BY sd.skill_id
    
), average_salary AS (
    SELECT 
           sd.skill_id,
           sd.skills,
           ROUND(AVG(jb.salary_year_avg), 0) AS avg_salary
    FROM job_postings_fact jb 
    INNER JOIN skills_job_dim sjd
    ON jb.job_id = sjd.job_id
    INNER JOIN skills_dim sd
    ON sd.skill_id = sjd.skill_id
    WHERE jb.job_work_from_home = TRUE 
      AND jb.job_title_short = 'Data Analyst'
      AND jb.salary_year_avg IS NOT NULL
    GROUP BY sd.skill_id
    
)

SELECT skills_demand.skill_id,
       skills_demand.skills,
       skills_demand.skills_count,
       average_salary.avg_salary
FROM skills_demand
JOIN average_salary
ON skills_demand.skill_id = average_salary.skill_id
WHERE skills_demand.skills_count > 10
ORDER BY 
         average_salary.avg_salary DESC,
         skills_demand.skills_count DESC
LIMIT 25;



# ALTERNATIVE SOLUTION
SELECT sd.skill_id,
       sd.skills,
       COUNT(sjd.skill_id) AS skills_count,
       ROUND(AVG(jb.salary_year_avg), 0) AS avg_salary
FROM job_postings_fact jb 
INNER JOIN skills_job_dim sjd
ON jb.job_id = sjd.job_id
INNER JOIN skills_dim sd    
ON sd.skill_id = sjd.skill_id
WHERE jb.job_work_from_home = TRUE 
  AND jb.job_title_short = 'Data Analyst'
  AND jb.salary_year_avg IS NOT NULL
GROUP BY sd.skill_id
HAVING COUNT(sjd.skill_id) > 10
ORDER BY 
         avg_salary DESC,
         skills_count DESC
LIMIT 25;
