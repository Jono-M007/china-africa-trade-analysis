# China-Africa Trade Monitoring Dataset: SQL Analysis

An exploratory analysis of shipment-level trade data from China to African
destinations. It includes a Streamlit dashboard, the source CSV,
SQLite-compatible SQL queries, and a report generated from the dataset.

## Interactive dashboard

[![Deploy to Streamlit](https://static.streamlit.io/badges/streamlit_badge_black_white.svg)](https://share.streamlit.io/deploy?repository=Jono-M007%2Fchina-africa-trade-analysis&branch=main&mainModule=app.py)

The dashboard downloads the CSV directly from this repository's `main` branch
on GitHub, caches it for 15 minutes, and offers a manual refresh button. It
includes destination, commodity, transport, delay, and anomaly filters;
interactive trade, logistics, and risk charts; and searchable, downloadable
shipment records.

**First-time setup:** select the repository, `main` branch, and `app.py` in
Streamlit Community Cloud, then deploy. The badge above opens the deployment
flow; after deployment, Streamlit provides the live app URL.

To run it locally:

```bash
python -m pip install -r requirements.txt
streamlit run app.py
```

## Repository contents

| File | Description |
| --- | --- |
| [`china_africa_trade_dataset.csv`](china_africa_trade_dataset.csv) | Shipment-level source data (10,000 rows) |
| [`app.py`](app.py) | Streamlit dashboard; reads the CSV from GitHub |
| [`requirements.txt`](requirements.txt) | Python dependencies for the dashboard |
| [`china_africa_trade_analysis.sql`](china_africa_trade_analysis.sql) | 27 commented SQL questions and analysis queries |
| [`china_africa_trade_analysis_report.md`](china_africa_trade_analysis_report.md) | Detailed tabular analysis results |

## Key findings

- **10,000 shipments** with **10,000 unique shipment IDs** and **$778.8 million**
  in total declared value.
- **Nigeria** is the leading destination by declared value, at **$116.3 million**
  across 1,485 shipments.
- **Minerals** is the highest-value commodity category, contributing **$159.0
  million** in declared shipment value.
- **2,079 shipments (20.79%)** are marked delayed. Rail has the highest
  delay rate among the listed transport modes (**22.07%**).
- **Textiles** has the highest anomaly-flag rate by commodity (**28.74%**).
- **676 shipments** are both delayed and anomaly-flagged, with **$53.7 million**
  in associated declared value.
- Contract values exceed declared values in **49.86%** of records; the average
  contract-minus-declared difference is only **$0.52**.

## Important interpretation note

There is no date or year column, so the dataset cannot support time-series or
year-over-year trend analysis. The market-price-per-unit and declared-value-per-
quantity fields differ substantially in scale on average; confirm their units,
commodity comparability, and calculation basis before interpreting their
difference as a pricing anomaly. The anomaly flag is supplied in the source
data; the analysis describes its distribution and does not infer its meaning.

## Run the SQL analysis

The queries target SQLite and expect a table named `china_africa_trade`.
Using the SQLite command-line tool, create the table from the CSV header and
import the records with CSV mode enabled:

```text
sqlite3 trade.db
```

```sql
.mode csv
.import china_africa_trade_dataset.csv china_africa_trade
.read china_africa_trade_analysis.sql
```

When importing into a table that does not exist, the SQLite CLI uses the CSV
header for column names. For stricter type handling, create the table first with
numeric affinity for the quantity, value, transit, exchange-rate, volatility,
and flag columns, then import the file with `.import --skip 1`.

## Columns

| Column | Description |
| --- | --- |
| `shipment_id` | Shipment identifier |
| `export_country`, `import_country` | Origin and destination countries |
| `commodity`, `hs_code` | Commodity category and HS code |
| `quantity`, `declared_value_usd`, `contract_value_usd` | Shipment quantity and values |
| `transport_mode`, `departure_port`, `arrival_port` | Shipment route and transport |
| `transit_time_days`, `delay_status` | Transit duration and delay classification |
| `payment_terms` | Payment arrangement |
| `currency_exchange_rate` | Exchange-rate field as supplied in the dataset |
| `market_price_per_unit`, `price_volatility_index` | Market-price indicators |
| `anomaly_flag` | Source-provided anomaly indicator (0/1) |

## Analysis coverage

The SQL file asks and answers questions about dataset quality, destination and
commodity rankings, country-commodity pairs, transport and delay performance,
port and route activity, payment terms, contract-versus-declared values,
market-price comparisons, price volatility, anomaly rates, HS-code
concentration, high-value outliers, and destination concentration.
