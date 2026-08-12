from uuid import uuid4
from django.db import models
from django.conf import settings

class GradingLog(models.Model):
    MATURITY_CHOICES = [
        ('Premature', 'Premature'),
        ('Mature', 'Mature'),
        ('Overmature', 'Overmature'),
    ]

    uuid = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='scans'
    )
    
    image = models.ImageField(upload_to='coconuts/images/%Y/%m/%d/')
    audio_file = models.FileField(upload_to='coconuts/audio/%Y/%m/%d/')
    
    visual_prediction = models.CharField(max_length=20, choices=MATURITY_CHOICES)
    audio_prediction = models.CharField(max_length=20, choices=MATURITY_CHOICES)
    final_maturity_stage = models.CharField(max_length=20, choices=MATURITY_CHOICES)
    
    confidence_score = models.FloatField()
    is_synced = models.BooleanField(default=True)
    created_at = models.DateTimeField(db_index=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Scan {self.uuid} - {self.final_maturity_stage}"