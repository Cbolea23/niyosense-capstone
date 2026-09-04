from rest_framework import serializers
from .models import GradingLog

class BulkSyncGradingLogSerializer(serializers.ModelSerializer):
    image = serializers.ImageField(required=False, allow_null=True)
    audio_file = serializers.FileField(required=False, allow_null=True)

    class Meta:
        model = GradingLog
        fields = [
            'uuid',
            'visual_prediction',
            'audio_prediction',
            'final_maturity_stage',
            'confidence_score',
            'created_at',
            'image',
            'audio_file',
        ]

    def to_internal_value(self, data):
        # Create a mutable copy of incoming form data
        mutable_data = data.copy() if hasattr(data, 'copy') else dict(data)
        
        # Auto-convert choice fields from "MATURE" -> "Mature"
        for field in ['visual_prediction', 'audio_prediction', 'final_maturity_stage']:
            if field in mutable_data and isinstance(mutable_data[field], str):
                mutable_data[field] = mutable_data[field].capitalize()
                
        return super().to_internal_value(mutable_data)