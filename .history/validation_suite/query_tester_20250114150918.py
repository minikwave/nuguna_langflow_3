from app.api.services.prompt_handler import PromptHandler
from validation_suite.question_generator import generate_questions

def test_generated_questions():
    """
    생성된 질문을 Langflow 및 VectorDB를 통해 실행하고 결과 검증
    """
    questions = generate_questions()
    handler = PromptHandler()

    for question in questions:
        print(f"Testing question: {question['question']}")
        results = handler.handle_prompt(question["question"])

        # Langflow 결과 출력
        if "langflow_result" in results:
            print("Langflow Result:", results["langflow_result"])

        # VectorDB 결과 출력
        if "vectordb_results" in results:
            print("VectorDB Results:", results["vectordb_results"])

        print("\n")
