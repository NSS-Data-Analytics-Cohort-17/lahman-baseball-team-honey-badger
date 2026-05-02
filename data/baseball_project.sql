-- 1. What range of years for baseball games played does the provided database cover? 

SELECT MIN(yearid), MAX(yearid)
FROM teams;

-- answer: from 1871 to 2016.

-------------------------------------------------------------------------------------------------------------------------

-- 2. Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played?

SELECT 
	namefirst AS first_name, 
	namelast AS last_name, 
	height AS height_inches
FROM people
WHERE height = (SELECT MIN(height)
				FROM people
				);
				
-- answer: the shortest person was Eddie Gaedel at 43".

-------------------------------------------------------------------------------------------------------------------------
-- 3. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?

WITH salary_sum AS (SELECT SUM(salary::numeric::money) AS salary, playerid
					FROM salaries
					GROUP BY playerid)
SELECT 
	people.namefirst AS first_name,
	people.namelast AS last_name,
	salary AS total_salary_mlb
FROM collegeplaying
INNER JOIN 
	salary_sum USING(playerID)
INNER JOIN 
	people USING(playerid)
WHERE schoolid = 'vandy'
GROUP BY 
	namefirst, 
	namelast,
	salary,
	playerid
ORDER BY salary DESC;

-- answer: David Price earned the most in the majors: $81,851,296.00"

-------------------------------------------------------------------------------------------------------------------------
-- 4. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.

WITH position_catagory AS (
		SELECT pos AS position,
		playerid,
		CASE
			WHEN pos = 'OF' 
				THEN 'Outfield'
			WHEN pos =	
					'SS'
					OR pos = '1B'
					OR pos = '2B'
					OR pos = '3B'
				THEN 'Infield'
			WHEN pos = 'P'
					OR pos = 'C'
				THEN 'Battery'
			ELSE 'other'
			END AS fielding_catagory
		FROM fielding
		GROUP BY pos, fielding.playerid)
SELECT 
	SUM(po) AS put_outs, 
	fielding_catagory
FROM fielding
INNER JOIN position_catagory ON position_catagory.playerid = fielding.playerid
GROUP BY position_catagory.fielding_catagory
ORDER BY put_outs DESC;

-------------------------------------------------------------------------------------------------------------------------
   
-- 5. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. Do you see any trends?

WITH avg_so_hr AS 
					(SELECT 
						SUM(so) / (SUM(g) / 2.0) AS avg_so,
        				SUM(hr) / (SUM(g) / 2.0) AS avg_hr,
						(yearID / 10) * 10 AS decade
					FROM teams
					WHERE (yearid/10)*10 >= 1920
					GROUP BY decade)
SELECT decade,
	ROUND(avg_so, 2) AS avg_strikeouts,
	ROUND(avg_hr, 2) AS avg_homeruns
FROM avg_so_hr
ORDER BY decade DESC;
   
-------------------------------------------------------------------------------------------------------------------------

-- 6. Find the player who had the most success stealing bases in 2016, 
-- where __success__ is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases.

SELECT people.namefirst AS first_name,
	people.namelast AS last_name, 
	sb - cs AS successful_steals, 
	ROUND((sb * 100.0) / NULLIF(sb+cs, 0),2) AS percent_sb_success
FROM batting
JOIN people USING(playerid)
WHERE yearid = 2016
	AND (sb * 100.0) / NULLIF(sb+cs, 0) IS NOT NULL
	AND sb + cs >= 20
GROUP BY playerid, sb, cs, yearid, first_name, last_name
ORDER BY percent_sb_success DESC;

-- Chris Owings had the highest stole base success rate (success/success+fails) 91.3%
	
-------------------------------------------------------------------------------------------------------------------------

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
-- Doing this will probably result in an unusually small number of wins for a world series champion 
-- – determine why this is the case. Then redo your query, excluding the problem year. 
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time?

SELECT name AS team_name, yearID AS tear, W as wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
  AND WSWin = 'N'
ORDER BY W DESC
LIMIT 1;

SELECT name AS team_name, yearID, W as wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'Y'
ORDER BY W ASC
LIMIT 1;

SELECT name AS team_name, yearID, W as wins
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'Y' 
	AND (name, W) IN (SELECT name, MAX(W)
							FROM teams
							WHERE yearID BETWEEN 1970 AND 2016
							GROUP BY name)

							--
-------------------------------------------------------------------------------------------------------------------------

-- 8. Using the attendance figures from the homegames table, 
-- find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. 
-- Repeat for the lowest 5 average attendance.

SELECT 
	park_name,
	franchname AS team,
	attendance/games AS avg_attendance 
FROM homegames
JOIN teamsfranchises ON homegames.team = teamsfranchises.franchid
JOIN parks ON homegames.park = parks.park
WHERE 
	year = 2016
	AND games >= 10
ORDER BY attendance DESC
LIMIT 10;

-- top blue jays with 41,877 avg attendance.
-- Very HM to the Red Sox (go sox!) with 36,486 avg. attendance

-------------------------------------------------------------------------------------------------------------------------
SELECT 
	park_name,
	franchname AS team,
	attendance/games AS avg_attendance 
FROM homegames
JOIN teamsfranchises ON homegames.team = teamsfranchises.franchid
JOIN parks ON homegames.park = parks.park
WHERE 
	year = 2016
	AND games >= 10
ORDER BY attendance ASC
LIMIT 10;

-- oakland a's wwih 18,784 avg attendance per game

-------------------------------------------------------------------------------------------------------------------------

-- 9. Which managers have won the TSN Manager of the Year award in both 
-- the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

WITH both_lg_winners AS(SELECT COUNT (DISTINCT lgid),
							playerid
						FROM awardsmanagers
						WHERE awardid = 'TSN Manager of the Year'
							AND lgid IN('NL', 'AL')
						GROUP BY playerid
						HAVING COUNT (DISTINCT lgid) = 2)
SELECT 
	namefirst || ' ' || namelast AS full_name, 
	teams.name
FROM both_lg_winners
INNER JOIN people USING(playerid)
INNER JOIN awardsmanagers USING(playerid)
INNER JOIN managers USING(playerid, yearid, lgid)
INNER JOIN teams USING(teamid, yearid, lgid)
WHERE awardid = 'TSN Manager of the Year';
-------------------------------------------------------------------------------------------------------------------------

-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. 
-- Report the players first and last names and the number of home runs they hit in 2016.
WITH decade_career AS (SELECT
   							playerid,
    						debut,
   							finalgame,
    						LEFT(finalgame, 4)::INT - LEFT(debut, 4)::INT AS career_years
						FROM people
						WHERE debut IS NOT NULL
  							AND finalgame IS NOT NULL)
SELECT 
	namefirst || ' ' || namelast AS full_name,
FROM decade_career
INNER JOIN people USING(playerid)

SELECT *
FROM  batting
WHERE yearid = 2016
	AND (hr) IN
		(SELECT MAX(HR)
		FROM batting 
			WHERE hr > 0
		GROUP BY playerid)

-------------------------------------------------------------------------------------------------------------------------

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? 
-- Use data from 2000 and later to answer this question. As you do this analysis, 
-- keep in mind that salaries across the whole league tend to increase together, 
-- so you may want to look on a year-by-year basis.

-------------------------------------------------------------------------------------------------------------------------

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
-- --       <li>Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- </li>
-- --     </ol>

-------------------------------------------------------------------------------------------------------------------------

-- 13. It is thought that since left-handed pitchers are more rare, 
-- causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. 
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?


