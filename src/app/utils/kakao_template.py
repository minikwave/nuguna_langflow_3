def create_kakao_response(result):
    return {
        "version": "2.0",
        "template": {
            "outputs": [
                {"simpleText": {"text": f"쿼리 결과:\n{result}"}}
            ]
        }
    }
