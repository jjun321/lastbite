# 매장 영업시간 종료 시 자동 품절 처리를 위한 Celery Beat 주기 작업 등록

from django.db import migrations


TASK_NAME = "auto-soldout-closed-stores"
TASK_PATH = "store.tasks.auto_soldout_all_closed_stores"
INTERVAL_MINUTES = 5


def create_periodic_task(apps, schema_editor):
    IntervalSchedule = apps.get_model("django_celery_beat", "IntervalSchedule")
    PeriodicTask = apps.get_model("django_celery_beat", "PeriodicTask")

    schedule, _ = IntervalSchedule.objects.get_or_create(
        every=INTERVAL_MINUTES,
        period=IntervalSchedule.MINUTES,
    )

    PeriodicTask.objects.get_or_create(
        name=TASK_NAME,
        defaults={
            "task": TASK_PATH,
            "interval": schedule,
            "enabled": True,
        },
    )


def remove_periodic_task(apps, schema_editor):
    PeriodicTask = apps.get_model("django_celery_beat", "PeriodicTask")
    PeriodicTask.objects.filter(name=TASK_NAME).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("store", "0009_storeworkingtime_end_day_offset"),
        ("django_celery_beat", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_periodic_task, remove_periodic_task),
    ]
