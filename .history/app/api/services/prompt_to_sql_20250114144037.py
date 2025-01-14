import json

def map_prompt_to_sql(prompt: str, rules_path: str = "config/prompt_rules.json"):
    """
    Prompt를 기반으로 SQL을 생성
    Args:
        prompt (str): 사용자 질문
        rules_path (str): Prompt Rules JSON 경로

    Returns:
        dict: 매핑된 SQL 쿼리 및 테이블 정보
    """
    with open(rules_path, "r") as f:
        rules = json.load(f)["rules"]

    for rule in rules:
        if rule["prompt"] in prompt:
            return {
                "table": rule["table"],
                "query": rule["example_query"],
                "dimension": rule["dimension"],
                "metric": rule["metric"],
                "response_format": rule["response_format"],
            }

    return {"error": "Prompt not found in rules"}
