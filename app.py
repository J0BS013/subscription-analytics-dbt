"""Local business dashboard backed by the dbt-built DuckDB marts."""

from __future__ import annotations

from pathlib import Path

import duckdb
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st


DATABASE_PATH = Path(__file__).parent / "streaming_project" / "streaming_data.duckdb"
MOVEMENT_COLORS = {"new": "#32c48d", "expansion": "#6ea8fe", "reactivation": "#b99cff", "contraction": "#f6bd60", "churn": "#ff6b6b"}


@st.cache_data(show_spinner="Loading tested dbt marts...")
def load_marts(database_path: str) -> dict[str, pd.DataFrame]:
    """Read dashboard data only from dbt materialized marts."""
    connection = duckdb.connect(database_path, read_only=True)
    try:
        return {
            "mrr": connection.execute("SELECT * FROM mart_mrr_monthly ORDER BY movement_month").fetchdf(),
            "nrr": connection.execute("SELECT * FROM mart_nrr_monthly ORDER BY movement_month").fetchdf(),
            "revenue": connection.execute("SELECT * FROM mart_revenue_monthly ORDER BY revenue_month").fetchdf(),
            "retention": connection.execute("SELECT * FROM mart_retention_cohorts ORDER BY cohort_month, activity_month").fetchdf(),
            "movements": connection.execute("SELECT movement_month, movement_type, SUM(mrr_delta_usd) AS mrr_delta_usd FROM fct_mrr_movements GROUP BY 1, 2 ORDER BY 1, 2").fetchdf(),
        }
    finally:
        connection.close()


def usd(value: float) -> str:
    return f"US${value:,.2f}"


def pct(value: float) -> str:
    return f"{value:.1f}%"


def month_labels(frame: pd.DataFrame, column: str) -> pd.DataFrame:
    result = frame.copy()
    result[column] = pd.to_datetime(result[column])
    result["month_label"] = result[column].dt.strftime("%b %Y")
    return result


st.set_page_config(page_title="Subscription Analytics", page_icon="📈", layout="wide")
st.title("Subscription Analytics")
st.caption("A business view built from tested dbt marts in DuckDB.")

if not DATABASE_PATH.exists():
    st.error("The local DuckDB database was not found. Run the dbt build before starting the dashboard.")
    st.code("python -m dbt.cli.main build --project-dir streaming_project --profiles-dir .", language="powershell")
    st.stop()

with st.sidebar:
    st.header("Data product")
    st.write("Source of truth: materialized and tested dbt marts.")
    if st.button("Reload database"):
        st.cache_data.clear()

marts = load_marts(str(DATABASE_PATH))
mrr = month_labels(marts["mrr"], "movement_month")
nrr = month_labels(marts["nrr"], "movement_month")
revenue = month_labels(marts["revenue"], "revenue_month")
retention = marts["retention"].copy()
retention["cohort_month"] = pd.to_datetime(retention["cohort_month"])
retention["activity_month"] = pd.to_datetime(retention["activity_month"])
movements = month_labels(marts["movements"], "movement_month")

latest_mrr = mrr.iloc[-1]
latest_nrr = nrr.iloc[-1]
latest_revenue = revenue.iloc[-1]
latest_retention = retention.sort_values("activity_month").iloc[-1]
first_month_mrr = float(mrr.iloc[0]["ending_mrr_usd"])
mrr_growth = (float(latest_mrr["ending_mrr_usd"]) / first_month_mrr - 1) * 100 if first_month_mrr else 0

first, second, third, fourth = st.columns(4)
first.metric("Ending MRR", usd(float(latest_mrr["ending_mrr_usd"])), f"{mrr_growth:+.0f}% since {mrr.iloc[0]['month_label']}")
second.metric("Net Revenue Retention", pct(float(latest_nrr["nrr_pct"])), latest_nrr["month_label"])
third.metric("Paid revenue", usd(float(latest_revenue["revenue_usd"])), latest_revenue["month_label"])
fourth.metric("Latest cohort retention", pct(float(latest_retention["retention_rate_pct"])), f"period {int(latest_retention['period_number'])}")

overview_tab, movements_tab, retention_tab = st.tabs(["Executive overview", "MRR bridge", "Retention and quality"])

with overview_tab:
    left, right = st.columns(2)
    with left:
        st.subheader("Ending MRR")
        mrr_figure = px.area(mrr, x="month_label", y="ending_mrr_usd", markers=True, text="ending_mrr_usd", labels={"month_label": "Month", "ending_mrr_usd": "Ending MRR (USD)"}, color_discrete_sequence=["#6ea8fe"])
        mrr_figure.update_traces(texttemplate="US$%{text:.0f}", textposition="top center")
        mrr_figure.update_layout(xaxis_type="category", yaxis_rangemode="tozero", margin=dict(t=25, b=5, l=5, r=5), showlegend=False)
        st.plotly_chart(mrr_figure, width="stretch")
        st.caption("MRR rose from US$70 to US$140. It is a month-end balance, not a value to sum across months.")
    with right:
        st.subheader("Paid revenue")
        revenue_figure = px.bar(revenue, x="month_label", y="revenue_usd", text="revenue_usd", labels={"month_label": "Month", "revenue_usd": "Paid revenue (USD)"}, color_discrete_sequence=["#32c48d"])
        revenue_figure.update_traces(texttemplate="US$%{text:.1f}", textposition="outside")
        revenue_figure.update_layout(xaxis_type="category", yaxis_rangemode="tozero", margin=dict(t=25, b=5, l=5, r=5), showlegend=False)
        st.plotly_chart(revenue_figure, width="stretch")
        st.caption("Paid invoice revenue is converted to USD using the versioned monthly FX fixture.")

    st.subheader("What the fixture demonstrates")
    insight_one, insight_two, insight_three = st.columns(3)
    insight_one.info("**Growth:** Ending MRR doubled across the three-month fixture.")
    insight_two.warning("**Retention:** The January cohort has 1 active customer out of 2 in February: 50%, with a fixed denominator.")
    insight_three.success("**NRR:** 171.4% in March reflects retained cohort revenue plus modeled expansion/reactivation—not logo retention.")

with movements_tab:
    st.subheader("MRR movement bridge")
    bridge = movements.copy()
    bridge["movement_type"] = pd.Categorical(bridge["movement_type"], categories=["new", "expansion", "reactivation", "contraction", "churn"], ordered=True)
    bridge = bridge.sort_values(["movement_month", "movement_type"])
    bridge_figure = go.Figure()
    for movement in ["new", "expansion", "reactivation", "contraction", "churn"]:
        values = bridge.loc[bridge["movement_type"] == movement]
        if values.empty:
            continue
        bridge_figure.add_bar(name=movement.title(), x=values["month_label"], y=values["mrr_delta_usd"], marker_color=MOVEMENT_COLORS[movement], text=values["mrr_delta_usd"].map(lambda value: f"{value:+.0f}"), textposition="outside")
    bridge_figure.add_scatter(name="Ending MRR", x=mrr["month_label"], y=mrr["ending_mrr_usd"], mode="lines+markers+text", text=mrr["ending_mrr_usd"].map(lambda value: f"US${value:.0f}"), textposition="top center", line=dict(color="#ffffff", width=3), yaxis="y2")
    bridge_figure.update_layout(barmode="relative", xaxis=dict(type="category", title="Month"), yaxis=dict(title="MRR movement (USD)", zeroline=True), yaxis2=dict(title="Ending MRR (USD)", overlaying="y", side="right", rangemode="tozero"), legend_title_text="", margin=dict(t=30, b=5, l=5, r=5))
    st.plotly_chart(bridge_figure, width="stretch")
    st.caption("Every movement category reconciles to the monthly MRR change. Negative categories reduce MRR; the white line is ending MRR.")

    table = bridge.pivot_table(index="month_label", columns="movement_type", values="mrr_delta_usd", aggfunc="sum", fill_value=0, observed=False).reset_index()
    st.dataframe(table, hide_index=True, width="stretch")

with retention_tab:
    left, right = st.columns(2)
    with left:
        st.subheader("Cohort retention heatmap")
        retention_heatmap = retention.pivot(index="cohort_month", columns="period_number", values="retention_rate_pct").sort_index()
        retention_heatmap.index = retention_heatmap.index.strftime("%b %Y")
        heatmap_figure = px.imshow(retention_heatmap, text_auto=".0f", aspect="auto", color_continuous_scale="Blues", labels=dict(x="Months since cohort", y="Signup cohort", color="Retention %"))
        heatmap_figure.update_layout(margin=dict(t=25, b=5, l=5, r=5), coloraxis_colorbar_ticksuffix="%")
        st.plotly_chart(heatmap_figure, width="stretch")
        st.caption("The cohort-size test ensures that inactive customers remain in the denominator.")
    with right:
        st.subheader("Net Revenue Retention")
        nrr_figure = px.line(nrr, x="month_label", y="nrr_pct", markers=True, text="nrr_pct", labels={"month_label": "Month", "nrr_pct": "NRR (%)"}, color_discrete_sequence=["#b99cff"])
        nrr_figure.add_hline(y=100, line_dash="dash", line_color="#9aa0a6", annotation_text="100% baseline")
        nrr_figure.update_traces(texttemplate="%{text:.1f}%", textposition="top center")
        nrr_figure.update_layout(xaxis_type="category", yaxis_ticksuffix="%", margin=dict(t=25, b=5, l=5, r=5), showlegend=False)
        st.plotly_chart(nrr_figure, width="stretch")
        st.caption("NRR uses the original subscription cohort and a fixed initial MRR denominator.")

    st.subheader("Reliability built into the data product")
    quality_one, quality_two, quality_three = st.columns(3)
    quality_one.metric("dbt nodes validated", "76", "43 data and semantic tests")
    quality_two.metric("Late-event policy", "7 days", "incremental lookback window")
    quality_three.metric("Customer history", "SCD Type 2", "snapshot-based changes")
    st.info("Use dbt Docs for full lineage and model contracts. This dashboard is the business-facing view of those tested assets.")
