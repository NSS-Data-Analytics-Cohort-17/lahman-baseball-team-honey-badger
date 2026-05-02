--REMINDER...DOUBLE CHECK TO SEE WHAT IS IN A COLUMN
SELECT * FROM  LIMIT 5;

--What range of years for baseball games played does the provided database cover?

SELECT MIN(yearID) AS earliest, MAX(yearID) AS latest FROM Teams;


--2. Find the name and height of the shortest player in the database. (Eddie, 43in)
SELECT MIN (height)
FROM people;

SELECT namefirst, namelast, playerID, height
FROM people
WHERE height = 43;

--How many games did he play in? (1)

SELECT people.namefirst, people.namelast, people.height, appearances.g_all
FROM people
JOIN appearances ON people.playerid = appearances.playerid
WHERE people.height = 43;

-- What is the name of the team for which he played? (St. Louis Browns)
SELECT people.namefirst, people.namelast,
       people.height, appearances.g_all,
       teams.name
FROM people
JOIN appearances ON people.playerid = appearances.playerid
JOIN teams ON appearances.teamid = teams.teamid
          AND appearances.yearid = teams.yearid
WHERE people.height = 43;

--3.Find all players in the database who played at Vanderbilt University. 
SELECT *
FROM schools
JOIN collegeplaying ON schools.schoolid = collegeplaying.schoolid
WHERE schools.schoolname = 'Vanderbilt University';

--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
SELECT people.namefirst, people.namelast
FROM schools
JOIN collegeplaying ON schools.schoolid = collegeplaying.schoolid
JOIN people ON collegeplaying.playerid = people.playerid
WHERE schools.schoolname = 'Vanderbilt University';

--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT people.namefirst, people.namelast,
       SUM(salaries.salary) AS total_salary
FROM schools
JOIN collegeplaying ON schools.schoolid = collegeplaying.schoolid
JOIN people ON collegeplaying.playerid = people.playerid
JOIN salaries ON people.playerid = salaries.playerid
WHERE schools.schoolname = 'Vanderbilt University'
GROUP BY people.namefirst, people.namelast
ORDER BY total_salary DESC;

--4. . Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". 
Determine the number of putouts made by each of these three groups in 2016.

SELECT 
CASE 
 WHEN fielding = 'OF' THEN "Outfield"
 WHEN position IN          

 --5.Find the average number of strikeouts per game by decade since 1920.
 Round the numbers you report to 2 decimal places.
 Do the same for home runs per game. 
 Do you see any trends?

 SELECT 
  (yearid / 10) * 10 AS decade,
  ROUND(SUM(so)::numeric / SUM(g), 2) AS avg_so_per_game,
  ROUND(SUM(hr)::numeric / SUM(g), 2) AS avg_hr_per_game
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

--.6 Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.)
Consider only players who attempted _at least_ 20 stolen bases.


SELECT people.namefirst, people.namelast,
ROUND(sb::numeric / (sb+cs) * 100,2) AS success_rate
FROM batting
JOIN people ON batting.playerid = people.playerid
WHERE batting.yearid = 2016
AND (sb+cs>= 20)
ORDER BY success_rate DESC
LIMIT 1;


--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case.
Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
gft mbhyWhat percentage of the time?
--Most wins without winning World Series
SELECT MAX(w) AS max_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'N';

--Fewest wins to win World Series
SELECT MIN(w) AS min_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y';

--Excluding 1981 strike year
SELECT MIN(w) AS min_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y'
AND yearid <> 1981;

--How often did most wins = WS champion
WITH max_wins AS (
    SELECT yearid, MAX(w) AS max_w
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016
    AND yearid <> 1981
    GROUP BY yearid
)
SELECT COUNT(*) AS times_most_wins_won_ws,
       ROUND(COUNT(*)::numeric / 46 * 100, 2) AS percentage
FROM max_wins
JOIN teams ON max_wins.yearid = teams.yearid
          AND max_wins.max_w = teams.w
WHERE teams.wswin = 'Y';



--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
(where average attendance is defined as total attendance divided by number of games). 
Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 
Repeat for the lowest 5 average attendance.

SELECT parks.park_name, teams.name,
    ROUND(SUM(homegames.attendance)::numeric/SUM(homegames.games), 2) AS avg_attendance   
FROM homegames
JOIN parks ON homegames.park = parks.park
JOIN teams ON homegames.team = teams.teamid
          AND homegames.year = teams.yearid
WHERE homegames.year = 2016
GROUP BY parks.park_name, teams.name
HAVING SUM(games) >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

--the lowest 5 average attendance
SELECT parks.park_name, teams.name,
    ROUND(SUM(homegames.attendance)::numeric/SUM(homegames.games), 2) AS avg_attendance   
FROM homegames
JOIN parks ON homegames.park = parks.park
JOIN teams ON homegames.team = teams.teamid
          AND homegames.year = teams.yearid
WHERE homegames.year = 2016
GROUP BY parks.park_name, teams.name
HAVING SUM(games) >= 10
ORDER BY avg_attendance ASC
LIMIT 5;

--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
Give their full name and the teams that they were managing when they won the award.

WITH both_leagues AS (
    SELECT playerid FROM awardsmanagers 
    WHERE awardid = 'TSN Manager of the Year'
    AND lgid = 'AL'
    
    INTERSECT
    
    SELECT playerid FROM awardsmanagers 
    WHERE awardid = 'TSN Manager of the Year'
    AND lgid = 'NL'
)
SELECT people.namefirst, people.namelast,
       awardsmanagers.lgid, awardsmanagers.yearid,
       teams.name
FROM both_leagues
JOIN people ON both_leagues.playerid = people.playerid
JOIN awardsmanagers ON both_leagues.playerid = awardsmanagers.playerid
JOIN managers ON awardsmanagers.playerid = managers.playerid
             AND awardsmanagers.yearid = managers.yearid
JOIN teams ON managers.teamid = teams.teamid
          AND managers.yearid = teams.yearid
WHERE awardsmanagers.awardid = 'TSN Manager of the Year'
ORDER BY people.namelast, awardsmanagers.yearid;

--10. Find all players who hit their career highest number of home runs in 2016. 
Consider only players who have played in the league for at least 10 years, 
and who hit at least one home run in 2016. 
Report the players' first and last names and the number of home runs they hit in 2016.

