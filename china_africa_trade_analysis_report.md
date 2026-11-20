# China-Africa Trade SQL Analysis

## Executive summary

- The dataset contains **10,000 shipment records** and **10,000 unique shipment IDs**.
- Total declared shipment value is **$778,793,365.00**.
- The leading import destination is **Nigeria**, with $116,285,822.00 in declared trade across 1,485 shipments.
- The leading commodity by declared value is **Minerals**, with $159,006,896.00.
- **2,079 shipments (20.79%)** are flagged as delayed.
- Contract values are above declared values in **49.86%** of shipments; the average contract-minus-declared difference is $0.52.
- Average declared value per unit is **$70.68** versus $1509.63 for market price per unit, a -84.92% average discrepancy.
- **676 shipments** are both delayed and anomalous, representing $53,650,468.00 in declared value.

## Import-country concentration

| Import country | Shipments | Declared value (USD) |
| --- | --- | --- |
| Nigeria | 1485 | 116285822.0 |
| Tanzania | 1458 | 114407645.0 |
| Ethiopia | 1439 | 113550682.0 |
| Kenya | 1463 | 112267995.0 |
| Ghana | 1377 | 107916545.0 |
| South Africa | 1368 | 107233566.0 |
| Egypt | 1410 | 107131110.0 |

## Commodity concentration

| Commodity | Shipments | Declared value (USD) |
| --- | --- | --- |
| Minerals | 2010 | 159006896.0 |
| Machinery | 2030 | 157118466.0 |
| Electronics | 2032 | 156768220.0 |
| Agricultural | 2018 | 156762183.0 |
| Textiles | 1910 | 149137600.0 |

## Logistics by transport mode

| Transport mode | Shipments | Average transit days | Delayed % |
| --- | --- | --- | --- |
| Rail | 2551 | 21.39 | 22.07 |
| Air | 2507 | 21.32 | 20.42 |
| Ship | 2503 | 20.77 | 20.5 |
| Road | 2439 | 20.84 | 20.13 |

## Delay status

| Status | Shipments | Percentage |
| --- | --- | --- |
| Delayed | 2079 | 20.79 |
| On-Time | 7921 | 79.21 |

## Anomaly rates by commodity

| Commodity | Shipments | Anomaly % |
| --- | --- | --- |
| Textiles | 1910 | 28.74 |
| Minerals | 2010 | 27.86 |
| Agricultural | 2018 | 27.65 |
| Machinery | 2030 | 26.01 |
| Electronics | 2032 | 25.94 |

## Payment terms

| Payment term | Shipments | Declared value (USD) |
| --- | --- | --- |
| Prepaid | 3363 | 258221890.0 |
| Credit | 3337 | 261066278.0 |
| On Delivery | 3300 | 259505197.0 |

## Top 10 routes by declared value

| Departure port | Arrival port | Shipments | Declared value (USD) |
| --- | --- | --- | --- |
| Guangzhou | Mombasa | 339 | 26542926.0 |
| Shanghai | Durban | 307 | 25167776.0 |
| Shenzhen | Mombasa | 314 | 24370852.0 |
| Beijing | Dar es Salaam | 295 | 24278415.0 |
| Qingdao | Dar es Salaam | 304 | 24130361.0 |
| Beijing | Tema | 309 | 23946529.0 |
| Shanghai | Lagos | 294 | 23674159.0 |
| Qingdao | Cairo | 289 | 23594122.0 |
| Beijing | Durban | 291 | 23347250.0 |
| Qingdao | Mombasa | 282 | 23221866.0 |

## Commodity volatility

| Commodity | Average volatility index |
| --- | --- |
| Agricultural | 0.2566 |
| Machinery | 0.2553 |
| Textiles | 0.2552 |
| Minerals | 0.2539 |
| Electronics | 0.2501 |

## Reproduce the analysis

Run [china_africa_trade_analysis.sql](china_africa_trade_analysis.sql) after loading the CSV into a table named `china_africa_trade`. The SQL includes data overview, quality checks, country and commodity rankings, logistics, pricing, contracts, anomalies, HS-code concentration, outliers, and Pareto analysis.