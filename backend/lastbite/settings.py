"""
Django settings for lastbite project.
"""

from datetime import timedelta
from pathlib import Path

from decouple import config
from datetime import timedelta
from dotenv import load_dotenv
import os

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = "django-insecure-=a--rdh+esu4a%bzudo!tp2k22u@%lpoz*@(kt&#-y(3&_2!v8"

DEBUG = True

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '10.0.2.2',  # Android 에뮬레이터
    '.ngrok.io',  # ngrok 무료 도메인
    '.ngrok-free.app',  # ngrok 무료 플랜 신규 도메인
    '.ngrok-free.dev'
]

AUTH_USER_MODEL = "user.User"

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "user",
    "store",
    "product",
    "order",
    "cart",
    "common",
    "image",
    "post",
    "notification",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "lastbite.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "lastbite.wsgi.application"

load_dotenv()

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        'NAME': os.getenv("DJANGO_DB_NAME"),
        'USER': os.getenv("DJANGO_DB_USER"),
        'PASSWORD': os.getenv("DJANGO_DB_PASSWORD"),
        'HOST': os.getenv("DJANGO_DB_HOST"),
        'PORT': os.getenv("DJANGO_DB_PORT"),
    }
}

# Redis 설정 (Upstash)
REDIS_URL = config("REDIS_URL", default="redis://localhost:6379")

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "EXCEPTION_HANDLER": "common.response.custom_exception_handler",
}


AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "ko-kr"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"

# JWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=14),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'AUTH_HEADER_TYPES': ('Bearer',),
    'USER_ID_FIELD': 'user_id',
    'USER_ID_CLAIM': 'user_id',
}

# Email Settings (wiil be used in password resets)
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = True
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default=EMAIL_HOST_USER)

PASSWORD_RESET_TIMEOUT_MINUTES = 30 #minutes

# temp reset page, needs to be changed
FRONTEND_RESET_URL = config('FRONTEND_RESET_URL', default='http://localhost:3000/reset-password')

MEDIA_URL  = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
