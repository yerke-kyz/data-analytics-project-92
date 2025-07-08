--count customers number
select 
count(*) as customers_count
from customers c ;

-- топ 10 продавцев у которых наибольшая выручка
with tab as (
	select 
	e.employee_id,
	concat(e.first_name,' ',e.last_name) as seller,
	count(s.sales_id) as operations
	from employees e 
	left join sales s on e.employee_id = s.sales_person_id
	group by e.employee_id , seller
	),
 sales_amount as (
	select
	s.*,
	s.quantity * p.price as amount
	from sales s
	join products p 
	on s.product_id = p.product_id
)
select 
tab.seller,
tab.operations,
sum(sa.amount) as income
from tab 
join sales_amount sa on tab.employee_id =sa.sales_person_id
group by tab.seller,
tab.operations
order by sum(sa.amount) desc
limit 10;


--отчет с продавцами, чья выручка ниже средней выручки всех продавцов
with  sales_amount_employees as (
	select
	concat(e.first_name,' ',e.last_name) as seller,
	s.quantity * p.price as amount
	from sales s
	join products p 
	on s.product_id = p.product_id
	join employees e on e.employee_id =s.sales_person_id
)
select 
seller,
round(avg(amount),0) as average_income
from sales_amount_employees
where amount < (select avg(amount) from sales_amount_employees)
group by seller
order by round(avg(amount),0);

--отчет с данными по выручке по каждому продавцу и дню недели
with  sales_amount_employees as (
	select
	concat(e.first_name,' ',e.last_name) as seller,
	s.quantity * p.price as amount,
	s.sale_date,
	case
		when extract(dow from s.sale_date) = 0 then 7
		else extract(dow from s.sale_date)
	end as number_of_day,
	TO_CHAR(s.sale_date, 'Day') AS day_of_week
	from sales s
	join products p 
	on s.product_id = p.product_id
	join employees e on e.employee_id =s.sales_person_id
)
select
seller,
day_of_week,
round(sum(s.amount),0) as income
from sales_amount_employees s
group by day_of_week, seller, number_of_day
order by number_of_day, seller;


--отчет с данными по выручке по каждому продавцу и дню недели
with  sales_amount_employees as (
	select
	concat(e.first_name,' ',e.last_name) as seller,
	s.quantity * p.price as amount,
	s.sale_date,
	case
		when extract(dow from s.sale_date) = 0 then 7
		else extract(dow from s.sale_date)
	end as number_of_day,
	TO_CHAR(s.sale_date, 'Day') AS day_of_week
	from sales s
	join products p 
	on s.product_id = p.product_id
	join employees e on e.employee_id =s.sales_person_id
)
select
seller,
day_of_week,
round(sum(s.amount),0) as income
from sales_amount_employees s
group by day_of_week, seller, number_of_day
order by number_of_day, seller;


