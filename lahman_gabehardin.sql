-- 1. What range of years for baseball games played does the provided database cover?

SELECT *
FROM appearances

SELECT MIN(yearID),MAX(yearID)
FROM appearances; 
--1871-2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT *
FROM appearances;

SELECT *
FROM teams

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



SELECT DISTINCT name
FROM appearances
	INNER JOIN teams USING (teamid)



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

-- seems like this is
-- WITH good_stealers AS(
-- 	SELECT yearid, playerid, namefirst||' '||namelast AS full_name,sb,cs
-- 	FROM batting
-- 		INNER JOIN people USING(playerid)
-- 	WHERE sb <> 0
-- 	)
SELECT namefirst||' '||namelast AS full_name, SUM(sb)+SUM(cs)AS steal_attempts, ROUND(SUM(sb::numeric)/(SUM(sb::numeric)+SUM(cs::numeric))*100,0) AS steal_percentage
FROM batting
	INNER JOIN people USING (playerid)
WHERE yearid = '2016' 
GROUP BY playerid,full_name
	HAVING SUM(sb)+SUM(cs) >=20
ORDER BY steal_percentage DESC
LIMIT 1; 
-- Chris Owings

SELECT *
FROM batting
WHERE yearid= '2016'

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for
	--a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine 
	-- why this is the case. Then redo your query, excluding the problem year. 

SELECT COUNT (DISTINCT name)AS unique_teams, count(name), yearid
FROM teams
GROUP BY yearid

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

SELECT * 
FROM teams



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
	--WHERE WSWIN = 'Y' 
	)
SELECT SUM(CASE WHEN wswin = 'Y' THEN 1 END)/COUNT(yearid)::numeric * 100 AS dominant_champ_percentage
FROM ws_winners
-- 	LEFT JOIN ws_winners USING(yearid)
-- WHERE yearid <> 1981 AND yearid <>1994

-- still needs to exclude 1981 and get a percentage for wswin that have the max wins per season
	
-- i can't think of a good way to merge these queries returning the max of wins by a team per year and the wswin per year. (without a million cte's or subqueries)	
WITH ws_winners AS(
	SELECT yearid,name
	FROM teams
	WHERE WSWIN = 'Y' AND yearid >=1970

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

SELECT *
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year' 

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at 
	--least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, 
	--keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?