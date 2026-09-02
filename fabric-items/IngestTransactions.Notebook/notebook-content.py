# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "11111111-1111-4111-8111-111111111111",
# META       "default_lakehouse_name": "BankingLakehouse",
# META       "default_lakehouse_workspace_id": "22222222-2222-4222-8222-222222222222",
# META       "known_lakehouses": [
# META         {
# META           "id": "11111111-1111-4111-8111-111111111111"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

from pyspark.sql import functions as F

try:
    config = notebookutils.variableLibrary.getLibrary("BankingConfig")
    environment = config.ENVIRONMENT
except Exception:
    # Allows interactive authoring before the Variable Library is first deployed.
    environment = "DEV"

SEED = 20260816
ACCOUNT_COUNT = 500
TRANSACTION_COUNT = 5000

print(f"Generating deterministic synthetic data for {environment}; seed={SEED}")

# CELL ********************

accounts = (
    spark.range(1, ACCOUNT_COUNT + 1)
    .withColumnRenamed("id", "account_id")
    .withColumn(
        "customer_segment",
        F.element_at(F.array(F.lit("Retail"), F.lit("SME"), F.lit("Private")),
                     (F.pmod(F.col("account_id"), F.lit(3)) + 1).cast("int")),
    )
    .withColumn("open_date", F.date_add(F.lit("2020-01-01"), F.pmod(F.col("account_id") * 13, F.lit(1460)).cast("int")))
    .withColumn("current_balance", F.round(F.lit(1000.0) + F.pmod(F.col("account_id") * 7919, F.lit(250000)), 2))
    .withColumn("environment", F.lit(environment))
)

transactions = (
    spark.range(1, TRANSACTION_COUNT + 1)
    .withColumnRenamed("id", "transaction_id")
    .withColumn("account_id", F.pmod(F.col("transaction_id") * 37, F.lit(ACCOUNT_COUNT)) + 1)
    .withColumn("transaction_ts", F.timestampadd("MINUTE", -(F.col("transaction_id") * 17), F.current_timestamp()))
    .withColumn("amount", F.round((F.pmod(F.col("transaction_id") * 104729, F.lit(200000)) - 100000) / 100.0, 2))
    .withColumn(
        "channel",
        F.element_at(F.array(F.lit("ACH"), F.lit("CARD"), F.lit("WIRE"), F.lit("ATM")),
                     (F.pmod(F.col("transaction_id"), F.lit(4)) + 1).cast("int")),
    )
    .withColumn("is_flagged", (F.abs(F.col("amount")) >= F.lit(900.0)) | (F.col("channel") == F.lit("WIRE")))
    .withColumn("environment", F.lit(environment))
)

accounts.write.mode("overwrite").format("delta").saveAsTable("accounts")
transactions.write.mode("overwrite").format("delta").saveAsTable("transactions")

assert accounts.count() == ACCOUNT_COUNT
assert transactions.count() == TRANSACTION_COUNT
allowed_account_columns = {
    "account_id",
    "customer_segment",
    "open_date",
    "current_balance",
    "environment",
}
assert set(accounts.columns) == allowed_account_columns

display(transactions.groupBy("channel", "is_flagged").agg(F.count("*").alias("transaction_count")))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
