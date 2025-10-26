-- Primary and Secondary Questions

-- Total Trips by City -- Top 3
select city_name , count(trip_id) as Total_Trips
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name
order by Total_Trips desc
limit 3
-- Bottom 3
with cte as (
select city_name , count(trip_id) as Total_Trips , dense_rank() over (order by count(trip_id) asc) as rn
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name )
select *
from cte where rn <=3
-------------------------------------------------------------
-- Average Fare per trip per city
select city_name , count(trip_id) as Total_Trips , avg(fare_amount) as Avg_amount , avg(distance_travelled_km)
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name
order by Avg_amount
-- Average Passenger and Driver Ratings
select city_name ,passenger_type, avg(passenger_rating) , avg(driver_rating)
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name,passenger_type
----------------------------------------------------------------------------------
-- peak demands monthwise for cities
--peak demanding month city wise 
with cte as (
select city_name , year(dd.date) as year_no,month(dd.date) as Month_No, count(trip_id) as total_trips , dense_rank() over(partition by city_name order by count(trip_id) desc) as rn
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
join dim_date dd on dd.date = ft.date
group by city_name,month(dd.date),year(dd.date) 
)
select city_name , year_no, Month_No , total_trips
from cte
where rn =1
order by month_no
-------------------------------------------------------------
-- low demand month wise 
select city_name ,passenger_type, avg(passenger_rating) , avg(driver_rating)
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name,passenger_type
-- low demands monthwise for cities
--low demanding month city wise 
with cte as (
select city_name , year(dd.date) as year_no,month(dd.date) as Month_No, count(trip_id) as total_trips , dense_rank() over(partition by city_name order by count(trip_id) asc) as rn
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
join dim_date dd on dd.date = ft.date
group by city_name,month(dd.date),year(dd.date) 
)
select city_name , year_no, Month_No , total_trips
from cte
where rn =1
-------------------------------------------------------------
with cte as (
select city_name,dd.day_type, count(trip_id) as total_trips , dense_rank() over(partition by city_name order by count(trip_id) desc) as rn
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
join dim_date dd on dd.date = ft.date
group by city_name,dd.day_type )
select * 
from cte 
where rn =1
-------------------------------------------------------------------
-- frequency of each repeat passenger in each city
with cte as (
select dc.city_name , rt.trip_count , sum(rt.repeat_passenger_count) as total_repeat_pgr
from dim_city dc 
join dim_repeat_trip_distribution rt
on rt.city_id = dc.city_id	
group by dc.city_name,rt.trip_count) , cte_2 as (
select city_name, trip_count, total_repeat_pgr, (select sum(repeat_passenger_count) from dim_repeat_trip_distribution) as gt
from cte )
select *, (total_repeat_pgr/gt)*100 as repeat_passenger_rate
from cte_2
order by repeat_passenger_rate desc
----------------------------------------------------------------------
-- monthly target achievement analysis for each city
with actual_trips as (
select city_name , count(trip_id) as Actual_Trips , month(dd.date) as month_no
from trips_db.dim_city dc
join trips_db.fact_trips ft on ft.city_id = dc.city_id
join trips_db.dim_date dd on dd.date = ft.date
group by city_name, month(dd.date))
,
total_target_trips  as (SELECT dc.city_name, month(mt.month) as month_no, mt.total_target_trips
                      FROM targets_db.monthly_target_trips mt
                      join dim_city dc on dc.city_id = mt.city_id
                      order by city_name )

SELECT 
    t.city_name,
    t.month_no,
	a.actual_trips,
    t.total_target_trips,
    (t.total_target_trips- a.actual_trips) AS achievement_pct , 
    case when  (t.total_target_trips- a.actual_trips) > 0 then "Not Achieved" 
         when  (t.total_target_trips- a.actual_trips) <0  then "Achieved"  end as Status
FROM total_target_trips t
JOIN actual_trips a
    ON a.city_name = t.city_name AND a.month_no = t.month_no
    order by status asc
    
--------------------
-- Identify RPR based on city and month
SELECT month(month), city_name , (repeat_passengers/total_passengers)*100 as rpr
FROM trips_db.fact_passenger_summary fp
join dim_city dc on dc.city_id = fp.city_id

top 2 cities
SELECT month(month), city_name , (repeat_passengers/total_passengers)*100 as rpr
FROM trips_db.fact_passenger_summary fp
join dim_city dc on dc.city_id = fp.city_id
order by rpr desc 
limit 2
bottom 2 cities
with cte as (
SELECT month(month), city_name , (repeat_passengers/total_passengers)*100 as rpr, dense_rank() over(partition by city_name order by (repeat_passengers/total_passengers)*100 asc ) as rn
FROM trips_db.fact_passenger_summary fp
join dim_city dc on dc.city_id = fp.city_id) , cte2 as (
select *
from cte
where rn =1)
select *
from cte2
order by rpr asc
limit 2

SELECT city_name , (repeat_passengers/total_passengers)*100 as rpr, dense_rank() over(partition by city_name order by (repeat_passengers/total_passengers)*100 asc ) as rn
FROM trips_db.fact_passenger_summary fp
join dim_city dc on dc.city_id = fp.city_id

--------------------------------------------------------


