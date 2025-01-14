import random

def generate_questions():
    """
    테이블 스키마를 기반으로 다양한 질문 생성
    """
    base_questions = [
        "2024년 평균 {metric1}와 {metric2}을 알려줘.",
        "2024년 12월 {dimension} 기준 {metric}이 가장 높은 소스는 어디야?",
        "{metric}을 기준으로 2024년 {dimension1}과 {dimension2}의 결과를 알려줘.",
    ]

    # 테이블과 스키마 정보
    table_schemas = {
        "source_report": {
            "dimensions": ["event_date", "source_medium", "campaign"],
            "metrics": ["regular_donation", "temporary_donation", "session"],
        },
        "page_report": {
            "dimensions": ["event_date", "page_title"],
            "metrics": ["pageview", "average_engagement_time_per_user"],
        },
        "event_report": {
            "dimensions": ["event_date", "event_name", "page_location"],
            "metrics": ["value", "engagement_time_msec"],
        },
    }

    # 질문 생성
    questions = []
    for table, schema in table_schemas.items():
        for base_question in base_questions:
            dimension = random.choice(schema["dimensions"])
            metric = random.choice(schema["metrics"])
            question = base_question.format(
                dimension=dimension,
                metric=metric,
                metric1=random.choice(schema["metrics"]),
                metric2=random.choice(schema["metrics"]),
            )
            questions.append({"table": table, "question": question})

    return questions
