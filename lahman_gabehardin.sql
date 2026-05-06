-- 1. What range of years for baseball games played does the provided database cover?

SELECT *
FROM appearances

SELECT MIN(yearID),MAX(yearID)
FROM appearances; 
--1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT namegiven
	,MIN (height) AS min_height
	,COUNT(g_all) AS games_played
	,teams.name
FROM people
	INNER JOIN appearances USING(playerid)
	INNER JOIN teams USING (yearID,teamid)
GROUP BY namegiven, teams.name
ORDER BY min_height ASC;

SELECT playerid,height,namegiven
FROM people
	INNER JOIN app
ORDER BY height
LIMIT 1

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as 
	-- the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
	
SELECT DISTINCT playerid, schoolname, namefirst || ' ' || namelast AS full_name, SUM (salary)::numeric::money AS total_salary
FROM collegeplaying
	JOIN schools USING (schoolid)
	JOIN people USING (playerid)
	LEFT JOIN salaries USING (playerid)
WHERE schoolname = 'Vanderbilt University'
GROUP BY playerid, schoolname, full_name
ORDER BY total_salary DESC NULLS LAST;

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with
	--position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT SUM(PO),
	CASE WHEN pos = 'OF' THEN 'Outfield'
 		 WHEN pos IN ('P','C') THEN 'Battery'
	  	 WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'	
END AS field_pos	  
FROM  fielding
WHERE yearid = 2016
GROUP BY field_pos
 
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home
	--runs per game. Do you see any trends?

SELECT
	 ROUND(SUM(so)::numeric / SUM(g), 2) AS so_avg
	,ROUND(SUM(hr)::numeric / SUM(g), 2) AS hr_avg
	,(yearid / 10) * 10 AS decade
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts
	--which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst||' '||namelast AS full_name, SUM(sb)+SUM(cs)AS steal_attempts, ROUND(SUM(sb::numeric)/(SUM(sb::numeric)+SUM(cs::numeric))*100,0) AS steal_percentage
FROM batting
	INNER JOIN people USING (playerid)
WHERE yearid = '2016' 
GROUP BY playerid,full_name
	HAVING SUM(sb)+SUM(cs) >=20
ORDER BY steal_percentage DESC
LIMIT 1; 
-- Chris Owings

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for
	--a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine 
	-- why this is the case. Then redo your query, excluding the problem year. 

(SELECT yearid,name AS series_winners, SUM(W)AS season_wins
FROM teams
WHERE yearid >= 1970 AND WSWIN = 'N'
GROUP BY yearid,name
ORDER BY season_wins DESC
LIMIT 1)
UNION
(SELECT yearid,name, SUM(w)AS season_wins
FROM teams
WHERE yearid >= 1970 AND WSWIN = 'Y' AND yearid != 1981
GROUP BY yearid,name
ORDER BY season_wins ASC
LIMIT 1); -- the 1981 season was shortened by a strike

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH rs_champs AS
	(
	SELECT yearid,MAX(w)AS w
	FROM teams
	WHERE yearid >=1970
	GROUP BY yearid
	),
	ws_winners AS
	(
	SELECT DISTINCT yearid,w,name,WSWIN
	FROM teams
		INNER JOIN rs_champs USING(yearid,w) 
	)
SELECT SUM(CASE WHEN wswin = 'Y' THEN 1 END)/COUNT(yearid)::numeric * 100 AS dominant_champ_percentage
FROM ws_winners

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
	--(where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. 
	--Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

(SELECT yearid,teams.name, park_name, h.attendance / games AS avg_stadium_attendance--, SUM(teams.attendance)/SUM(teams.g) AS avg_team_attendance
FROM homegames h
	JOIN parks USING (park)
	JOIN teams ON teams.teamid = h.team AND yearid = h.year
WHERE year = 2016 AND games >=10
ORDER BY avg_stadium_attendance DESC
LIMIT 5)
UNION all
(SELECT yearid,teams.name, park_name, h.attendance / games AS avg_stadium_attendance--, SUM(teams.attendance)/SUM(teams.g) AS avg_team_attendance
FROM homegames h
	JOIN parks USING (park)
	JOIN teams ON teams.teamid = h.team AND yearid = h.year
WHERE year = 2016 AND games >=10
ORDER BY avg_stadium_attendance ASC
LIMIT 5)

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full 
	--name and the teams that they were managing when they won the award.
-- what tables do I actually need?

--Jason
WITH dbl_winners AS
	(SELECT 
		am.playerid
   		,p.namefirst || ' ' || p.namelast AS full_name
   	    ,am.lgid
   	    ,am.yearid
   	    ,m.teamid
	FROM awardsmanagers AS am
   		JOIN people AS p USING (playerid)
   	    JOIN managers AS m USING (playerid, yearid, lgid)
        WHERE am.awardid = 'TSN Manager of the Year'
	),
both_leagues AS 
	(SELECT 
		playerid
	FROM dbl_winners
	GROUP BY playerid
	HAVING COUNT (DISTINCT lgid) = 2
	)
SELECT
	dw.full_name
	,dw.yearid
	,dw.lgid
	,t.name AS team_name
FROM dbl_winners AS dw
	JOIN both_leagues AS b USING (playerid)
	JOIN teams AS t 
		ON  dw.teamid = t.teamid
	    AND dw.yearid = t.yearid
		AND dw.lgid = t.lgid
ORDER BY dw.full_name, dw.yearid;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at 
	--least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH hr_by_year AS
	(SELECT SUM(hr) AS yearly_hr
		,playerid
		,yearid
	FROM batting
	GROUP BY playerid, yearid
	)
	,yearly_max AS
	(SELECT
		playerid
		,MAX(yearly_hr) AS max_hr
	FROM hr_by_year	
	GROUP BY playerid
	)
	,hr_2016 AS
	(SELECT playerid
		  ,SUM(hr) AS hr_2016
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
	HAVING SUM(hr) > 0
	)
	,career_length AS
	(SELECT
		playerid
		,COUNT(DISTINCT yearid) AS years_played
	FROM batting
	GROUP BY playerid
	)
SELECT
	p.namefirst || ' ' || p.namelast AS full_name
	,hr16.hr_2016
FROM hr_2016 AS hr16
	JOIN yearly_max AS ym USING (playerid)
	JOIN career_length AS cl USING (playerid)
	JOIN people AS p USING (playerid)
WHERE hr16.hr_2016 = ym.max_hr
	AND cl.years_played >= 10
ORDER BY hr16.hr_2016 DESC;
-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, 
	--keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

WITH member_salary AS(
	SELECT 
		salary::numeric::money AS member_salary
		,w
		,yearid
		,name
	FROM teams
		INNER JOIN salaries USING(yearid,lgid,teamid)
	WHERE yearid >=2000
	)
	, team_salary AS(
	SELECT 
		SUM(salary)::numeric AS team_salary
		,yearid
	FROM teams
		INNER JOIN salaries USING(yearid,lgid,teamid)
	WHERE yearid >=2000
	GROUP BY yearid
	)
	,team_wins AS(
	SELECT 
		SUM(w)::numeric AS team_wins
		,yearid
	FROM teams
		INNER JOIN salaries USING(yearid,lgid,teamid)
	WHERE yearid >=2000
	GROUP BY yearid
	)
SELECT 
	CORR(team_wins,team_salary)
	,yearid
FROM teams
	INNER JOIN team_wins USING (yearid)
	INNER JOIN team_salary USING(yearid)
GROUP BY yearid
	
	



WITH member_salary AS(
	SELECT 
		name
		,yearid
		,salary
	FROM teams
		INNER JOIN salaries USING(yearid,lgid,teamid)
	WHERE yearid >=2000
	)
	,total_salary AS(
	SELECT 
		SUM(salary)::numeric::money
		,yearid
	FROM member_salary
	GROUP BY yearid
	ORDER BY yearid ASC
	)
SELECT 



SELECT *
FROM teams

SELECT *
FROM salaries

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?