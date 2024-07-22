
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

--8. Find the `first_login` datetime for each device ID.
SELECT Dev_ID, MIN(TimeStamp) As FirstLogin
FROM [Game Analysis].DBO.level_details2$
GROUP BY Dev_ID;

--9. Find the top 5 scores based on each difficulty level and rank them in increasing order 
--using `Rank`. Display `Dev_ID` as well. 
WITH RankedScores AS (
    SELECT lev.Dev_ID, lev.Score, lev.Difficulty,
    RANK() OVER (PARTITION BY lev.Difficulty ORDER BY lev.score DESC) AS Rank
    FROM [Game Analysis].dbo.level_details2$ lev
)
SELECT rs.Dev_ID,rs.score,rs.difficulty,rs.Rank
FROM RankedScores rs
WHERE rs.Rank <= 5
ORDER BY rs.difficulty ASC, rs.Rank ASC;

--10. Find the device ID that is first logged in (based on `start_datetime`) for each player 
--(`P_ID`). Output should contain player ID, device ID, and first login datetime. 

WITH RankedLogins AS (
    SELECT P_ID,Dev_ID,TimeStamp,
    ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp ASC) AS LoginRank
    FROM [Game Analysis].DBO.level_details2$ 
)
SELECT P_ID,Dev_ID,TimeStamp AS first_login_datetime
FROM RankedLogins
WHERE LoginRank = 1;

--11. For each player and date, determine how many `kill_counts` were played by the player 
--so far. 
--a) Using window functions 
SELECT P_ID, TimeStamp,kill_count,
    SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS total_kill_count_so_far
FROM [Game Analysis].DBO.level_details2$
ORDER BY P_ID,TimeStamp;


--b) Without window functions 
SELECT lev.P_ID, lev.TimeStamp,lev.kill_count,
    (SELECT SUM(lev.kill_count)
        FROM [Game Analysis].DBO.level_details2$ lev
        WHERE lev.P_ID = lev.P_ID
        AND lev.TimeStamp <= lev.TimeStamp
    ) AS total_kill_count_so_far
FROM [Game Analysis].DBO.level_details2$ lev
ORDER BY lev.P_ID, lev.TimeStamp;

--12. Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, 
--excluding the most recent `start_datetime`.

WITH CumulativeStages AS (
    SELECT P_ID, TimeStamp,Stages_crossed,
        SUM(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS CumulativeStagesCrossed,
        ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC) AS rn
    FROM [Game Analysis].DBO.level_details2$
)
SELECT P_ID,TimeStamp,
    CumulativeStagesCrossed - COALESCE(LEAD(Stages_crossed) OVER (PARTITION BY P_ID ORDER BY TimeStamp DESC), 0) AS CumulativeStagesCrossed
FROM CumulativeStages
WHERE rn > 1
ORDER BY P_ID, TimeStamp;

--13. Extract the top 3 highest sums of scores for each Dev_ID and the corresponding P_ID.
WITH RankedScores AS (
    SELECT Dev_ID,P_ID,SUM(Score) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
    FROM [Game Analysis].DBO.level_details2$
    GROUP BY Dev_ID, P_ID
)
SELECT Dev_ID,P_ID,TotalScore
FROM RankedScores
WHERE Rank <= 3
ORDER BY Dev_ID, TotalScore DESC;

--14. Find players who scored more than 50% of the average score, scored by the sum of 
--scores for each `P_ID`. 
WITH PlayerTotalScores AS (
    SELECT P_ID, SUM(Score) AS TotalScore
    FROM [Game Analysis].DBO.level_details2$
    GROUP BY P_ID
),
AverageScore AS (
    SELECT AVG(TotalScore) AS AvgTotalScore
    FROM PlayerTotalScores
)
SELECT sts.P_ID, sts.TotalScore
FROM PlayerTotalScores sts
JOIN AverageScore avg ON sts.TotalScore > 0.5 * avg.AvgTotalScore
ORDER BY sts.P_ID;

--15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` 
--and rank them in increasing order using `Row_Number`. Display the difficulty as well.

CREATE PROCEDURE GetTopNHeadshotsByDevID
    @n INT
AS
BEGIN
    SET NOCOUNT ON;
    WITH RankedHeadshots AS (
        SELECT Dev_ID,Headshots_count,Difficulty,
            ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_count ASC) AS Rank
        FROM [Game Analysis].DBO.level_details2$
    )
    SELECT Dev_ID,Headshots_count,Difficulty
    FROM RankedHeadshots
    WHERE Rank <= @n
    ORDER BY Dev_ID, Rank;
END;
GO




























