"""
ml_server/settings.py
DBSCAN 기반 추천 전용 Django 서버 설정
메인 서버(backend/)와 동일한 DB를 읽기 전용으로 공유
"""

from pathlib import Path
from dotenv import load_dotenv
from decouple import config
import os

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config("ML_SECRET_KEY")

DEBUG = config("DEBUG", default=True, cast=bool)

ALLOWED_HOSTS = [
    "localhost",
    "127.0.0.1",
    "10.0.2.2",
    ".ngrok-free.app",
    ".ngrok-free.dev",
    '101.79.19.70',
    'lastbite.o-r.kr'
]

INSTALLED_APPS = [
    "django.contrib.contenttypes",  # recommend 앱 모델에 필요
    "django.contrib.auth",          # managed=False 모델 참조 시 필요
    "rest_framework",
    "recommend",
    "anomaly",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.middleware.common.CommonMiddleware",
]

ROOT_URLCONF = "ml_server.urls"

WSGI_APPLICATION = "ml_server.wsgi.application"

# ── DB: 메인 서버와 동일한 PostgreSQL, 마이그레이션은 하지 않음 ────────────────
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME":     os.getenv("DJANGO_DB_NAME"),
        "USER":     os.getenv("DJANGO_DB_USER"),
        "PASSWORD": os.getenv("DJANGO_DB_PASSWORD"),
        "HOST":     os.getenv("DJANGO_DB_HOST"),
        "PORT":     os.getenv("DJANGO_DB_PORT", "5432"),
        "OPTIONS": {
            # 읽기 전용 트랜잭션으로 실수로 인한 쓰기 방지
            "options": "-c default_transaction_read_only=on",
        },
    }
}

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [],   # JWT 불필요 — 내부 API 키로 인증
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",
    ],
}

LANGUAGE_CODE = "ko-kr"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# ── 내부 API 키: 메인 서버만 호출 가능하도록 ─────────────────────────────────
ML_INTERNAL_API_KEY = config("ML_INTERNAL_API_KEY", default="_qRqqEaQcs5ZIJHAeNAKxfSpRy4YUjdvV")

# ── DBSCAN 파라미터 ───────────────────────────────────────────────────────────
DBSCAN_EPS_KM      = 0.5   # 군집 반경 (km)
DBSCAN_MIN_SAMPLES = 3     # 군집 형성 최소 포인트 수
SEARCH_RADIUS_KM   = 10.0   # 군집 중심 기준 매장 탐색 반경 (km) 테스트 시 변경 필요

# ── 가중치 ────────────────────────────────────────────────────────────────────
RECOMMEND_ALPHA = 0.5   # 거리 가중치
RECOMMEND_BETA  = 0.2   # 조회수 가중치
RECOMMEND_GAMMA = 0.3   # 할인율 가중치

# ── Isolation Forest 파라미터 ─────────────────────────────────────────────────
IF_CONTAMINATION = 0.1   # 이상치 비율 (전체 데이터의 10% 이상치로 가정)
IF_N_ESTIMATORS  = 100   # 트리 개수
IF_RANDOM_STATE  = 42    # 재현성 보장
IF_MIN_SAMPLES   = 5     # 학습 최소 데이터 수 (미만이면 탐지 생략)

# ── 연관 규칙 파라미터 ────────────────────────────────────────────────────────
AR_MIN_SUPPORT    = 0.05   # FP-Growth 최소 지지도 (전체 사용자 중 5% 이상)
AR_MIN_CONFIDENCE = 0.3    # 연관 규칙 최소 신뢰도 30%
AR_BOOST_WEIGHT   = 0.15   # DBSCAN 결과 boost 가산점
AR_POPULARITY_TOP = 10     # 인기도 폴백 반환 수