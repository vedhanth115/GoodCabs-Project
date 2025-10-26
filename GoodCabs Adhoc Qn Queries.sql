-- ADHOC Requests\
USE Trips_db;
/*Business Request - 1: City-Level Fare and Trip Summary Report*/
select city_name , count(trip_id) as Total_Trips , (sum(fare_amount)/sum(distance_travelled_km)) as avg_fare_Per_km , 
	   (sum(fare_amount)/count(trip_id)) as avg_fare_per_trip , 
       concat(round(count(trip_id)*100/sum(count(trip_id)) over(),2), " %") as Perc_to_total_trips
from dim_city dc
left join fact_trips ft on ft.city_id = dc.city_id 
group by city_name;
----------------------------------------------------------------------------------------------------------------------------
-- Business Request - 2: Monthly City-Level Trips Target Performance Report 
select dc.city_id,city_name, month(mtt.month), monthname(mtt.month)AS Month_Name, coalesce(count(trip_id),0) as actual_trips, total_target_trips,
       case when count(trip_id) > total_target_trips then 'Above Target' else "Below Target" end as performance_status,
       CONCAT( Round(
                      (coalesce(count(trip_id),0) - total_target_trips)*100/total_target_trips,2),"%" ) as Diff_in
from dim_city dc
left join fact_trips ft on ft.city_id= dc.city_id
left join targets_db.monthly_target_trips mtt on mtt.city_id = dc.city_id 
                                              AND MONTH(ft.date) = MONTH(mtt.month)
group by dc.city_id, city_name,monthname(month),total_target_trips,month(month)
order by city_name, month(month);
-----------------------------------------------------------------------------------------------------------------------------
-- Business Request - 3: City-Level Repeat Passenger Trip Frequency Report 
with cte as (
select city_name, trip_count, sum(repeat_passenger_count) as repeat_customer, sum(sum(repeat_passenger_count)) over (partition by city_name) as Total
from dim_city dc 
join dim_repeat_trip_distribution rtd on rtd.city_id = dc.city_id
group by city_name,trip_count),
cte2 as (
select * , (repeat_customer*100/Total) as Perc_repeat
from cte )
select City_name,
	   sum(case when trip_count = '2-Trips' then concat(round(perc_repeat,2),"%") end) as "2-Trips",
	   sum(case when trip_count = '3-Trips' then concat(round(perc_repeat,2),"%")  end) as "3 trips",
	   sum(case when trip_count = '4-Trips' then concat(round(perc_repeat,2),"%")  end) as "4 trips",
	   sum(case when trip_count = '5-Trips' then concat(round(perc_repeat,2),"%")  end) as "5 trips",
	   sum(case when trip_count = '6-Trips' then concat(round(perc_repeat,2),"%") end) as "6 trips",
	   sum(case when trip_count = '7-Trips' then concat(round(perc_repeat,2),"%") end) as "7 trips",
	   sum(case when trip_count = '8-Trips' then concat(round(perc_repeat,2),"%")  end) as "8 trips",
	   sum(case when trip_count = '9-Trips' then concat(round(perc_repeat,2),"%")  end) as "9 trips"
from cte2
group by city_name;
-- Business Request - 4: Identify Cities with Highest and Lowest Total New Passengers 
with cte as (
select city_name , sum(new_passengers)as New_Passengers , dense_rank() over(order by sum(new_passengers) desc ) as top_rank
, dense_rank() over(order by sum(new_passengers) asc ) as bottom_rank
from dim_city dc
join fact_passenger_summary fps on fps.city_id = dc.city_id
group by city_name )
      select city_name , New_Passengers , case when top_rank <=3 then "Top 3"
										 when bottom_rank <=3 then "Bottom 3" else "Other" end   as Category
      from cte
	  order by new_passengers desc;
      
-- Business Request - 5: Identify Month with Highest Revenue for Each City 
with cte as (
select city_name , monthname(date)as Month_name ,sum(fare_amount)as Revenue, sum(sum(fare_amount)) over (partition by city_name) as Total_Revenue , 
       dense_rank() over (partition by city_name order by sum(fare_amount) desc ) as rnk
from dim_city dc
join fact_trips ft on ft.city_id = dc.city_id
group by city_name,monthname(date) )
select city_name , Month_name, Revenue, concat(round((Revenue*100/Total_Revenue),2), "%") as perc_total_revenue
from cte
where rnk =1;
-- Business Request - 6: Repeat Passenger Rate Analysis 
with cte as (
Select city_name , monthname(month) as Month_name, sum(repeat_passengers ) as Repeat_passengers, 
     sum(total_passengers) as Total_passengers,
     sum(sum(total_passengers)) over(partition by city_name) as city_level,
     sum(repeat_passengers )*100/sum(total_passengers) as monthly_perc_repeat_rate,
	 sum(sum(repeat_passengers )*100) over(partition by city_name)/ sum(sum(total_passengers)) over(partition by city_name) as city_perc_repeat_rate
from dim_city dc
join fact_passenger_summary fps on fps.city_id = dc.city_id
group by city_name, monthname(month) 
)
select city_name, Month_name, Repeat_passengers, Total_passengers, concat(round(monthly_perc_repeat_rate,2),"%") , concat(round(city_perc_repeat_rate,2),"%")
from cte







