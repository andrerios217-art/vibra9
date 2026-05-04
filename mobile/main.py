
@app.get("/me/export")
def export_my_data(user: Dict[str, Any] = Depends(get_current_user)):
    conn = get_connection()

    assessment_rows = conn.execute(
        """
        SELECT *
        FROM assessments
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    recommendation_rows = conn.execute(
        """
        SELECT *
        FROM recommendations
        WHERE user_id = ?
        ORDER BY created_at DESC
        """,
        (user["id"],)
    ).fetchall()

    conn.close()

    assessments = []

    for row in assessment_rows:
        item = dict(row)
        item["dimensions"] = json.loads(item["dimensions_json"])
        del item["dimensions_json"]
        assessments.append(item)

    recommendations = []

    for row in recommendation_rows:
        item = dict(row)
        item["daily_actions"] = json.loads(item["daily_actions_json"])
        del item["daily_actions_json"]
        recommendations.append(item)

    return {
        "user": {
            "id": user["id"],
            "name": user["name"],
            "email": user["email"],
            "created_at": user["created_at"],
            "subscription_active": bool(user["subscription_active"]),
            "subscription_source": user["subscription_source"],
        },
        "assessments": assessments,
        "recommendations": recommendations,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "note": "Exportação de dados do usuário para transparência e portabilidade."
    }
