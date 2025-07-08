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

--отчет по возрастным группам покупателей
select 
	'16-25' as age_category,
	COUNT(CASE WHEN age between 16 and 25 THEN 1 END) AS age_count	
from customers c
union all
select 
	'26-40' as age_category,
	COUNT(CASE WHEN age between 26 and 40 THEN 1 END) AS age_count	
from customers c
union all
select 
	'40+' as age_category,
	COUNT(CASE WHEN age > 40 THEN 1 END) AS age_count	
from customers c

--отчет с количеством покупателей и выручкой по месяцам
select
TO_CHAR(s.sale_date, 'YYYY-MM') as selling_month,
count(distinct customer_id) as total_customers,
round(sum(s.quantity * p.price),0) as income
from sales s
join products p 
	on s.product_id = p.product_id
group by extract(month from s.sale_date),TO_CHAR(s.sale_date, 'YYYY-MM')
order by extract(month from s.sale_date);

--отчет с покупателями первая покупка которых пришлась на время проведения специальных акций
with ordered_sales as (
	select 
		s.customer_id,
		s.sale_date,
		s.sales_person_id,
		s.product_id,
		p.price,
		row_number() over (partition by s.customer_id order by s.sale_date) as rn
	from sales s
	join products p on s.product_id=p.product_id
	order by customer_id, s.sale_date
)
select 
concat(c.first_name,' ',c.last_name) as customer,
s.sale_date,
concat(e.first_name,' ',e.last_name) as seller
from ordered_sales s
join employees e on s.sales_person_id = e.employee_id
join customers c on s.customer_id = c.customer_id
where rn=1 and s.price=0;



