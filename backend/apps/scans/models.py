import uuid
from django.conf import settings
from django.db import models


class GradingLog(models.Model):
  MATURITY_CHOICES = [
      ('Premature', 'Premature'),
      ('Mature', 'Mature'),
      ('Overmature', 'Overmature'),
      ('Buko', 'Buko'),
      ('Malauhog', 'Malauhog'),
  ]

  uuid = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  user = models.ForeignKey(
      settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='scans'
  )

  image = models.ImageField(upload_to='coconuts/images/%Y/%m/%d/')
  audio_file = models.FileField(upload_to='coconuts/audio/%Y/%m/%d/')

  # Raw inputs allow model labels ("Buko", "Malauhog") and skipped recordings
  visual_prediction = models.CharField(max_length=50, default='Unknown')
  audio_prediction = models.CharField(max_length=50, default='N/A')

  final_maturity_stage = models.CharField(
      max_length=20, choices=MATURITY_CHOICES
  )
  confidence_score = models.FloatField()
  is_synced = models.BooleanField(default=True)
  created_at = models.DateTimeField(db_index=True)

  class Meta:
    ordering = ['-created_at']

  def __str__(self):
    return f'Scan {self.uuid} - {self.final_maturity_stage}'