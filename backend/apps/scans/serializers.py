from rest_framework import serializers
from .models import GradingLog, PriceSetting, DeliveryBatch


class PriceSettingSerializer(serializers.ModelSerializer):
  class Meta:
    model = PriceSetting
    fields = ['mature_price', 'premature_price', 'reject_price', 'updated_at']


class DeliveryBatchSerializer(serializers.ModelSerializer):
  total_scans = serializers.IntegerField(read_only=True)
  mature_count = serializers.IntegerField(read_only=True)
  premature_count = serializers.IntegerField(read_only=True)
  reject_count = serializers.IntegerField(read_only=True)
  total_payout = serializers.FloatField(read_only=True)

  class Meta:
    model = DeliveryBatch
    fields = [
        'batch_id',
        'farmer_name',
        'operator',
        'mature_price',
        'premature_price',
        'reject_price',
        'is_closed',
        'created_at',
        'total_scans',
        'mature_count',
        'premature_count',
        'reject_count',
        'total_payout',
    ]


class BulkSyncGradingLogSerializer(serializers.ModelSerializer):
  image = serializers.ImageField(required=False, allow_null=True)
  audio_file = serializers.FileField(required=False, allow_null=True)
  visual_prediction = serializers.CharField(
      required=False, allow_blank=True, max_length=50
  )
  audio_prediction = serializers.CharField(
      required=False, allow_blank=True, max_length=50
  )
  batch_id = serializers.CharField(required=False, allow_blank=True)
  device_id = serializers.CharField(required=False, allow_blank=True, max_length=64)
  bunch_count = serializers.IntegerField(required=False, default=1, min_value=1)

  class Meta:
    model = GradingLog
    fields = [
        'uuid',
        'visual_prediction',
        'audio_prediction',
        'final_maturity_stage',
        'confidence_score',
        'device_id',
        'bunch_count',
        'created_at',
        'image',
        'audio_file',
        'batch_id',
    ]

  created_at = serializers.DateTimeField(required=False)

  def to_internal_value(self, data):
    mutable_data = data.copy() if hasattr(data, 'copy') else dict(data)

    STAGE_MAPPING = {
        'buko': 'Buko',
        'malauhog': 'Malauhog',
        'mature': 'Malauhog',
        'premature': 'Buko',
        'overmature': 'Malauhog',
        'reject': 'Reject',
        'unrecognized': 'Reject',
        'unrecognized object': 'Reject',
        'unrecognized_object': 'Reject',
    }

    # Normalize final_maturity_stage to standard stages (Malauhog, Buko, Reject)
    final_stage = str(mutable_data.get('final_maturity_stage', '')).strip()
    lowered = final_stage.lower()
    if 'unrecognized' in lowered or 'reject' in lowered:
      mutable_data['final_maturity_stage'] = 'Reject'
    else:
      mutable_data['final_maturity_stage'] = STAGE_MAPPING.get(
          lowered, final_stage.capitalize() or 'Buko'
      )

    # Clean raw prediction fields without triggering choice validation
    vis = str(mutable_data.get('visual_prediction', '')).strip()
    mutable_data['visual_prediction'] = vis.capitalize() if vis else 'Unknown'

    aud = str(mutable_data.get('audio_prediction', '')).strip()
    mutable_data['audio_prediction'] = aud if aud else 'N/A'

    # Auto-populate created_at if missing or invalid
    if not mutable_data.get('created_at'):
      from django.utils import timezone
      mutable_data['created_at'] = timezone.now().isoformat()

    return super().to_internal_value(mutable_data)