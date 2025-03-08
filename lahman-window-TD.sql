/*
Question 1a: Warmup Question
Write a query which retrieves each teamid and number of wins (w) for the 2016 season. 
Apply three window functions to the number of wins (ordered in descending order) - ROW_NUMBER, RANK, AND DENSE_RANK. 
Compare the output from these three functions. What do you notice?
*/
-- Main Query
SELECT teamid, w 
FROM teams
WHERE yearid = 2016



-- Using ROW_NUMBER
SELECT 
	teamid,
	w,
	ROW_NUMBER()OVER(ORDER BY w DESC)
FROM teams
WHERE yearid = 2016
-- This one simply when ordered by wins, gives row numbers. It kinda ranks the teams by wins, using the initial placement for tiebreakers.


-- Using RANK
SELECT 
	teamid,
	w,
	RANK()OVER(ORDER BY w DESC)
FROM teams
WHERE yearid = 2016
-- This one accounts for tie-breakers, but counts two teams in one place as two different spots.


-- DENSE_RANK
SELECT 
	teamid,
	w,
	DENSE_RANK()OVER(ORDER BY w DESC)
FROM teams
WHERE yearid = 2016
-- This one also accounts for tie breakers, but teams with the same number of wins count in the same spot. 

/*
Question 1b:
Which team has finished in last place in its division (i.e. with the least number of wins) the most number of times?
A team's division is indicated by the divid column in the teams table.
*/

SELECT DISTINCT(divid)
FROM teams

WITH div_year_ranks AS (
	SELECT 
		teamid,
		w,
		yearid,
		divid,
		RANK()OVER(PARTITION BY divid, yearid ORDER BY w)
	FROM teams
	WHERE divid IN ('W','C','E')
)
SELECT COUNT(teamid) AS numtimeslast, teamid
FROM div_year_ranks AS dyr
WHERE dyr.rank = 1
GROUP BY dyr.teamid
ORDER BY numtimeslast DESC

-- The team that was last the most amount of times in their division was PHI with 19 times.








/*
Question 2: Cumulative Sums
Question 2a:
Barry Bonds has the record for the highest career home runs, with 762. Write a query which returns, for each season of Bonds' 
career the total number of seasons he had played and his total career home runs at the end of that season. (Barry Bonds' playerid is bondsba01.)
*/

SELECT
	playerid,
	yearid,
	hr,
	SUM(hr) OVER(ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS career_homeruns,
	COUNT(*) OVER(ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num_seasons_played
FROM batting
WHERE playerid = 'bondsba01';



/*
Question 2b:
How many players at the end of the 2016 season were on pace to beat Barry Bonds' record? 
For this question, we will consider a player to be on pace to beat Bonds' record if they have more 
home runs than Barry Bonds had the same number of seasons into his career.
*/

WITH main_query AS (
	SELECT
		playerid,
		yearid,
		hr,
		SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS career_homeruns,
		COUNT(*) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num_seasons_played
	FROM batting
),
barry_bonds AS (
	SELECT
		playerid,
		yearid,
		hr,
		SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS career_homeruns,
		COUNT(*) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num_seasons_played
	FROM batting
	WHERE playerid = 'bondsba01'
)
SELECT mq.*, bb.career_homeruns AS bb_career_hr, bb.num_seasons_played AS bb_total_seasons_played
FROM main_query AS mq
LEFT JOIN barry_bonds AS bb
ON mq.num_seasons_played = bb.num_seasons_played
WHERE mq.yearid = 2016 AND mq.career_homeruns > bb.career_homeruns


-- There were 18 players that were on track to beat Barry Bonds HR record at the end of 2016.


/*
Question 2c:
Were there any players who 20 years into their career who had hit more home runs at that point into their career than Barry Bonds had hit 20 years into his career?
*/


WITH main_query AS (
	SELECT
		playerid,
		yearid,
		hr,
		SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS career_homeruns,
		COUNT(*) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num_seasons_played
	FROM batting
),
barry_bonds AS (
	SELECT
		playerid,
		yearid,
		hr,
		SUM(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS career_homeruns,
		COUNT(*) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS num_seasons_played
	FROM batting
	WHERE playerid = 'bondsba01'
)
SELECT mq.*, bb.career_homeruns AS bb_career_hr, bb.num_seasons_played AS bb_total_seasons_played
FROM main_query AS mq
LEFT JOIN barry_bonds AS bb
ON mq.num_seasons_played = bb.num_seasons_played
WHERE mq.num_seasons_played = 20 AND mq.career_homeruns > bb.career_homeruns;

-- There was one player, and that was playerid 'aaronha01' in the year of 1973, having 5 more home runs than barry.




/*
Question 3: Anomalous Seasons
Find the player who had the most anomalous season in terms of number of home runs hit. 
To do this, find the player who has the largest gap between the number of home runs hit in a season and the 5-year 
moving average number of home runs if we consider the 5-year window centered at that year 
(the window should include that year, the two years prior and the two years after).
*/


WITH rolling_avg AS (
	SELECT 
		playerid,
		yearid,
		hr,
		ROUND(AVG(hr) OVER(PARTITION BY playerid ORDER BY yearid ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING),2) AS avg_hr_5year
	FROM batting
)
SELECT ra.*, hr - ra.avg_hr_5year AS largest_difference
FROM rolling_avg AS ra
ORDER BY largest_difference DESC
--WHERE playerid = 'greenha01';





/*
Question 4: Players Playing for one Team
For this question, we'll just consider players that appear in the batting table.
*/





/*
Question 4a:
Warmup: How many players played at least 10 years in the league and played for exactly one team? 
(For this question, exclude any players who played in the 2016 season). Who had the longest career with a single team? 
(You can probably answer this question without needing to use a window function.)
*/


WITH ten_years AS (
	SELECT playerid
	FROM batting
	GROUP BY playerid
	HAVING COUNT(playerid) >= 10 
),
players2016 AS (
	SELECT playerid
	FROM batting
	WHERE yearid = 2016
),
filtered_players AS (
	SELECT playerid
	FROM ten_years AS ty
	EXCEPT
	SELECT playerid
	FROM players2016
),
batting_filtered AS (
	SELECT b.*
	FROM filtered_players AS fp
	LEFT JOIN batting AS b
	ON b.playerid = fp.playerid
),
one_team AS (
	SELECT playerid, COUNT(DISTINCT(teamid))
	FROM batting_filtered
	GROUP BY playerid
	HAVING COUNT(DISTINCT(teamid)) = 1
)
SELECT *
FROM one_team




WITH ten_years AS (
	SELECT playerid
	FROM batting
	GROUP BY playerid
	HAVING COUNT(playerid) >= 10 
),
players2016 AS (
	SELECT playerid
	FROM batting
	WHERE yearid = 2016
),
filtered_players AS (
	SELECT playerid
	FROM ten_years AS ty
	EXCEPT
	SELECT playerid
	FROM players2016
),
batting_filtered AS (
	SELECT b.*
	FROM filtered_players AS fp
	LEFT JOIN batting AS b
	ON b.playerid = fp.playerid
),
one_team AS (
	SELECT playerid, COUNT(DISTINCT(teamid))
	FROM batting_filtered
	GROUP BY playerid
	HAVING COUNT(DISTINCT(teamid)) = 1
),
years_played_single_team AS (
	SELECT COUNT(b.yearid)OVER(PARTITION BY b.playerid) AS years_played, b.*
	FROM one_team AS ot
	LEFT JOIN batting AS b
	ON b.playerid = ot.playerid
	ORDER BY years_played DESC
)
SELECT DISTINCT(playerid), years_played, teamid
FROM years_played_single_team
WHERE years_played = 23;



-- There were 156 players that had atleast 10 years and played for only one team. (Found with just running code up to one_team CTE)
-- Playerid robinbr01 and yastrca01 had the longest careers with the same team, with 23 years.


/*
Question 4b:
Some players start and end their careers with the same team but play for other teams in between. 
For example, Barry Zito started his career with the Oakland Athletics, moved to the San Francisco Giants for 7 seasons 
before returning to the Oakland Athletics for his final season. How many players played at least 10 years in the league 
and start and end their careers with the same team but played for at least one other team during their career? 
For this question, exclude any players who played in the 2016 season.
*/

WITH ten_years AS (
	SELECT playerid
	FROM batting
	GROUP BY playerid
	HAVING COUNT(playerid) >= 10 
),
players2016 AS (
	SELECT playerid
	FROM batting
	WHERE yearid = 2016
),
filtered_players AS (
	SELECT playerid
	FROM ten_years AS ty
	EXCEPT
	SELECT playerid
	FROM players2016
),
batting_filtered AS (
	SELECT b.*
	FROM filtered_players AS fp
	LEFT JOIN batting AS b
	ON b.playerid = fp.playerid
),
multi_team AS (
	SELECT playerid, COUNT(DISTINCT(teamid))
	FROM batting_filtered
	GROUP BY playerid
	HAVING COUNT(DISTINCT(teamid)) >= 2
),
batting_extra_filtered AS (
	SELECT b.*
	FROM multi_team AS mt
	LEFT JOIN batting AS b
	ON b.playerid = mt.playerid
),
minmaxyears AS (
	SELECT 
		 playerid
		,yearid
		,teamid
		,MAX(yearid)OVER(PARTITION BY playerid) AS last_year
		,MIN(yearid)OVER(PARTITION BY playerid) AS first_year
	FROM batting_extra_filtered
	ORDER BY playerid, yearid 
)
SELECT playerid
FROM minmaxyears
WHERE yearid = last_year OR yearid = first_year
GROUP BY playerid
HAVING COUNT(DISTINCT(teamid)) = 1;

-- There were 190 players that fit the criteria of the question, and started and ended their careers on the same time with having switched teams at some point.

WITH ten_years AS (
	SELECT playerid
	FROM batting
	GROUP BY playerid
	HAVING COUNT(playerid) >= 10 
),
players2016 AS (
	SELECT playerid
	FROM batting
	WHERE yearid = 2016
),
filtered_players AS (
	SELECT playerid
	FROM ten_years AS ty
	EXCEPT
	SELECT playerid
	FROM players2016
),
batting_filtered AS (
	SELECT b.*
	FROM filtered_players AS fp
	LEFT JOIN batting AS b
	ON b.playerid = fp.playerid
),
multi_team AS (
	SELECT playerid, COUNT(DISTINCT(teamid))
	FROM batting_filtered
	GROUP BY playerid
	HAVING COUNT(DISTINCT(teamid)) >= 2
),
batting_extra_filtered AS (
	SELECT b.*
	FROM multi_team AS mt
	LEFT JOIN batting AS b
	ON b.playerid = mt.playerid
),
minmaxyears AS (
	SELECT 
		 playerid
		,yearid
		,teamid
		,MAX(yearid)OVER(PARTITION BY playerid) AS last_year
		,MIN(yearid)OVER(PARTITION BY playerid) AS first_year
	FROM batting_extra_filtered
	ORDER BY playerid, yearid 
),
list_of_players AS (
	SELECT playerid
	FROM minmaxyears
	WHERE yearid = last_year OR yearid = first_year
	GROUP BY playerid
	HAVING COUNT(DISTINCT(teamid)) = 1
)
SELECT mmy.*
FROM minmaxyears AS mmy
RIGHT JOIN list_of_players AS lop
ON lop.playerid = mmy.playerid
WHERE yearid = last_year OR yearid = first_year;



/*
Question 5: Streaks
Question 5a:
How many times did a team win the World Series in consecutive years?
*/

WITH prev_win_counts AS (
	SELECT
		 yearid
		,teamid
		,CASE WHEN wswin = 'Y' THEN 1
		 ELSE 0
		 END AS wswin_number
	FROM teams
	WHERE wswin IN ('Y','N')
),
streak_finder AS (
	SELECT pwc.*,
		CASE WHEN wswin_number = 1 AND LEAD(wswin_number)OVER(PARTITION BY teamid ORDER BY yearid) = 1 THEN 1
		ELSE 0 
		END AS streak_finder
	FROM prev_win_counts AS pwc
),
non_dupe_streak_finder AS (
	SELECT sf.*,
		CASE WHEN streak_finder = 1 AND LEAD(streak_finder)OVER(PARTITION BY teamid ORDER BY yearid) = 0 THEN 1
		ELSE 0
		END AS non_dupe_streak_finder
	FROM streak_finder AS sf
)
SELECT SUM(non_dupe_streak_finder), SUM(streak_finder)
FROM non_dupe_streak_finder



/*
Question 5b:
What is the longest steak of a team winning the World Series? Write a query that produces this result rather than scanning the output of your previous answer.
*/
WITH prev_win_counts AS (
	SELECT
		 yearid
		,teamid
		,CASE WHEN wswin = 'Y' THEN 1
		 ELSE 0
		 END AS wswin_number
	FROM teams
	WHERE wswin = 'Y'
)
SELECT *,
	
FROM prev_win_counts
ORDER BY teamid, yearid 



/*
Question 5c:
A team made the playoffs in a year if either divwin, wcwin, or lgwin will are equal to 'Y'. Which team has the longest streak of making the playoffs?
*/


/*
Question 5d:
The 1994 season was shortened due to a strike. If we don't count a streak as being broken by this season, does this change your answer for the previous part?
*/


/*
Question 6: Manager Effectiveness
Which manager had the most positive effect on a team's winning percentage? To determine this, calculate the average winning percentage in the three years before the manager's first full season and compare it to the average winning percentage for that manager's 2nd through 4th full season. Consider only managers who managed at least 4 full years at the new team and teams that had been in existence for at least 3 years prior to the manager's first full season.
*/