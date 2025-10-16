-- Lab 2 SQL Answers

create database tpch
use tpch
-- Q1: Return nation id and name where regionkey = 1
SELECT n_nationkey AS id, n_name AS name
FROM nation
WHERE n_regionkey = 1
ORDER BY id;

-- Q2: Return distinct customer keys who have orders after 2018-11-25 with total price between 265000 and 280000
SELECT o_custkey FROM orders
WHERE o_orderdate > '2018-11-25'
AND o_totalprice BETWEEN 265000 and 280000
ORDER BY 1 ASC;

-- Q3: Return customer key, name, and account balance where nationkey < 2 and account balance < 0
SELECT c_custkey, c_name, c_acctbal
FROM customer
WHERE c_nationkey < 2
  AND c_acctbal < 0;

-- Q4: Return parts containing 'ivory' with suppliers from CANADA or FRANCE
SELECT p.p_name, b.s_name, b.n_name FROM part p 
left join 
(select s.*, n.n_name, ps.ps_partkey from supplier s
left join nation n
on s.s_nationkey = n.n_nationkey
left join partsupp ps 
on s.s_suppkey = ps.ps_suppkey) b
on p.p_partkey = b.ps_partkey
WHERE p.p_name LIKE '%ivory%'
AND b.n_name in ('CANADA','FRANCE')
ORDER BY 2 ASC
LIMIT 8;

-- Q5: Supplier pairs with same first 5 digits of phone and in same nation
SELECT s1.s_name AS s_name1, s2.s_name AS s_name2,
       s1.s_phone AS s_phone1, s2.s_phone AS s_phone2,
       (s1.s_acctbal + s2.s_acctbal) AS totalBalance
FROM supplier s1
JOIN supplier s2
  ON s1.s_nationkey = s2.s_nationkey
 AND LEFT(s1.s_phone,5) = LEFT(s2.s_phone,5)
 AND s1.s_suppkey < s2.s_suppkey;

-- Q6: Count, distinct nations, total balance, avg address length for selected market segments
SELECT COUNT(*) AS numCustomer,
       COUNT(DISTINCT c_nationkey) AS numCountries,
       SUM(c_acctbal) AS totalBalance,
       AVG(CHAR_LENGTH(c_address)) AS avgLength
FROM customer
WHERE c_mktsegment IN ('BUILDING','AUTOMOBILE','MACHINERY')
  AND c_nationkey < 10;

-- Q7: Stats per nation and market segment (only nations with 'A' in name)
SELECT c.c_mktsegment AS c_mktsegment,
       n.n_name AS n_name,
       COUNT(DISTINCT c.c_custkey) AS numCustomer,
       COUNT(o.o_orderkey) AS numOrders,
       MAX(c.c_acctbal) AS maxBalance,
       MIN(c.c_acctbal) AS minBalance
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
WHERE n.n_name LIKE '%A%'
GROUP BY c.c_mktsegment, n.n_name
HAVING numCustomer > 10
   AND numOrders > 180
   AND maxBalance >= 9000
ORDER BY c_mktsegment, n_name;

-- Q8: Parts with size 10–12 never shipped in any May
SELECT p.p_partkey, p.p_size
FROM part p
WHERE p.p_size BETWEEN 10 AND 12
  AND p.p_partkey NOT IN (
    SELECT DISTINCT l.l_partkey
    FROM lineitem l
    WHERE MONTH(l.l_shipdate) = 5
  )
ORDER BY p.p_size DESC, p.p_partkey DESC;

-- Q9: Customer(s) with highest account balance
SELECT c_name, c_acctbal 
FROM customer
ORDER BY 2 DESC
LIMIT 1;

-- Q10: Parts with total quantity >= 1.6 * average total quantity
SELECT CONCAT(p.p_mfgr, '-', p.p_brand) as manufacturerBrand,
p.p_partkey, 
SUM(l.l_quantity) as totalQty
FROM part p
LEFT JOIN lineitem l
ON p.p_partkey = l.l_partkey
GROUP BY manufacturerBrand, p.p_partkey
HAVING totalQty > 
(SELECT AVG(Qty) as avgQty 
FROM
(SELECT p.p_partkey, 
SUM(l.l_quantity) as Qty
FROM part p
LEFT JOIN lineitem l
ON p.p_partkey = l.l_partkey
GROUP BY p.p_partkey) tp) * 1.6
ORDER BY totalQty DESC;
