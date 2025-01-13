from app.api.services.condition_parser import ConditionParser

def test_condition_parsing():
    """
    Test condition parsing from prompt to SQL-compatible format.
    """
    parser = ConditionParser()
    prompt = "2024년 12월 소스/매체가 'google'인 정기후원 총액을 알려줘."
    conditions = parser.parse_conditions(prompt)
    expected_conditions = {"source_medium": "google", "event_date": "2024-12%"}
    assert conditions == expected_conditions, f"Condition parsing failed: {conditions}"
