from rest_framework import serializers
from .models import GradingLog

class BulkSyncGradingLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = GradingLog
        fields = [
            'uuid', 'visual_prediction', 'audio_prediction',
            'final_maturity_stage', 'confidence_score',
            'image', 'audio_file', 'created_at'
        ]

    def validate_image(self, value):
        if not value.name.lower().endswith(('.png', '.jpg', '.jpeg')):
            raise serializers.ValidationError("Only PNG and JPG images are supported.")
        return value

    def validate_audio_file(self, value):
        if not value.name.lower().endswith(('.m4a', '.wav')):
            raise serializers.ValidationError("Only M4A and WAV audio formats are supported.")
        return value