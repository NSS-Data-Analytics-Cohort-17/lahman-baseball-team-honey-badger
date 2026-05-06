--	1.	What range of years for baseball games played does the provided database cover? 

SELECT MIN(DISTINCT yearid), MAX(DISTINCT yearid)
FROM teams;

-- 2.	Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

WITH shortest_player AS (
			SELECT CONCAT(namefirst,' ',namelast) AS name
			, height, playerid
			FROM people
			WHERE height =(SELECT MIN(height) FROM people WHERE height >0)
			)
SELECT name, height, ap.g_all AS total_games, ap.teamid AS team_name
FROM shortest_player
INNER JOIN appearances AS ap USING(playerid)
;

--	3.	Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total  
--		salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player 
--		earned the most money in the majors?

WITH vandy_players AS(
			SELECT namefirst
			, namelast
			, playerid
			FROM schools AS sc
			INNER JOIN collegeplaying AS cp USING(schoolid)
			INNER JOIN people AS pe USING(playerid)
			WHERE schoolid = 'vandy'
)
SELECT CONCAT(vp.namefirst,' ',namelast) AS name, SUM(sal.salary) AS total_salary
FROM vandy_players AS vp
INNER JOIN salaries AS sal USING(playerid)
GROUP BY vp.playerid, vp.namefirst, vp.namelast
ORDER BY total_salary DESC
;

--	4.	Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
--		those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number 
--		of putouts made by each of these three groups in 2016.

WITH group_players AS(
			SELECT pos
			, po
			FROM fielding
			WHERE yearid = '2016'
)
SELECT CASE
			WHEN pos = 'OF' THEN 'outfield'
			WHEN pos IN ( 'SS','1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
			END AS position_group
			,SUM(po) AS total_putouts
FROM group_players
GROUP BY position_group
ORDER BY total_putouts DESC
;

-- 5.	Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--		Do the same for home runs per game. Do you see any trends?

WITH total_games AS (
			SELECT SUM(te.hr) AS number_homeruns
			, SUM(te.so) AS number_so
			, (SELECT SUM(homegames.games) FROM homegames WHERE year >=1920 ) AS total_games
			FROM teams AS te
			WHERE te.yearid >=1920
)
SELECT	ROUND((number_so::numeric/total_games),2) AS avg_strike_outs
		, ROUND((number_homeruns::numeric/total_games),2) AS avg_homeruns
FROM total_games
;

--	6.	Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts
--		which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at 
--		least_ 20 stolen bases

WITH stealing_bases AS(
			SELECT CONCAT(pe.namefirst, ' ', pe.namelast) AS name
			, SUM(ba.sb) AS stolen_bases
			, SUM(ba.cs) AS caougt_stealing
			FROM batting AS ba
			INNER JOIN people AS pe USING(playerid)
			WHERE ba.yearid = 2016
			GROUP BY pe.playerid, pe.namefirst, pe.namelast
			HAVING SUM(ba.sb) > 20
)
SELECT name, stolen_bases, ROUND(((stolen_bases::numeric/(stolen_bases+caougt_stealing))*100),2) AS percentage_stole
FROM stealing_bases
ORDER BY stolen_bases DESC
LIMIT 1
;

--	7.	From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for 
--		a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine 
--		why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins 
--		also won the world series? What percentage of the time?

		-- largest number of wins for a team that did not win the world series
		
WITH world_winners AS(
			SELECT yearid, name AS team_name, lgid AS league, wswin AS world_series, w AS total_wins
			FROM teams
			WHERE yearid BETWEEN 1970 AND 2016
)
SELECT MAX(total_wins)AS total_wins, MIN(total_wins) AS min_wins, yearid
FROM world_winners
WHERE world_series != 'Y'
GROUP BY yearid
ORDER BY min_wins
LIMIT 1
;      	--Result: total-wins: 66; min_wins 37 in 1981

		-- smallest number of wins for a team that did win the world series
		
WITH world_winners AS(
			SELECT yearid, name AS team_name, lgid AS league, wswin AS world_series, w AS total_wins
			FROM teams
			WHERE yearid BETWEEN 1970 AND 2016
						AND wswin = 'Y'
)
SELECT MAX(total_wins)AS total_wins, MIN(total_wins) AS min_wins, yearid
FROM world_winners
WHERE world_series = 'Y'
GROUP BY yearid
ORDER BY min_wins
LIMIT 1
;		-- Result: total_wins: 63; min_wins: 63 for a winner series

		-- 1981 was an anomaly year due the teams' strike

-- 		Part query redo, excluding problem year

WITH max_wins_per_year AS (
			SELECT yearid
			, MAX(w) AS max_wins
			FROM teams
			WHERE yearid between 1970 AND 2016 AND yearid <> 1981
			GROUP BY yearid
),
world_series_winners AS (
			SELECT yearid, w AS ws_winner
			FROM teams
			WHERE yearid between 1970 AND 2016 AND yearid <> 1981 AND wswin = 'Y'
)
SELECT	COUNT(mwpy.yearid) AS total_years_compared
		, SUM(CASE WHEN mwpy.max_wins = wsw.ws_winner THEN 1 ELSE 0 END) AS times_most_wins_win_ws
		, ROUND((SUM(CASE WHEN mwpy.max_wins = wsw.ws_winner THEN 1 ELSE 0 END)::numeric/COUNT(mwpy.yearid)) *100, 2) AS percentage_of_time
FROM max_wins_per_year AS mwpy
INNER JOIN world_series_winners AS wsw ON mwpy.yearid = wsw.yearid
;

--	8.	Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
--		(where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. 
--		Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

--		Top 5 average attendance

WITH park_games AS (
		SELECT park, team, attendance, games
		FROM homegames as hg
		WHERE games >= 10 AND year = 2016
)
SELECT park AS park_name, team, ROUND(SUM(park_games.attendance)::numeric/(SELECT SUM(park_games.games) FROM park_games),2) AS avg_attendance
FROM park_games
GROUP BY team, park_name
ORDER BY avg_attendance DESC
LIMIT 5
;

--		Lowest 5 average attendance

WITH park_games AS (
		SELECT park, team, attendance, games
		FROM homegames as hg
		WHERE games >= 10 AND year = 2016
)
SELECT park AS park_name, team, ROUND(SUM(park_games.attendance)::numeric/(SELECT SUM(park_games.games) FROM park_games),2) AS avg_attendance
FROM park_games
GROUP BY team, park_name
ORDER BY avg_attendance ASC
LIMIT 5
;


--	9.	Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the 
--		teams that they were managing when they won the award.

WITH TSN_nl AS  (
		SELECT am.playerid AS playerid, am.yearid AS yearid
		FROM awardsmanagers AS am
		WHERE am.awardid = 'TSN Manager of the Year' AND  am.lgid = 'NL'
),
TSN_al AS (
		SELECT am.playerid AS playerid, am.yearid AS yearid
		FROM awardsmanagers AS am
		WHERE am.awardid = 'TSN Manager of the Year' AND  am.lgid = 'AL'
),
join_tables AS (
		SELECT	DISTINCT TSN_nl.playerid AS playerid
		, TSN_nl.yearid AS yearid
		FROM TSN_nl
		INNER JOIN TSN_al ON TSN_nl.playerid = TSN_al.playerid 
)
SELECT	CONCAT(pe.namefirst,' ',pe.namelast) AS name
		, ma.teamid AS team
		, am.yearid AS year
FROM join_tables AS jt
INNER JOIN people AS pe ON pe.playerid = jt.playerid
INNER JOIN managers AS ma ON ma.playerid = jt.playerid AND ma.yearid =jt.yearid
INNER JOIN awardsmanagers AS am ON jt.playerid = am.playerid AND am.yearid = ma.yearid
WHERE am.awardid = 'TSN Manager of the Year'
ORDER BY name, year;


--	10.	Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, 
--		and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH career_highest AS (
		SELECT pe.playerid,pe.namefirst
			, pe.namelast
			, SUM(ba.hr) AS total_hr
			,pe.debut,pe.finalgame
		FROM people AS pe
		INNER JOIN batting AS ba USING(playerid)
		WHERE ba.yearid = 2016 
			AND (pe.finalgame::DATE - pe.debut::DATE) > 3650 
		GROUP BY	pe.playerid
					,pe.namefirst
					,pe.namelast
					,pe.debut
					,pe.finalgame
)
SELECT CONCAT(ch.namefirst,' ',ch.namelast) AS name
			, ch.total_hr 
FROM career_highest AS ch
WHERE ch.total_hr > 1
ORDER BY ch.total_hr DESC
;


--   **Open-ended questions**

--  11.	Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, 
--		keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

WITH team_salaries AS (
		SELECT 	teamid
				,yearid
				,SUM(salary) AS total_salaries
		FROM	salaries
		WHERE yearid >= 2000
		GROUP BY teamid, yearid
),
team_wins AS (	SELECT 	teamid
				,yearid
				,w AS wins
		FROM	teams
		WHERE yearid >= 2000
)
SELECT tw.yearid AS year, CORR(tw.wins, ts.total_salaries)
FROM team_wins AS tw
INNER JOIN team_salaries AS ts ON tw.teamid=ts.teamid AND tw.yearid = ts.yearid
GROUP BY tw.yearid
ORDER BY tw.yearid DESC
;
		-- There is no correlation between the salary and the number of wins in the league.
					

--	12.	In this question, you will explore the connection between number of wins and attendance.
--		a.	Does there appear to be any correlation between attendance at home games and number of wins?

WITH homegames_attendance AS (
		SELECT 	team
				,year
				,SUM(attendance) AS total_attendance
		FROM	homegames
		WHERE year >= 2000
		GROUP BY team, year
),
team_wins AS (	SELECT 	teamid
				,yearid
				,w AS wins
		FROM	teams
		WHERE yearid >= 2000
)
SELECT tw.yearid AS year, CORR(tw.wins, hga.total_attendance)
FROM team_wins AS tw
INNER JOIN homegames_attendance AS hga ON tw.teamid = hga.team AND tw.yearid = hga.year
GROUP BY tw.yearid
ORDER BY tw.yearid ASC
;

		-- There is no correlation between the salary and the number of wins at home.


--		b.	Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs 
--			means either being a division winner or a wild card winner.


SELECT 
    t1.yearID,
    t1.name AS team_name,
    t1.attendance AS current_year_attendance,
    t2.attendance AS next_year_attendance,
    (t2.attendance - t1.attendance) AS attendance_difference,
    CASE 
        WHEN (t2.attendance - t1.attendance) > 0 THEN 'Increase'
        ELSE 'Reduction / No change'
    END AS trend
FROM teams AS t1
INNER JOIN teams AS t2 
    ON t1.teamID = t2.teamID 
    AND t2.yearID = t1.yearID + 1
WHERE t1.yearID >= 1995 
  AND t1.WSWin = 'Y'
ORDER BY t1.yearID ASC;

		-- Mostly was an increased after the teams won the world series


-- FOR playoff winners:

SELECT 
    t1.yearID,
    t1.name AS team_name,
    t1.attendance AS current_year_attendance,
    t2.attendance AS next_year_attendance,
    (t2.attendance - t1.attendance) AS attendance_difference,
    CASE 
        WHEN (t2.attendance - t1.attendance) > 0 THEN 'Increase'
        ELSE 'Reduction / No change'
    END AS trend
FROM teams AS t1
INNER JOIN teams AS t2 
    ON t1.teamID = t2.teamID 
    AND t2.yearID = t1.yearID + 1
WHERE t1.yearID >= 1995 
  AND t1.divwin = 'Y'
ORDER BY t1.yearID ASC;


		-- Mostly was an increased after the teams won the playoffs

		
-- Wildcard winners

SELECT 
    t1.yearID,
    t1.name AS team_name,
    t1.attendance AS current_year_attendance,
    t2.attendance AS next_year_attendance,
    (t2.attendance - t1.attendance) AS attendance_difference,
    CASE 
        WHEN (t2.attendance - t1.attendance) > 0 THEN 'Increase'
        ELSE 'Reduction / No change'
    END AS trend
FROM teams AS t1
INNER JOIN teams AS t2 
    ON t1.teamID = t2.teamID 
    AND t2.yearID = t1.yearID + 1
WHERE t1.yearID >= 1995 
  AND t1.wcwin = 'Y'
ORDER BY t1.yearID ASC;

		-- Mostly was an increased after the teams won the wildcard


--	13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
--		Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are 
--		compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

SELECT 
    pe.throws,
    COUNT(DISTINCT pe.playerid) AS total_pitchers,
    ROUND(
        (COUNT(DISTINCT pe.playerid)::numeric / 
         SUM(COUNT(DISTINCT pe.playerid)) OVER()) * 100, 2
    ) AS percentage
FROM people AS pe
INNER JOIN pitching AS pi USING(playerid)
WHERE pi.yearid >= 2000
  AND pe.throws IN ('L', 'R')
GROUP BY pe.throws;

		-- Left handed pichers are rare in Baseball, there are only the 28% of the total.

SELECT 
    pe.throws,
    SUM(pi.so) AS total_strikeouts,
    COUNT(DISTINCT pe.playerid) AS total_pitchers,
    ROUND((SUM(pi.so)::numeric / COUNT(DISTINCT pe.playerid)::numeric), 2
    	) AS avg_strikeouts_per_pitcher
FROM people AS pe
INNER JOIN pitching AS pi USING(playerid)
WHERE pi.yearid >= 2000
  AND pe.throws IN ('L', 'R')
GROUP BY pe.throws
;

		-- Left handed pichers are slighter better than right handed pitchers

SELECT 
    pe.throws,
    COUNT(DISTINCT aw.yearID) AS total_cy_young_awards,
    ROUND(
        (COUNT(DISTINCT aw.yearID)::numeric / 
         SUM(COUNT(DISTINCT aw.yearID)) OVER()) * 100, 2
    ) AS percentage
FROM people AS pe
INNER JOIN awardsplayers AS aw ON pe.playerID = aw.playerID
WHERE aw.awardID = 'Cy Young Award'
  AND aw.yearID >= 2000
  AND pe.throws IN ('L', 'R')
GROUP BY pe.throws;

		-- Left-handed pitchers win a higher percentage of Cy Young Awards relative to their overall proportion in the league

SELECT 
    pe.throws,
    COUNT(DISTINCT pe.playerID) AS hhof_pitchers,
    ROUND(
        (COUNT(DISTINCT pe.playerID)::numeric / 
         SUM(COUNT(DISTINCT pe.playerID)) OVER()) * 100, 2
    ) AS percentage
FROM people AS pe
INNER JOIN halloffame AS hf ON pe.playerID = hf.playerID
WHERE hf.category = 'Player' 
  AND hf.inducted = 'Y'
  AND pe.throws IN ('L', 'R')
GROUP BY pe.throws
;


		-- There is no distinct bias; induction is determined by overall career achievements and statistics rather than throwing hand
--						BONUS

--	In these exercises, you'll explore a couple of other advanced features of PostgreSQL. 

--	1.	In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, 
--		but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

--		a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

--			If you need a hint, you can structure your query as follows:

--	SELECT DISTINCT lgid, ( <Write a correlated subquery here that will pull the teamid for the team with the highest number of wins from each league> )
--	FROM teams t
--	WHERE yearid = 2016;

--		b.	One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example 
--			that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. 
--			(Try it and see the error you get). Add another correlated subquery to your query on the previous part so that your result shows not 
--			just the teamid but also the number of wins by that team.

--		c.	If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression 
--			(https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to 
--			return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

--		d.	If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword 
--			(https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM 
--			that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple 
--			rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the team ID and number of wins for the team 
--			with the most wins from each league in 2016. 

--			If you want a hint, you can structure your query as follows:

--	SELECT *
--	FROM (SELECT DISTINCT lgid 
--    FROM teams
--    WHERE yearid = 2016) AS leagues,
--    LATERAL ( <Fill in a subquery here to retrieve the teamid and number of wins> ) as top_teams;
      
--		e.	Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. 
--			(Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the 
--			previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.


--	2.	Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, 
--		you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. 
--		For example,

--	SELECT 
--		teamid,
--		w,
--		l,
--		w + l AS total_games,
--		w*100.0 / total_games AS winning_pct
--	FROM teams
--	WHERE yearid = 2016
--	ORDER BY winning_pct DESC;

--		results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

--	SELECT
--  teamid,
--  w,
--  l,
--  total_games,
--  w*100.0 / total_games AS winning_pct
--	FROM teams t,
--	LATERAL (
--	  SELECT w + l AS total_games
--	) AS tg
--	WHERE yearid = 2016
--	ORDER BY winning_pct DESC;

--	a.	Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called 
--		birthdate which is of the date type.

--	b.	Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. 
--		(Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).

--	c.	Who is the youngest player to ever play in the major leagues?

--	d.	Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. 
--		Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

--	3.	For this question, you will want to make use of RECURSIVE CTEs (see https://www.postgresql.org/docs/13/queries-with.html). 
--		The RECURSIVE keyword allows a CTE to refer to its own output. Recursive CTEs are useful for navigating network datasets such as social networks, 
--		logistics networks, or employee hierarchies (who manages who and who manages that person). To see an example of the last item, see this 
--		tutorial: https://www.postgresqltutorial.com/postgresql-recursive-query/. 

--		In the next couple of weeks, you'll see how the graph database Neo4j can easily work with such datasets, but for now we'll 
--		see how the RECURSIVE keyword can pull it off (in a much less efficient manner) in PostgreSQL. 
--		(Hint: You might find it useful to look at this blog post when attempting to answer the following questions: https://data36.com/kevin-bacon-game-recursive-sql/.)

--	a.	Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? 
--		(A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

--	b.	How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with another player 
--		who started an All Star Game with Willie Mays? For example, Graig Nettles never started an All Star Game with Willie Mayes, but he did star 
--		the 1975 All Star Game with Blue Vida who started the 1971 All Star Game with Willie Mays.

--	c.	We'll call two players connected if they both started in the same All Star Game. Using this, we can find chains of players. 
--		For example, one chain from Carlton Fisk to Willie Mays is as follows: Carlton Fisk started in the 1973 All Star Game with Rod Carew who 
--		started in the 1972 All Star Game with Willie Mays. Find a chain of All Star starters connecting Babe Ruth to Willie Mays. 

--	d.	How large a chain do you need to connect Derek Jeter to Willie Mays?

