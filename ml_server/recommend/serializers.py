from rest_framework import serializers


class RecommendRequestSerializer(serializers.Serializer):
    """POST /recommend/ 요청 검증"""
    user_id = serializers.IntegerField(min_value=0)
    top_n   = serializers.IntegerField(min_value=1, max_value=50, default=10)


