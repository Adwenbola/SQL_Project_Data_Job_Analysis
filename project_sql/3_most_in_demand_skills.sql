# THE MOST IN DEMAND SKILLS FOR THE DATA ANALYST JOBS
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

# ALTERNATIVE SOLUTION


SELECT skills,
       COUNT(sjd.skill_id) AS skills_count
FROM job_postings_fact jb 
INNER JOIN skills_job_dim sjd
ON jb.job_id = sjd.job_id
INNER JOIN skills_dim sd
ON sd.skill_id = sjd.skill_id
WHERE jb.job_work_from_home = TRUE 
  AND jb.job_title_short = 'Data Analyst'
GROUP BY skills
ORDER BY skills_count DESC
LIMIT 5;