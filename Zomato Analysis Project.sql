drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


select * from sales;
select * from product;
select * from users;
select * from goldusers_signup;

-- 1.   What is the totle amount each customer spent on zomato 

select a.userid,sum(b.price) from sales a
inner join product b
on a.product_id = b.product_id
group by a.userid
order by userid

-- 2.   How many days has each customer visited zomato?

select userid,count(distinct created_date)total_days from sales
group by userid

-- 3.   What was the first product purchased by each customer
select * from
(select c.userid,c.product_name, 
rank() over(partition by c.userid order by c.created_date asc)rnk
from 
(select * from sales a
inner join product b
on a.product_id = b.product_id)c)d
where rnk=1

/* 4.   what is the most purchased product on the menu and how many
 times it was purchased by each customer */
 
-- The most purchased product on the menu 
select product_id from sales
group by product_id
order by count(product_id) desc
limit 1

select userid,count(product_id)cnt from sales 
where product_id = (select product_id from sales
group by product_id
order by count(product_id) desc
limit 1)
group by userid

-- 5.  Which item is the most popular for each customer.
select * from 
(select *,
rank() over(partition by a.userid order by a.cnt desc) from
(select userid,product_id,count(product_id)cnt
from sales
group by userid,product_id)a)b
where rank=1

/* 6.  What item was purchased first by a customer after they became
a member? */

select * from
(select c.*,
rank() over(partition by userid order by created_date asc)rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
 from sales a 
inner join goldusers_signup b
on a.userid = b.userid
where created_date >= gold_signup_date)c)d
where rnk = 1

-- 7. Which item was purchased just before the customer became a member?
select d.* from 
(select c.*,
rank() over(partition by userid order by created_date desc)rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from
sales a
inner join goldusers_signup b
on a.userid = b.userid
where created_date < gold_signup_date)c)d
where rnk = 1

/* 8.  What is the the total orders and amount spent for each member
before they became a member */

select e.userid,count(e.created_date)total_orders,
sum(e.price)total_amount_spent
from
(select c.*,d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from
sales a
inner join goldusers_signup b
on a.userid = b.userid
where created_date < gold_signup_date)c
inner join product d on c.product_id = d.product_id)e
group by userid

/* 9. If buying each product generates points for eg 5rs=2 zomato point
and each product has different purchasing points for eg for p1 5rs=1
zomato point,for p2 10rs = 5 zomato points and for p3 5rs=1 zomato 
point.
Calculate points collected by each customers and for which product
most points have been given till now. */


--  points collected by each customers
select d.userid,sum(d.z_point)total_zomato_points from
(select *,
case 
when c.product_id =1 then (c.total)/5
when c.product_id =2 then (c.total)/2
when c.product_id =3 then (c.total)/5
else 0 end as z_point from
(select a.userid,a.product_id,sum(b.price)total from sales a
inner join product b
on a.product_id = b.product_id
group by a.userid,a.product_id)c)d
group by userid order by userid



-- product for which most points have been given till now
select * from
(select *,
rank() over(order by total_zomato_points desc)rnk
from
(select d.product_id,sum(d.z_point)total_zomato_points from
(select *,
case 
when c.product_id =1 then (c.total)/5
when c.product_id =2 then (c.total)/2
when c.product_id =3 then (c.total)/5
else 0 end as z_point from
(select a.userid,a.product_id,sum(b.price)total from sales a
inner join product b
on a.product_id = b.product_id
group by a.userid,a.product_id)c)d
group by product_id order by total_zomato_points desc)e)f
where rnk=1;


/* 10. In the first one year after a customer joins the golden program
(including their join date) irrespective of what the customer purchased
they earn 5 zomato points for every 10 rs. spent.Who earned more and 
what was their points earnings in their first year? */

select *,
rank() over(order by zomato_points desc)rnk from
(select g.userid,(g.price/2) Zomato_Points from
(select e.*,f.price from
(select * from
(select c.*,(gold_signup_date + INTERVAL '1 year')::date one_year_gold_signup_date
from
(select a.*,b.gold_signup_date from sales a
inner join goldusers_signup b
on a.userid = b.userid)c)d
where created_date between gold_signup_date and one_year_gold_signup_date)e
inner join product f on e.product_id = f.product_id)g)h


-- 11. Rank all the transactions of the customer

select *, rank() over(partition by userid order by created_date)rnk
from sales;

/* 12.Rank all the transactions for each member whenever they are a
zomato gold member.For every non gold member transaction mark as 'na'.*/


select e.userid,e.created_date,e.product_id,case when rnkk=0 then 'na' else cast( rnkk as varchar) end as rank1 from
(select *,
case when gold_signup_date is null then 0 else rnk end 
 as rnkk from
(select *,
rank() over(partition by userid order by created_date desc)rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
left join goldusers_signup b
on a.userid=b.userid
and created_date >= gold_signup_date)c)d)e
