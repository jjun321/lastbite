from rest_framework import serializers

class AnomalyDetectSerializer(serializers.Serializer):
    """POST /anomaly/detect/ 요청 검증 — 단건 이상치 탐지"""
    store_id      = serializers.IntegerField(min_value=0)
    discount_rate = serializers.IntegerField(min_value=0, max_value=100)


class _AnomalyItemSerializer(serializers.Serializer):
    store_id      = serializers.IntegerField(min_value=0)
    product_id    = serializers.IntegerField(min_value=0)
    discount_rate = serializers.IntegerField(min_value=0, max_value=100)


class AnomalyBatchSerializer(serializers.Serializer):
    """POST /anomaly/detect-batch/ 요청 검증 — 일괄 이상치 탐지"""
    items = _AnomalyItemSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("items는 비어 있을 수 없습니다.")
        return value
