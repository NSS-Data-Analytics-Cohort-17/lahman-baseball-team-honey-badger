-- 1. What range of years for baseball games played does the provided database cover? 

SELECT 
	MIN(yearid), 
	MAX(yearid)
FROM teams;

-- answer: from 1871 to 2016.

-------------------------------------------------------------------------------------------------------------------------

-- 2. Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played?

WITH shortest_player AS (
    SELECT 
        namefirst AS first_name, 
        namelast AS last_name, 
        height AS height_inches,
		playerid
    FROM people
    WHERE height = (SELECT MIN(height) FROM people)
)
SELECT 
first_name, 
   last_name, 
   height_inches, 
   teams.teamid, 
   SUM(batting.g) AS games_played
FROM shortest_player
INNER JOIN batting USING(playerid)
INNER JOIN teams USING(teamid)
GROUP BY first_name, 
   last_name, 
   height_inches, 
   teams.teamid;
				
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

-------------------------------------------------------------------

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
			WHEN pos ='SS'
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
						SUM(so) / (SUM(g) / 1.0) AS avg_so,
        				SUM(hr) / (SUM(g) / 1.0) AS avg_hr,
						(yearID / 10) * 10 AS decade
					FROM teams
					WHERE (yearid/10)*10 >= 1920
					GROUP BY decade)
SELECT decade,
	ROUND(avg_so, 2) AS avg_strikeouts,
	ROUND(avg_hr, 2) AS avg_homeruns
FROM avg_so_hr
ORDER BY decade ASC;

--------------------------------------------
-- for refrences - Isaac's work, *not mine*
-- basically, generate series creates a new column and therefore doesn't need to be from a table

WITH decades AS(SELECT 
				generate_series(1920, 2020, 10) AS decade_start
) 
SELECT 
	decade_start || 's' AS decade,
	SUM(so) AS total_strikeouts,
	SUM(hr) AS total_homeruns,
	SUM(g) AS total_games,
	SUM(so) / SUM(g) AS avg_strkeouts, 
	SUM(hr) / SUM(g) AS avg_homeruns
FROM 
	decades
	INNER JOIN teams 
		ON teams.yearid 
		BETWEEN decades.decade_start 
		AND decades.decade_start + 9
GROUP BY decade
ORDER BY decade DESC
   
-------------------------------------------------------------------------------------------------------------------------

-- 6. Find the player who had the most success stealing bases in 2016, 
-- where __success__ is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases.

SELECT 
	people.namefirst AS first_name,
	people.namelast AS last_name, 
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

-- seattle mariners had 116 wins, but did not win WS in 2001

SELECT name AS team_name, yearID, W as wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'Y'
ORDER BY W ASC
LIMIT 1;

-- la dodgers had 63 wins, but did win the WS in 1981

WITH ws_winners AS (SELECT 
					name AS team_name, 
					yearID, 
					W as wins
				FROM teams
				WHERE yearID BETWEEN 1970 AND 2016
				AND WSWin = 'Y'
				),
yearly_max_wins AS (SELECT
					yearID,
					MAX(w) AS max_wins
				FROM teams
				WHERE yearID BETWEEN 1970 AND 2016
				GROUP BY yearid
				),
ws_vs_max AS (SELECT 
				ws_winners.team_name,
				ws_winners.yearID,
				ws_winners.wins,
				yearly_max_wins.max_wins,
				CASE WHEN ws_winners.wins < yearly_max_wins.max_wins 
					THEN 1 ELSE 0 END AS did_not_have_max_wins
			FROM ws_winners
			JOIN yearly_max_wins USING(yearid))
SELECT COUNT(*) AS total_ws_wins, SUM(did_not_have_max_wins) AS count_ws_winner_did_not_lead_wins,
ROUND(100.0* SUM(did_not_have_max_wins)/ COUNT(*), 2) AS percent_ws_winner_did_not_lead_wins
	FROM ws_vs_max;
	
-- to calculate the number of times a world series winner did get the WS and highest W in league, 
-- we can find the inverse of 73.91%, or 26.09%



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

-- "Jim Leyland" and "Davey Johnson"
-------------------------------------------------------------------------------------------------------------------------

-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, 
-- and who hit at least one home run in 2016. 
-- Report the players first and last names and the number of home runs they hit in 2016.

WITH decade_career AS (SELECT
   							playerid
						FROM people
						WHERE debut IS NOT NULL
  							AND finalgame IS NOT NULL
							AND LEFT(finalgame, 4)::INT - LEFT(debut, 4)::INT >= 10
						),
career_hr_max AS (SELECT
						playerid,
						MAX(hr) AS max_hr
					FROM batting
					GROUP BY playerid
					),
hr_2016 AS (SELECT
				playerid,
				SUM(HR) AS hr_in_2016
			FROM batting
			WHERE yearid = 2016
			GROUP BY playerid
			)
SELECT 
	people.namefirst || ' ' || people.namelast AS full_name,
	hr_2016.hr_in_2016
FROM decade_career
INNER JOIN hr_2016 USING(playerid)
INNER JOIN career_hr_max USING(playerid)
INNER JOIN people USING(playerid)
WHERE hr_2016.hr_in_2016 >= 1
	AND hr_2016.hr_in_2016 = career_hr_max.max_hr
ORDER BY hr_in_2016 DESC;

-- Edwin Encarnacion had 42 hr in 2016. This player set a personal record for annual hr's with 2016,
-- and preformed better than all other players who share HR PR's in 2016.

-------------------------------------------------------------------------------------------------------------------------

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? 
-- Use data from 2000 and later to answer this question. As you do this analysis, 
-- keep in mind that salaries across the whole league tend to increase together, 
-- so you may want to look on a year-by-year basis.

WITH sum_team_salary_per_year AS (SELECT 
							SUM(salary) AS sum_salary, 
							teamid, yearid
						FROM salaries
							WHERE yearid >= 2000
						GROUP BY teamid, yearid
						),
wins_per_year AS (SELECT teamid,
							SUM(w) AS wins,
							yearid
							FROM teams
							WHERE  yearid >= 2000
								AND (lgID = 'NL' OR lgID = 'AL')
							GROUP BY teamid, yearid)
SELECT 
    yearid, 
	CORR(sum_team_salary_per_year.sum_salary, wins_per_year.wins)
FROM  sum_team_salary_per_year
INNER JOIN wins_per_year USING(teamid, yearid)
GROUP BY yearid

-- some years, spending more = winning more

WITH sum_team_salary_per_year AS (SELECT 
							SUM(salary) AS sum_salary, 
							teamid, yearid
						FROM salaries
							WHERE yearid >= 2000
						GROUP BY teamid, yearid
						),
wins_per_year AS (SELECT teamid,
							SUM(w) AS wins,
							yearid
							FROM teams
							WHERE  yearid >= 2000
								AND (lgID = 'NL' OR lgID = 'AL')
							GROUP BY teamid, yearid)
SELECT 
    teamid, 
	CORR(sum_team_salary_per_year.sum_salary, wins_per_year.wins)
FROM  sum_team_salary_per_year
INNER JOIN wins_per_year USING(teamid, yearid)
GROUP BY teamid
ORDER BY corr DESC

-- my inital thought towards using a correation function (r) to find a linear trend MAY be
-- misleading when broken down by team. I think a high corrleation value only maps the best value or budgeting.
-- so, a team with low spending could have done averagly well in the regular season.
-- However, in the world of baseball, teams want to win and secure a spot in the playoffs.
-- So, teams that spend alot and won alot may have a similar r value to a team that lost alot, 
-- but also didn't spend money

-- Alternatively, I think measuring the success of spending more = winning more can be better
-- shown by grouping by years, since it averages all of the teams across the board with their winnings.

-------------------------------------------------------------------------------------------------------------------------

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
-- --       <li>Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- </li>
-- --     </ol>

WITH sum_attendance AS (SELECT 
							SUM(homegames.attendance) AS total_lifetime_attendance, 
							teams.name
						FROM homegames
						INNER JOIN teams ON homegames.year = teams.yearid
						GROUP BY  teams.name
						ORDER BY total_lifetime_attendance DESC
						),
sum_wins AS (SELECT 
				SUM(w) AS total_lifetime_wins, 
				teams.name
				FROM teams
				GROUP BY  teams.name
				ORDER BY total_lifetime_wins DESC)
SELECT corr(sum_wins.total_lifetime_wins, sum_attendance.total_lifetime_attendance)
FROM sum_wins
INNER JOIN sum_attendance USING(name)
LIMIT 40;

-- with a R of .89, the data strongly suggests that high attendance is associated wtih more wins



-------------------------------------------------------------------------------------------------------------------------

-- 13. It is thought that since left-handed pitchers are more rare, 
-- causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. 
-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?


