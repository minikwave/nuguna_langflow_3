import requests

def test_report_generation():
    """
    Test report generation for specific dimensions, metrics, and filters.
    """
    response = requests.post("http://localhost:8000/report-data", json={
        "report_type": "source_report",
        "dimensions": ["source_medium"],
        "metrics": ["regular_donation"],
        "filters": {"event_date": "2024-12"}
    })
    assert response.status_code == 200, "Report generation failed"
    assert "query_result" in response.json(), "Query result missing in report"
    print("Report generation test passed!")
