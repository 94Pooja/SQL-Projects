/*
"Part A - Calculating loyalty points				
"Based on the above information and the data provided answer the following questions:
1. Find Playerwise Loyalty points earned by Players in the following slots:-
    a. 2nd October Slot S1
    b. 16th October Slot S2
    b. 18th October Slot S1
    b. 26th October Slot S2
2. Calculate overall loyalty points earned and rank players on the basis of loyalty points in the month of October. 
     In case of tie, number of games played should be taken as the next criteria for ranking.
3. What is the average deposit amount?
4. What is the average deposit amount per user in a month?
5. What is the average number of games played per user?"

"Final Loyalty Point Formula
Loyalty Point = (0.01 * deposit) + (0.005 * Withdrawal amount) + (0.001 * (maximum of (#deposit - #withdrawal) or 0)) + (0.2 * Number of games played)

At the end of each month total loyalty points are alloted to all the players. Out of which the top 50 players are provided cash benefits."																									
*/

--HERE WE JOINED THE ALL 3 TABLES
create view PlayerDetail as
   SELECT 
        u.User_ID,
		u.Games_Played,
		u.Datetime,
        w.Amount as withdrawl_amount ,
		d.Amount as deposite_amount,
   CASE
      when DATEPART(HOUR,u.Datetime) >=12 and DATEPART(HOUR,u.Datetime)<24 then 'S1'
      else 'S2'
   END AS Slot
   from [User game play data] as u 
	   left join [Withdrawal data] as w
          on u.User_ID=w.User_Id
       left join [Deposite data] as d
          on u.User_ID=d.User_Id

--Q>On each day, there are 2 slots for each of which the loyalty points are to be calculated:
--S1 from 12am to 12pm 
--S2 from 12pm to 12am"

SELECT
    distinct(User_ID),Datetime,sum(Games_Played) as no_of_game_played,Slot,
    SUM(
        0.01 * deposite_amount +
        0.005 * withdrawl_amount +
        0.001 * (CASE WHEN deposite_amount - withdrawl_amount > 0 THEN deposite_amount - withdrawl_amount ELSE 0 END) +
        0.2 * Games_Played
    ) AS LoyaltyPoints
FROM
    PlayerDetail
WHERE
     datepart(dd,Datetime)='02' and Slot in('S1')
	 OR datepart(dd,Datetime)='18' and Slot in('S1')
	 OR datepart(dd,Datetime)='16' and Slot in('S2')
	 OR datepart(dd,Datetime)='26' and Slot in('S2')
GROUP BY
    User_ID,Datetime,Slot;

--Q2)Calculate overall loyalty points.

WITH PlayerRank AS (
    SELECT
        User_ID,
         SUM(
        0.01 * deposite_amount +
        0.005 * withdrawl_amount +
        0.001 * (CASE WHEN deposite_amount - withdrawl_amount > 0 THEN deposite_amount - withdrawl_amount ELSE 0 END) +
        0.2 * Games_Played
            ) AS TotalLoyaltyPoints,
        COUNT(*) AS TotalGamePlayedperUser
    FROM
        PlayerDetail
    GROUP BY
        User_ID
)
SELECT
    User_ID,
    TotalLoyaltyPoints,
    TotalGamePlayedperUser,
    ROW_NUMBER() OVER (ORDER BY TotalLoyaltyPoints DESC, TotalGamePlayedperUser DESC) AS Rank
FROM
    PlayerRank;

--Q3)Average deposite amount

SELECT
avg(deposite_amount) as AvgDepositeAmount
FROM
PlayerDetail;

--4. What is the average deposit amount per user in a month?
SELECT 
     AVG(deposite_amount) as AvgDepositePerUser
FROM PlayerDetail
     WHERE MONTH(Datetime)='10'
GROUP BY
     User_ID

--5. What is the average number of games played per user?"

SELECT
     USER_ID,
     AVG(Games_Played) as AvgGamePerUser
FROM PlayerDetail    
GROUP BY
     User_ID
/*
"Part B - How much bonus should be allocated to leaderboard players?

After calculating the loyalty points for the whole month find out which 50 players are at the top of the leaderboard.
The company has allocated a pool of Rs 50000 to be given away as bonus money to the loyal players.

Suggest a suitable way to divide the allocated money keeping in mind the following points:
1. Only top 50 ranked players are awarded bonus
*/

WITH PlayerLoyalty AS 
(
    SELECT
        User_ID,
        SUM(
            0.01 * deposite_amount +
            0.005 * withdrawl_amount +
            0.001 * (CASE WHEN deposite_amount - withdrawl_amount > 0 THEN deposite_amount - withdrawl_amount ELSE 0 END) +
            0.2 * Games_Played
        ) AS TotalLoyaltyPoints,
        COUNT(*) AS TotalGamePlayedperUser
    FROM
        PlayerDetail
    GROUP BY
        User_ID
)
SELECT
    User_ID,
    TotalLoyaltyPoints,
    TotalGamePlayedperUser,
    ROW_NUMBER() OVER (ORDER BY TotalLoyaltyPoints DESC, TotalGamePlayedperUser DESC) AS Rank,
    CASE
        WHEN ROW_NUMBER() OVER (ORDER BY TotalLoyaltyPoints DESC, TotalGamePlayedperUser DESC) <= 50 
        THEN
            ((0.75 * TotalLoyaltyPoints / TotalLoyaltyPointsSum) * 50000 +
            (0.25 * TotalGamePlayedperUser / TotalGamesPlayedSum) * 50000)
        ELSE
            0
    END AS BonusAllocation
FROM
   PlayerLoyalty
cross join
    (
	SELECT SUM(TotalGamePlayedperUser) AS TotalGamesPlayedSum, 
	SUM(TotalLoyaltyPoints) AS TotalLoyaltyPointsSum 
	FROM PlayerLoyalty
	) as total;

--Part C

--Would you say the loyalty point formula is fair or unfair?
From my perspective loyalty point formula is fair because it considered the all parameter 


--Can you suggest any way to make the loyalty point formula more robust?"
To make it more robust i think we need to considered 
Time(duration of play) & 
no.of.games played in a single day
& also we need to keep loyalty formula be simple so user can easliy understand.
