class LangflowProcessError(Exception):
    """Langflow 프로세스 관련 기본 예외"""
    pass

class ProcessStartError(LangflowProcessError):
    """프로세스 시작 실패"""
    pass

class ProcessNotFoundError(LangflowProcessError):
    """프로세스를 찾을 수 없음"""
    pass

class HealthCheckError(LangflowProcessError):
    """헬스체크 실패"""
    pass 