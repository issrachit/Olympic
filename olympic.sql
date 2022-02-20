--1. How many olympics games have been held?
select count(distinct(games)) as total_olypic1_games_held from athlete


--2 List down all Olympics games held so far. (Data issue at 1956-"Summer"-"Stockholm")
select distinct(year),season,city from athlete
order by year


--3 Mention the total no of nations who participated in each olympics game?
select games,count(distinct(noc)) as nation_participated_olympic_games from athlete
group by games
order by games


--4 Which year saw the highest and lowest no of countries participating in olympics
select concat(max(x.games),'-',max(x.nation_participated_olympic_games)) as highest_countries,
concat(min(x.games),'-',min(x.nation_participated_olympic_games)) as lowest_countries from
									(select games,count(distinct(noc)) as nation_participated_olympic_games from athlete
									group by games
									order by games) as x



--5 Which nation has participated in all of the olympic games
select x.team as country,sum(x.no_of_country_per_year) as total_partitcipated_games from
(select games,team, count(distinct team)as no_of_country_per_year from athlete
where year between 1896 and 2016
group by games,team) as x
group by x.team
having sum(no_of_country_per_year)=51



--6. Identify the sport which was played in all summer olympics.
with t1 as
		(select count(distinct year) as total_no_of_games from athlete where season ='Summer' and year between 1896 and 2016),
	 t2 as 
	 		(select year,sport,count(distinct sport) as no_of_games from athlete 
			 group by sport,year order by year),
	t3 as 
			(select sport,sum(no_of_games) as no_of_games  from t2 group by sport)
select * from t3
right join t1
on t1.total_no_of_games =t3.no_of_games



--7. Which Sports were just played only once in the olympics.

with t1 as
	(select distinct games,sport 
	 from athlete ),
	 t2 as
	 (select  sport,count(1) as no_of_games from t1
	 	group by sport)
	select t2.*,t1.games from t2
	left join t1
	on t2.sport=t1.sport
	where t2.no_of_games=1
	order by t2.sport


--8Fetch the total no of sports played in each olympic games.
select games,count(distinct sport) as nog from athlete group by games
order by nog desc,games asc



--9 Fetch oldest athletes to win a gold medal
select * from athlete
where age in(select max(age) from athlete where medal ='Gold') and medal ='Gold' 



--10 Find the Ratio of male and female athletes participated in all olympic games.
with t1 as
		(select sex,count(1) as cn from athlete group by sex),
	min_cnt as
		(select cn from t1 where sex='F' ),
 	max_cnt as
		(select cn from t1 where sex='M' )
select concat('1',' : ',round(max_cnt.cn /min_cnt.cn::decimal,2))as ratio from min_cnt,max_cnt



--11. Fetch the top 5 athletes who have won the most gold medals.
select name,team,count(medal) as no_of_gold_medal from athlete
where medal ='Gold' 
group by name,team
having count(medal)>=7
order by no_of_gold_medal desc



--12Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as
		(select name,team,count(medal) as no_of_medal from athlete
		where medal is not null
		group by name,team),
	 t2 as
		(select *,dense_rank() over( order by no_of_medal desc ) as rn from t1)
	select name,team,no_of_medal from t2
	where rn<=5

	

--13Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as 
		(select n.region,count(medal)as  no_of_medal from athlete as a
		 join noc as n on n.noc=a.noc
		where medal is not null
		group by n.region
		order by no_of_medal desc),
	t2 as
		(select *,dense_rank() over(order by no_of_medal desc) as rn from t1)
	select * from t2
	where rn<=5


-- PIVOT
In Postgresql, we can use crosstab function to create pivot table.
crosstab function is part of a PostgreSQL extension called tablefunc.
To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;


--14Write a SQL query to list down the  total gold, silver and bronze medals won by each country.
with t1 as 
		(select n.region,medal from athlete as a
		 join noc as n on n.noc=a.noc where medal is not null),
	 g as
		(select region,count(medal) as gold from t1 where medal='Gold' group by region),
	 s as
		(select region,count(medal) as silver from t1 where medal='Silver' group by region),
	b as
		(select region,count(medal) as bronze from t1 where medal='Bronze' group by region)
	select g.region,g.gold,s.silver,b.bronze from g
	join s
	on s.region=g.region
	join b
	on s.region=b.region
	order by gold desc
--OR
create extension tablefunc;
select country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze
from crosstab('select n.region as country,medal,count(1) as total_medal from athlete as a
				join noc as n
				on n.noc=a.noc
				where medal<>''0''
				group by n.region,medal
				order by n.region,medal',
				'values(''Bronze''),(''Gold''),(''Silver'')')
			as result(country varchar,bronze bigint,gold bigint,silver bigint)



--15. List down total gold, silver and broze medals won by each country corresponding to each olympic games.
--Note:SQL must return 3 columns: rowid, category, and values.
select  
substring(games,1,position('-'in games)-1) as games,
substring(games,position('-'in games)+1,10) as country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze
from crosstab
('select concat(games,''-'',n.region) as games,medal,count(1) as total_medal 
from athlete as a join noc as n
on n.noc=a.noc where medal<>''0''
group by games,n.region,medal
order by games,n.region,medal',
'values(''Bronze''),(''Gold''),(''Silver'')')
as result(games text,bronze bigint,gold bigint,silver bigint)




16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with t1 as 
(select 
substring(country,1,position('-'in country)-1) as games,
substring(country,position('-' in country)+1,10) as country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze from
crosstab('select concat(games,''-'',n.region)as country,medal,count(1) as max_medal 
 from athlete as a join noc as n on a.noc=n.noc where medal<>''0''
group by games,n.region,medal
order by games,n.region,medal','values(''Bronze''),(''Gold''),(''Silver'')')
 as result(country text,bronze bigint,gold bigint,silver bigint)),
 
select distinct games,
 concat(first_value(country) over(partition by games order by gold desc),'-',
		first_value(gold) over(partition by games order by gold desc)) as max_gold,
 concat(first_value(country) over(partition by t1.games order by silver desc),'-',
		first_value(silver) over(partition by games order by silver desc))as max_silver,
 concat(first_value(country) over(partition by t1.games order by bronze desc),'-',
		first_value(bronze) over(partition by games order by bronze desc)) as max_bronze
	from t1
       order by games 
 




17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with t1 as 
(select 
substring(country,1,position('-'in country)-1) as games,
substring(country,position('-' in country)+1,10) as country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze from
crosstab('select concat(games,''-'',n.region)as country,medal,count(1) as max_medal 
 from athlete as a join noc as n on a.noc=n.noc where medal<>''0''
group by games,n.region,medal
order by games,n.region,medal','values(''Bronze''),(''Gold''),(''Silver'')')
 as result(country text,bronze bigint,gold bigint,silver bigint)),
  t2 as
 (select games,n.region as country,count(medal) as max_medal 
 from athlete as a join noc as n on a.noc=n.noc where medal<>'0'
group by games,n.region
order by games,n.region)

select distinct t1.games,
 concat(first_value(t1.country) over(partition by t1.games order by gold desc),'-',
		first_value(t1.gold) over(partition by t1.games order by gold desc)) as max_gold,
 concat(first_value(t1.country) over(partition by t1.games order by silver desc),'-',
		first_value(t1.silver) over(partition by t1.games order by silver desc))as max_silver,
 concat(first_value(t1.country) over(partition by t1.games order by bronze desc),'-',
		first_value(t1.bronze) over(partition by t1.games order by bronze desc)) as max_bronze,
 concat(first_value(t2.country) over(partition by t2.games order by max_medal desc),'-',
		first_value(t2.max_medal) over(partition by t2.games order by max_medal desc)) as max_medals
		from t1 join t2 on t1.games=t2.games and t1.country=t2.country
  order by games 
 




--18. Which countries have never won gold medal but have won silver/bronze medals?
--COALESCE
select coalesce(medal,'0') as medal from athlete
update athlete
set medal=coalesce(medal,'0')

select * from
(select country,
coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
from
crosstab('SELECT n.region as country
    					, medal, count(1) as total_medals
    					FROM athlete as  a
    					JOIN noc n ON n.noc=a.noc
    					where medal<>''0''
    					GROUP BY n.region,medal order BY n.region,medal',
		'values(''Bronze''),(''Gold''),(''Silver'')')
		as result(country varchar,bronze bigint,gold bigint,silver bigint)) as x
		where gold=0 and (silver>0 or bronze>0)
		order by gold desc nulls last , silver desc nulls last, bronze desc nulls last




--19in which Sport/event, India has won highest medals.	
select n.region,sport,count(medal) as no_of_medal from athlete as a
join noc as n
on n.noc=a.noc
where n.region ='India'
group by n.region,sport
order by count(medal) desc
limit 1



--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
select n.region,sport,games,count(medal) as no_of_medal from athlete as a
join noc as n
on n.noc=a.noc where n.region ='India' and sport='Hockey'
group by n.region,sport,games
order by no_of_medal desc

