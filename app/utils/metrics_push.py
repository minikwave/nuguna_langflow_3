import requests

class MetricsPusher:
    def __init__(self, pushgateway_url="http://localhost:9091"):
        self.pushgateway_url = pushgateway_url

    def push_metrics(self, metric_name: str, value: float, labels: dict = None):
        """
        Push metrics to Prometheus PushGateway.
        """
        labels = labels or {}
        labels_str = ",".join([f'{k}="{v}"' for k, v in labels.items()])
        metric_data = f'{metric_name}{{{labels_str}}} {value}\n'
        response = requests.post(
            f"{self.pushgateway_url}/metrics/job/workflow_metrics",
            data=metric_data
        )
        if response.status_code != 202:
            raise ValueError(f"Failed to push metrics: {response.text}")

# 예제 사용
if __name__ == "__main__":
    pusher = MetricsPusher()
    pusher.push_metrics(
        metric_name="workflow_execution_time_ms",
        value=123.45,
        labels={"workflow_id": "condition-workflow", "status": "success"}
    )
