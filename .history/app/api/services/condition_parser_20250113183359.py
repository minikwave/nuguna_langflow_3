import re

class ConditionParser:
    def parse_conditions(self, prompt: str):
        """
        Parse conditions from the prompt.
        Example: "2024년 12월 소스/매체가 'google'인 정기후원 총액을 알려줘."
        """
        conditions = {}
        if "소스/매체" in prompt:
            match = re.search(r"소스/매체가\s'(.+?)'", prompt)
            if match:
                conditions["source_medium"] = match.group(1)
        if "날짜" in prompt or "기간" in prompt:
            match = re.search(r"(\d{4}년\s\d{1,2}월)", prompt)
            if match:
                conditions["event_date"] = match.group(1).replace("년", "-").replace("월", "%")
        return conditions
