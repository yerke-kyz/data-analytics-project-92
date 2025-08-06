-- -----------------------------------------------------------------------------
-- 1. Топ-10 продавцов с наибольшей выручкой
-- -----------------------------------------------------------------------------
with sellers_ops as (
    select
        e.employee_id,
        concat(e.first_name, ' ', e.last_name) as seller,
        count(s.sales_id) as operations
    from
        employees as e
    left join
        sales as s
        on
            e.employee_id = s.sales_person_id
    group by
        e.employee_id,
        seller
),

sales_amount as (
    select
        s.sales_id,
        s.sales_person_id,
        s.quantity * p.price as amount
    from
        sales as s
    inner join
        products as p
        on
            s.product_id = p.product_id
)

select
    so.seller,
    so.operations,
    floor(sum(sa.amount)) as income
from
    sellers_ops as so
inner join
    sales_amount as sa
    on
        so.employee_id = sa.sales_person_id
group by
    so.seller,
    so.operations
order by
    sum(sa.amount) desc
limit
    10;

-- -----------------------------------------------------------------------------
-- 2. Продавцы с выручкой ниже средней
-- -----------------------------------------------------------------------------
with sales_avg as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        floor(avg(s.quantity * p.price)) as avg_income
    from
        sales as s
    inner join
        products as p
        on
            s.product_id = p.product_id
    inner join
        employees as e
        on
            s.sales_person_id = e.employee_id
    group by
        seller
)

select
    sa.seller,
    sa.avg_income
from
    sales_avg as sa
where
    sa.avg_income < (
        select avg(sa2.avg_income)
        from
            sales_avg as sa2
    )
order by
    sa.avg_income;

-- -----------------------------------------------------------------------------
-- 3. Выручка по продавцу и дню недели (дни в lowercase)
-- -----------------------------------------------------------------------------
with sales_per_day as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        s.quantity * p.price as amount,
        case
            when extract(dow from s.sale_date) = 0
                then 7
            else extract(dow from s.sale_date)
        end as day_no,
        lower(to_char(s.sale_date, 'Day')) as day_name
    from
        sales as s
    inner join
        products as p
        on
            s.product_id = p.product_id
    inner join
        employees as e
        on
            s.sales_person_id = e.employee_id
)

select
    sd.seller,
    sd.day_name as day_of_week,
    floor(sum(sd.amount)) as income
from
    sales_per_day as sd
group by
    sd.day_no,
    sd.seller,
    sd.day_name
order by
    sd.day_no,
    sd.seller;

-- -----------------------------------------------------------------------------
-- 4. Выручка по продавцу и дню недели (дни с сохранением регистра)
-- -----------------------------------------------------------------------------
with sales_per_day_cap as (
    select
        concat(e.first_name, ' ', e.last_name) as seller,
        s.quantity * p.price as amount,
        case
            when extract(dow from s.sale_date) = 0
                then 7
            else extract(dow from s.sale_date)
        end as day_no,
        to_char(s.sale_date, 'Day') as day_name
    from
        sales as s
    inner join
        products as p
        on
            s.product_id = p.product_id
    inner join
        employees as e
        on
            s.sales_person_id = e.employee_id
)

select
    sdc.seller,
    sdc.day_name as day_of_week,
    round(sum(sdc.amount), 0) as income
from
    sales_per_day_cap as sdc
group by
    sdc.day_no,
    sdc.seller,
    sdc.day_name
order by
    sdc.day_no,
    sdc.seller;

-- -----------------------------------------------------------------------------
-- 5. Отчёт по возрастным группам покупателей
-- -----------------------------------------------------------------------------
select
    '16-25' as age_category,
    count(c.*) filter (where age between 16 and 25) as age_count
from
    customers

union all

select
    '26-40' as age_category,
    count(c.*) filter (where age between 26 and 40) as age_count
from
    customers

union all

select
    '40+' as age_category,
    count(c.*) filter (where age > 40) as age_count
from
    customers;

-- -----------------------------------------------------------------------------
-- 6. Количество покупателей и выручка по месяцам
-- -----------------------------------------------------------------------------
select
    to_char(s.sale_date, 'YYYY-MM') as selling_month,
    count(distinct s.customer_id) as total_customers,
    floor(sum(s.quantity * p.price)) as income
from
    sales as s
inner join
    products as p
    on
        s.product_id = p.product_id
group by
    to_char(s.sale_date, 'YYYY-MM')
order by
    to_char(s.sale_date, 'YYYY-MM');

-- -----------------------------------------------------------------------------
-- 7. Первая покупка во время специальных акций
-- -----------------------------------------------------------------------------
with ordered_sales as (
    select
        s.customer_id,
        s.sale_date,
        s.sales_person_id,
        p.price,
        row_number() over (
            partition by s.customer_id
            order by s.sale_date
        ) as rn
    from
        sales as s
    inner join
        products as p
        on
            s.product_id = p.product_id
    order by
        s.customer_id,
        s.sale_date
)

select
    os.sale_date,
    concat(c.first_name, ' ', c.last_name) as customer,
    concat(e.first_name, ' ', e.last_name) as seller
from
    ordered_sales as os
inner join
    employees as e
    on
        os.sales_person_id = e.employee_id
inner join
    customers as c
    on
        os.customer_id = c.customer_id
where
    os.rn = 1
    and os.price = 0;
