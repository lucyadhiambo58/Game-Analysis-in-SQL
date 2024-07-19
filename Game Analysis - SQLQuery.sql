
--Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.
SELECT lev.P_ID,lev.Dev_ID,ply.PName, lev.Difficulty
FROM [Game Analysis].DBO.player_details$ ply
JOIN [Game Analysis].DBO.level_details2$ lev
ON lev.P_ID = ply.P_ID
WHERE lev.Level = 0

--2. Find the total number of stages crossed at each difficulty level for Level 2 with players.
SELECT Difficulty, SUM(Stages_crossed) As Total_Stages_Crossed
FROM [Game Analysis].DBO.level_details2$
WHERE Level = 2
GROUP BY Difficulty

----3. Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 
--stages are crossed. Arrange the result in decreasing order of the total number of 
--stages crossed.

SELECT ply.L1_Code, AVG(lev.Kill_Count) AS AverageKillCount, SUM(lev.Stages_crossed) AS TotalStagesCrossed
FROM [Game Analysis].DBO.level_details2$ lev
JOIN [Game Analysis].DBO.player_details$ ply ON lev.P_ID = ply.P_ID
WHERE lev.Lives_Earned = 2 AND lev.Stages_crossed >= 3
GROUP BY ply.L1_Code
ORDER BY TotalStagesCrossed DESC;

--4. Extract `P_ID` and the total number of unique dates for those players who have played 
--games on multiple days
SELECT lev.P_ID, 
       COUNT(DISTINCT CAST(lev.TimeStamp AS DATE)) AS UniqueDateCount
FROM [Game Analysis].DBO.level_details2$ lev 
JOIN [Game Analysis].DBO.player_details$ ply 
    ON lev.P_ID = ply.P_ID
GROUP BY lev.P_ID
HAVING COUNT(DISTINCT CAST(lev.TimeStamp AS DATE)) > 1;
--5. Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the 
--average kill count for Medium difficulty

SELECT lev.P_ID, lev.Level, SUM(lev.Kill_Count) AS TotalKillCount
FROM [Game Analysis].DBO.level_details2$ lev
JOIN (
    SELECT Difficulty, AVG(Kill_Count) AS AverageKillCount
    FROM [Game Analysis].DBO.level_details2$
    WHERE Difficulty = 'Medium'
    GROUP BY Difficulty
) AS AvgKill
ON lev.Difficulty = AvgKill.Difficulty
WHERE lev.Kill_Count > AvgKill.AverageKillCount
GROUP BY lev.P_ID, lev.Level;

--6. Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 
--0. Arrange in ascending order of level.
SELECT lev.Level, ply.L1_Code, ply.L2_Code, SUM(Lives_Earned) As TotalLivesEarned
FROM [Game Analysis].DBO.level_details2$ lev
JOIN [Game Analysis].DBO.player_details$ ply
ON lev.P_ID = ply.P_ID
WHERE lev.Level > 0
GROUP BY lev.Level, ply.L1_Code, ply.L2_Code
ORDER BY lev.Level ASC

--7. Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using 
--`Row_Number`. Display the difficulty as well. 

WITH TopScoresCTE AS (
    SELECT Score, Dev_ID, Difficulty,
           ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY Score DESC) AS ScoreRank
    FROM [Game Analysis].DBO.level_details2$
)
SELECT Score, Dev_ID, Difficulty
FROM TopScoresCTE
WHERE ScoreRank <= 3
ORDER BY Dev_ID, ScoreRank;





























