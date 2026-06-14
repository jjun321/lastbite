import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lastbite.settings")

app = Celery("lastbite")

# Redis 등 broker/backend 관련 설정은 settings.py의 CELERY_* 값을 그대로 사용
app.config_from_object("django.conf:settings", namespace="CELERY")

# 각 app의 tasks.py를 자동으로 탐색하여 등록
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    print(f"Request: {self.request!r}")
