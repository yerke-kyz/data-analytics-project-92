-- -----------------------------------------------------------------------------
-- 1. Топ-10 продавцов с наибольшей выручкой
-- -----------------------------------------------------------------------------
with sellers_ops as (
    select
        e.employee_id                                as employee_id,
        concat(e.first_name, ' ', e.last_name)       as seller,
        count(s.sales_id)                            as operations
    from
        employees e
    left join
        sales s
            on e.employee_id = s.sales_person_id
    group by
        e.employee_id,
        seller
),

sales_amount as (
    select
        s.sales_id,
        s.sales_person_id,
        s.quantity * p.price                         as amount
    from
        sales s
    join
        products p
            on s.product_id = p.product_id
)

select
    so.seller,
    so.operations,
    floor(sum(sa.amount))                          as income
from
    sellers_ops so
join
    sales_amount sa
        on so.employee_id = sa.sales_person_id
group by
    so.seller,
    so.operations
order by
    sum(sa.amount) desc
limit
    10
;

-- -----------------------------------------------------------------------------
-- 2. Продавцы с выручкой ниже средней
-- -----------------------------------------------------------------------------
with sales_avg as (
    select
        concat(e.first_name, ' ', e.last_name)       as seller,
        floor(avg(s.quantity * p.price))             as avg_income
    from
        sales s
    join
        products p
            on s.product_id = p.product_id
    join
        employees e
            on e.employee_id = s.sales_person_id
    group by
        seller
)

select
    seller,
    avg_income
from
    sales_avg
where
    avg_income < (
        select
            avg(avg_income)
        from
            sales_avg
    )
order by
    avg_income
;

-- -----------------------------------------------------------------------------
-- 3. Выручка по продавцу и дню недели (дни в lowercase)
-- -----------------------------------------------------------------------------
with sales_per_day as (
    select
        concat(e.first_name, ' ', e.last_name)       as seller,
        s.quantity * p.price                         as amount,
        case
            when extract(dow from s.sale_date) = 0
                then 7
            else extract(dow from s.sale_date)
        end                                          as day_no,
        lower(to_char(s.sale_date, 'Day'))           as day_name
    from
        sales s
    join
        products p
            on s.product_id = p.product_id
    join
        employees e
            on e.employee_id = s.sales_person_id
)

select
    seller,
    day_name                                    as day_of_week,
    floor(sum(amount))                          as income
from
    sales_per_day
group by
    day_no,
    seller,
    day_name
order by
    day_no,
    seller
;

-- -----------------------------------------------------------------------------
-- 4. Выручка по продавцу и дню недели (дни с сохранением регистра)
-- -----------------------------------------------------------------------------
with sales_per_day_cap as (
    select
        concat(e.first_name, ' ', e.last_name)       as seller,
        s.quantity * p.price                         as amount,
        case
            when extract(dow from s.sale_date) = 0
                then 7
            else extract(dow from s.sale_date)
        end                                          as day_no,
        to_char(s.sale_date, 'Day')                  as day_name
    from
        sales s
    join
        products p
            on s.product_id = p.product_id
    join
        employees e
            on e.employee_id = s.sales_person_id
)

select
    seller,
    day_name                                    as day_of_week,
    round(sum(amount), 0)                       as income
from
    sales_per_day_cap
group by
    day_no,
    seller,
    day_name
order by
    day_no,
    seller
;

-- -----------------------------------------------------------------------------
-- 5. Отчёт по возрастным группам покупателей
-- -----------------------------------------------------------------------------
select
    '16-25'                                      as age_category,
    count(*) filter (where age between 16 and 25) as age_count
from
    customers

union all

select
    '26-40'                                      as age_category,
    count(*) filter (where age between 26 and 40) as age_count
from
    customers

union all

select
    '40+'                                        as age_category,
    count(*) filter (where age > 40)             as age_count
from
    customers
;

-- -----------------------------------------------------------------------------
-- 6. Количество покупателей и выручка по месяцам
-- -----------------------------------------------------------------------------
select
    to_char(s.sale_date, 'YYYY-MM')              as selling_month,
    count(distinct s.customer_id)                as total_customers,
    floor(sum(s.quantity * p.price))             as income
from
    sales s
join
    products p
        on s.product_id = p.product_id
group by
    to_char(s.sale_date, 'YYYY-MM')
order by
    to_char(s.sale_date, 'YYYY-MM')
;

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
        )                                           as rn
    from
        sales s
    join
        products p
            on s.product_id = p.product_id
    order by
        s.customer_id,
        s.sale_date
)

select
    concat(c.first_name, ' ', c.last_name)       as customer,
    os.sale_date,
    concat(e.first_name, ' ', e.last_name)       as seller
from
    ordered_sales os
join
    employees e
        on os.sales_person_id = e.employee_id
join
    customers c
        on os.customer_id = c.customer_id
where
    os.rn = 1
    and os.price = 0
;