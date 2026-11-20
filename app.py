from io import BytesIO
from urllib.error import URLError
from urllib.request import Request, urlopen

import pandas as pd
import plotly.express as px
import streamlit as st


DATA_URL = (
    "https://raw.githubusercontent.com/Jono-M007/"
    "china-africa-trade-analysis/main/china_africa_trade_dataset.csv"
)
REQUIRED_COLUMNS = {
    "shipment_id",
    "export_country",
    "import_country",
    "commodity",
    "hs_code",
    "quantity",
    "declared_value_usd",
    "transport_mode",
    "departure_port",
    "arrival_port",
    "transit_time_days",
    "delay_status",
    "contract_value_usd",
    "payment_terms",
    "market_price_per_unit",
    "price_volatility_index",
    "anomaly_flag",
}
NUMERIC_COLUMNS = [
    "quantity",
    "declared_value_usd",
    "transit_time_days",
    "contract_value_usd",
    "market_price_per_unit",
    "price_volatility_index",
    "anomaly_flag",
]

st.set_page_config(
    page_title="China-Africa Trade Dashboard",
    page_icon="🌍",
    layout="wide",
)


@st.cache_data(ttl=900, show_spinner="Loading the latest dataset from GitHub...")
def load_data():
    request = Request(DATA_URL, headers={"User-Agent": "China-Africa-Trade-Dashboard"})
    with urlopen(request, timeout=30) as response:
        content = response.read()

    data = pd.read_csv(
        BytesIO(content),
        dtype={"shipment_id": "string", "hs_code": "string"},
    )
    missing_columns = REQUIRED_COLUMNS.difference(data.columns)
    if missing_columns:
        raise ValueError(
            "The GitHub CSV is missing required columns: "
            + ", ".join(sorted(missing_columns))
        )

    for column in NUMERIC_COLUMNS:
        data[column] = pd.to_numeric(data[column], errors="coerce")

    return data


def usd(value):
    return f"${value:,.0f}"


def apply_multiselect_filter(data, column, selected):
    return data[data[column].isin(selected)]


try:
    shipments = load_data()
except (URLError, TimeoutError, pd.errors.ParserError, ValueError) as error:
    st.error(f"Could not load a usable dataset from GitHub: {error}")
    st.link_button("Open source CSV on GitHub", DATA_URL)
    st.stop()

st.title("China-Africa Trade Monitoring Dashboard")
st.caption(
    "Interactive shipment analysis · Data is loaded from the repository's "
    "[GitHub CSV](%s) and cached for 15 minutes." % DATA_URL
)

with st.sidebar:
    st.header("Filters")
    if st.button("Refresh data from GitHub", width="stretch"):
        st.cache_data.clear()
        st.rerun()

    destination_options = sorted(shipments["import_country"].dropna().unique().tolist())
    commodity_options = sorted(shipments["commodity"].dropna().unique().tolist())
    transport_options = sorted(shipments["transport_mode"].dropna().unique().tolist())
    delay_options = sorted(shipments["delay_status"].dropna().unique().tolist())
    destinations = st.multiselect(
        "Import country", destination_options, default=destination_options
    )
    commodities = st.multiselect(
        "Commodity", commodity_options, default=commodity_options
    )
    transport_modes = st.multiselect(
        "Transport mode", transport_options, default=transport_options
    )
    delay_statuses = st.multiselect(
        "Delay status", delay_options, default=delay_options
    )
    anomaly_filter = st.selectbox(
        "Anomaly flag",
        ["All", "Flagged", "Not flagged"],
    )

filtered = apply_multiselect_filter(shipments, "import_country", destinations)
filtered = apply_multiselect_filter(filtered, "commodity", commodities)
filtered = apply_multiselect_filter(filtered, "transport_mode", transport_modes)
filtered = apply_multiselect_filter(filtered, "delay_status", delay_statuses)
if anomaly_filter == "Flagged":
    filtered = filtered[filtered["anomaly_flag"] == 1]
elif anomaly_filter == "Not flagged":
    filtered = filtered[filtered["anomaly_flag"] == 0]

if filtered.empty:
    st.info("No shipments match the selected filters. Adjust the sidebar filters.")
    st.stop()

shipment_count = len(filtered)
declared_total = filtered["declared_value_usd"].sum()
delayed_pct = 100 * filtered["delay_status"].eq("Delayed").mean()
anomaly_pct = 100 * filtered["anomaly_flag"].eq(1).mean()
average_transit = filtered["transit_time_days"].mean()

metric_columns = st.columns(5)
metric_columns[0].metric("Shipments", f"{shipment_count:,}")
metric_columns[1].metric("Declared value", usd(declared_total))
metric_columns[2].metric(
    "Average transit",
    f"{average_transit:.1f} days" if pd.notna(average_transit) else "N/A",
)
metric_columns[3].metric("Delayed", f"{delayed_pct:.1f}%")
metric_columns[4].metric("Anomaly flagged", f"{anomaly_pct:.1f}%")

overview_tab, trade_tab, logistics_tab, risk_tab, records_tab = st.tabs(
    ["Overview", "Trade mix", "Logistics", "Risk & pricing", "Shipment records"]
)

with overview_tab:
    country_values = (
        filtered.groupby("import_country", as_index=False)["declared_value_usd"]
        .sum()
        .sort_values("declared_value_usd", ascending=True)
    )
    commodity_values = (
        filtered.groupby("commodity", as_index=False)["declared_value_usd"]
        .sum()
        .sort_values("declared_value_usd", ascending=False)
    )
    left, right = st.columns(2)
    with left:
        st.subheader("Declared trade value by destination")
        st.plotly_chart(
            px.bar(
                country_values,
                x="declared_value_usd",
                y="import_country",
                orientation="h",
                labels={
                    "declared_value_usd": "Declared value (USD)",
                    "import_country": "Import country",
                },
                color="declared_value_usd",
                color_continuous_scale="Blues",
            ),
            width="stretch",
        )
    with right:
        st.subheader("Declared trade value by commodity")
        st.plotly_chart(
            px.bar(
                commodity_values,
                x="commodity",
                y="declared_value_usd",
                labels={
                    "commodity": "Commodity",
                    "declared_value_usd": "Declared value (USD)",
                },
                color="commodity",
            ),
            width="stretch",
        )

    st.subheader("Shipment counts by delay status")
    delay_counts = (
        filtered.groupby("delay_status", as_index=False)
        .size()
        .rename(columns={"size": "shipment_count"})
    )
    st.plotly_chart(
        px.pie(
            delay_counts,
            values="shipment_count",
            names="delay_status",
            hole=0.45,
        ),
        width="stretch",
    )

with trade_tab:
    st.subheader("Destination and commodity")
    country_commodity = filtered.pivot_table(
        index="import_country",
        columns="commodity",
        values="declared_value_usd",
        aggfunc="sum",
        fill_value=0,
    )
    st.plotly_chart(
        px.imshow(
            country_commodity,
            labels={
                "x": "Commodity",
                "y": "Import country",
                "color": "Declared value (USD)",
            },
            aspect="auto",
            color_continuous_scale="Blues",
        ),
        width="stretch",
    )

    routes = (
        filtered.groupby(["departure_port", "arrival_port"], as_index=False)
        .agg(
            shipment_count=("shipment_id", "count"),
            declared_value_usd=("declared_value_usd", "sum"),
            avg_transit_days=("transit_time_days", "mean"),
        )
        .sort_values("declared_value_usd", ascending=False)
        .head(10)
    )
    routes["declared_value_usd"] = routes["declared_value_usd"].round(2)
    routes["avg_transit_days"] = routes["avg_transit_days"].round(1)
    st.subheader("Top 10 routes by declared value")
    st.dataframe(routes, hide_index=True, width="stretch")

with logistics_tab:
    mode_stats = (
        filtered.groupby("transport_mode", as_index=False)
        .agg(
            shipment_count=("shipment_id", "count"),
            avg_transit_days=("transit_time_days", "mean"),
            delayed_count=("delay_status", lambda values: values.eq("Delayed").sum()),
        )
    )
    mode_stats["delayed_pct"] = (
        100 * mode_stats["delayed_count"] / mode_stats["shipment_count"]
    )
    mode_stats["avg_transit_days"] = mode_stats["avg_transit_days"].round(1)
    mode_stats["delayed_pct"] = mode_stats["delayed_pct"].round(1)

    left, right = st.columns(2)
    with left:
        st.subheader("Average transit by mode")
        st.plotly_chart(
            px.bar(
                mode_stats,
                x="transport_mode",
                y="avg_transit_days",
                color="transport_mode",
                labels={
                    "transport_mode": "Transport mode",
                    "avg_transit_days": "Average days",
                },
            ),
            width="stretch",
        )
    with right:
        st.subheader("Delay rate by mode")
        st.plotly_chart(
            px.bar(
                mode_stats,
                x="transport_mode",
                y="delayed_pct",
                color="delayed_pct",
                color_continuous_scale="Oranges",
                labels={
                    "transport_mode": "Transport mode",
                    "delayed_pct": "Delayed shipments (%)",
                },
            ),
            width="stretch",
        )

    st.subheader("Transit time distribution")
    st.plotly_chart(
        px.histogram(
            filtered,
            x="transit_time_days",
            color="delay_status",
            barmode="overlay",
            opacity=0.75,
            labels={
                "transit_time_days": "Transit time (days)",
                "delay_status": "Delay status",
            },
        ),
        width="stretch",
    )

with risk_tab:
    anomaly_stats = (
        filtered.groupby("commodity", as_index=False)
        .agg(
            shipment_count=("shipment_id", "count"),
            anomaly_count=("anomaly_flag", "sum"),
            avg_volatility=("price_volatility_index", "mean"),
        )
    )
    anomaly_stats["anomaly_pct"] = (
        100 * anomaly_stats["anomaly_count"] / anomaly_stats["shipment_count"]
    ).round(1)
    anomaly_stats["avg_volatility"] = anomaly_stats["avg_volatility"].round(3)

    left, right = st.columns(2)
    with left:
        st.subheader("Anomaly rate by commodity")
        st.plotly_chart(
            px.bar(
                anomaly_stats.sort_values("anomaly_pct", ascending=False),
                x="commodity",
                y="anomaly_pct",
                color="anomaly_pct",
                color_continuous_scale="Reds",
                labels={
                    "commodity": "Commodity",
                    "anomaly_pct": "Flagged shipments (%)",
                },
            ),
            width="stretch",
        )
    with right:
        st.subheader("Average price volatility")
        st.plotly_chart(
            px.bar(
                anomaly_stats,
                x="commodity",
                y="avg_volatility",
                color="avg_volatility",
                color_continuous_scale="Purples",
                labels={
                    "commodity": "Commodity",
                    "avg_volatility": "Average volatility index",
                },
            ),
            width="stretch",
        )

    st.subheader("Declared value per unit vs. market price per unit")
    price_data = filtered.loc[filtered["quantity"] > 0].copy()
    price_data["declared_per_unit"] = (
        price_data["declared_value_usd"] / price_data["quantity"]
    )
    st.caption(
        "These fields may use different units or valuation bases. Treat their "
        "comparison as exploratory, not as evidence of mispricing."
    )
    st.plotly_chart(
        px.scatter(
            price_data,
            x="market_price_per_unit",
            y="declared_per_unit",
            color="commodity",
            hover_data=["shipment_id", "import_country", "anomaly_flag"],
            log_x=True,
            log_y=True,
            labels={
                "market_price_per_unit": "Market price per unit",
                "declared_per_unit": "Declared value / quantity",
            },
        ),
        width="stretch",
    )

with records_tab:
    search = st.text_input(
        "Search shipment ID, HS code, country, commodity, or port",
        placeholder="For example: SHP00001, Nigeria, Electronics, Lagos",
    ).strip()
    records = filtered
    if search:
        search_columns = [
            "shipment_id",
            "hs_code",
            "export_country",
            "import_country",
            "commodity",
            "departure_port",
            "arrival_port",
        ]
        matches = pd.Series(False, index=records.index)
        for column in search_columns:
            matches |= records[column].astype("string").str.contains(
                search, case=False, na=False, regex=False
            )
        records = records[matches]

    st.caption(f"{len(records):,} matching shipments")
    st.download_button(
        "Download filtered shipments as CSV",
        data=records.to_csv(index=False).encode("utf-8"),
        file_name="china_africa_trade_filtered.csv",
        mime="text/csv",
    )
    st.dataframe(records, hide_index=True, width="stretch")

st.divider()
st.caption(
    "Source: [China-Africa Trade Monitoring Dataset on GitHub]"
    "(https://github.com/Jono-M007/china-africa-trade-analysis). "
    "No date field is present, so this dashboard does not show time trends."
)
