# Read-only financial query tools for the FinTrack AI assistant.
#
# These tools allow the ADK agent to query the signed-in user's live financial data
# from Supabase. All tools are read-only and strictly scoped to tool_context.user_id.

from datetime import datetime
from google.adk.tools.tool_context import ToolContext
from app.core.supabase_client import get_supabase

# Parse ISO date strings returned by Supabase, converting UTC Z suffixes.
def _parse_date(value: str) -> datetime:
    if value.endswith("Z"):
        value = value.replace("Z", "+00:00")
    return datetime.fromisoformat(value)

# Fetch all transaction records for a specific user ID with category names.
# Args: user_id (str)
# Returns: List of transaction records containing joined category details.
def db_rows(user_id: str) -> list[dict]:
    return (
        get_supabase()
        .table("transactions")
        .select("*, categories(name)")
        .eq("user_id", user_id)
        .execute()
        .data
    )

# Calculate income, expenses, net savings, and category breakdown for a month.
# Use this tool to answer questions about monthly income, spending, or net savings.
# Args: month (1-12), year (e.g. 2026), tool_context (ToolContext)
# Returns: Dictionary containing monthly financial totals and spending by category in MYR.
def get_financial_summary(month: int, year: int, tool_context: ToolContext) -> dict:
    db = get_supabase()
    rows = (
        db.table("transactions")
        .select("*, categories(name)")
        .eq("user_id", tool_context.user_id)
        .execute()
        .data
    )

    total_income = 0.0
    total_expenses = 0.0
    by_category: dict[str, float] = {}

    for tx in rows:
        d = _parse_date(tx["transaction_date"])
        if d.month != month or d.year != year:
            continue
        amount = float(tx["amount"])
        if tx["type"] == "income":
            total_income += amount
        else:
            category = (tx.get("categories") or {}).get("name") or "Uncategorized"
            total_expenses += amount
            by_category[category] = by_category.get(category, 0.0) + amount

    ranked = dict(sorted(by_category.items(), key=lambda kv: kv[1], reverse=True))
    return {
        "month": month,
        "year": year,
        "currency": "MYR",
        "total_income": round(total_income, 2),
        "total_expenses": round(total_expenses, 2),
        "net": round(total_income - total_expenses, 2),
        "spending_by_category": {k: round(v, 2) for k, v in ranked.items()},
    }

# Retrieve the user's most recent transactions sorted newest first.
# Use this tool to answer questions about recent purchases or specific items.
# Args: limit (1-50), tool_context (ToolContext)
# Returns: Dictionary containing the formatted transaction list.
def get_recent_transactions(limit: int, tool_context: ToolContext) -> dict:
    limit = max(1, min(limit, 50))
    rows = db_rows(tool_context.user_id)
    rows.sort(key=lambda t: t["transaction_date"], reverse=True)

    items = []
    for tx in rows[:limit]:
        items.append(
            {
                "date": tx["transaction_date"][:10],
                "type": tx["type"],
                "amount": round(float(tx["amount"]), 2),
                "category": (tx.get("categories") or {}).get("name") or "Uncategorized",
                "title": tx.get("title"),
            }
        )
    return {"count": len(items), "currency": "MYR", "transactions": items}

# Compare category budgets against actual spending for a specific month.
# Use this tool to inform users whether they are over or under budget per category.
# Args: month (1-12), year (e.g. 2026), tool_context (ToolContext)
# Returns: Dictionary containing category budget limits, actual spending, and remainders.
def get_budget_status(month: int, year: int, tool_context: ToolContext) -> dict:
    db = get_supabase()
    user_id = tool_context.user_id

    budgets = (
        db.table("budgets")
        .select("*, categories(name)")
        .eq("user_id", user_id)
        .eq("month", month)
        .eq("year", year)
        .execute()
        .data
    )

    spent: dict[str, float] = {}
    for tx in db_rows(user_id):
        if tx["type"] != "expense":
            continue
        d = _parse_date(tx["transaction_date"])
        if d.month != month or d.year != year:
            continue
        category = (tx.get("categories") or {}).get("name") or "Uncategorized"
        spent[category] = spent.get(category, 0.0) + float(tx["amount"])

    items = []
    for b in budgets:
        category = (b.get("categories") or {}).get("name") or "Uncategorized"
        limit = float(b["amount_limit"])
        used = round(spent.get(category, 0.0), 2)
        items.append(
            {
                "category": category,
                "limit": round(limit, 2),
                "spent": used,
                "remaining": round(limit - used, 2),
                "percent_used": round((used / limit * 100) if limit else 0.0, 1),
                "over_budget": used > limit,
            }
        )
    return {"month": month, "year": year, "currency": "MYR", "budgets": items}
