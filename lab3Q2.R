install.packages('RMySQL')
install.packages('RSQLite')
install.packages('dplyr')
library(DBI)
library(RMySQL)
library(RSQLite)
library(dplyr)

mysql_conn <- dbConnect(
  MySQL(),
  user = "root",
  password = "harden13YRC.",
  dbname = "tpch",
  host = "localhost"
)
cat("✅ Connected to MySQL database.\n")


query1 <- "
SELECT 
  ps.ps_partkey,
  ps.ps_suppkey,
  YEAR(l.l_shipdate) AS year,
  SUM(l.l_quantity) AS shippedQuantity
FROM partsupp ps
JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                AND ps.ps_suppkey = l.l_suppkey
GROUP BY ps.ps_partkey, ps.ps_suppkey, YEAR(l.l_shipdate)
ORDER BY ps.ps_partkey, ps.ps_suppkey, YEAR(l.l_shipdate);
"

summary_data <- dbGetQuery(mysql_conn, query1)
cat("✅ Retrieved summary data from MySQL.\n")
head(summary_data, 10)


sqlite_conn <- dbConnect(SQLite(), "tpch_local.sqlite")
cat("✅ Connected to local SQLite database.\n")


dbWriteTable(sqlite_conn, "part_summary", summary_data, overwrite = TRUE)
cat("✅ MySQL summary data written to SQLite.\n")
partsupp_data <- dbGetQuery(mysql_conn, "SELECT * FROM partsupp;")
dbWriteTable(sqlite_conn, "partsupp", partsupp_data, overwrite = TRUE)


query2 <- "
SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, s.shippedQuantity AS shipped2018
FROM partsupp p
JOIN part_summary s 
  ON p.ps_partkey = s.ps_partkey AND p.ps_suppkey = s.ps_suppkey
WHERE s.year = 2018
  AND p.ps_availqty < s.shippedQuantity;
"

low_inventory <- dbGetQuery(sqlite_conn, query2)
cat("✅ Retrieved parts with insufficient inventory.\n")
head(low_inventory, 5)


subset_data <- summary_data %>%
  filter(ps_partkey == 217, ps_suppkey == 18) %>%
  arrange(year)

if (nrow(subset_data) >= 5) {
  model <- lm(shippedQuantity ~ year, data = subset_data)
  pred_2019 <- predict(model, newdata = data.frame(year = 2019))
  cat("\n📈 Predicted shippedQuantity for (partkey=217, suppkey=18) in 2019:", pred_2019, "\n")
} else {
  cat("\n⚠️ Not enough data for linear regression.\n")
}

query3 <- "
SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, s.shippedQuantity AS shipped2018,
       (CAST(p.ps_availqty AS FLOAT) / s.shippedQuantity) AS overstockRatio
FROM partsupp p
JOIN part_summary s 
  ON p.ps_partkey = s.ps_partkey AND p.ps_suppkey = s.ps_suppkey
WHERE s.year = 2018
  AND s.shippedQuantity >= 6
ORDER BY overstockRatio DESC
LIMIT 10;
"

overstock <- dbGetQuery(sqlite_conn, query3)
cat("\n🔥 Top 10 overstocked products (relative to 2018 sales):\n")
print(overstock)


dbDisconnect(mysql_conn)
dbDisconnect(sqlite_conn)
cat("\n✅ All database connections closed.\n")
