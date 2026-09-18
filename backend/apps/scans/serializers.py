from rest_framework import serializers
from .models import GradingLog


class BulkSyncGradingLogSerializer(serializers.ModelSerializer):
  image = serializers.ImageField(required=False, allow_null=True)
  audio_file = serializers.FileField(required=False, allow_null=True)
  visual_prediction = serializers.CharField(
      required=False, allow_blank=True, max_length=50
  )
  audio_prediction = serializers.CharField(
      required=False, allow_blank=True, max_length=50
  )

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
    mutable_data = data.copy() if hasattr(data, 'copy') else dict(data)

    STAGE_MAPPING = {
        'buko': 'Mature',
        'malauhog': 'Premature',
        'mature': 'Mature',
        'premature': 'Premature',
        'overmature': 'Overmature',
    }

    # Normalize final_maturity_stage to standard stages
    final_stage = str(mutable_data.get('final_maturity_stage', '')).strip()
    mutable_data['final_maturity_stage'] = STAGE_MAPPING.get(
        final_stage.lower(), final_stage.capitalize() or 'Mature'
    )

    # Clean raw prediction fields without triggering choice validation
    vis = str(mutable_data.get('visual_prediction', '')).strip()
    mutable_data['visual_prediction'] = vis.capitalize() if vis else 'Unknown'

    aud = str(mutable_data.get('audio_prediction', '')).strip()
    mutable_data['audio_prediction'] = aud if aud else 'N/A'

    return super().to_internal_value(mutable_data)