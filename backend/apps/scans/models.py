import uuid
from django.conf import settings
from django.db import models


class FarmProfile(models.Model):
  """Farm and owner profile information."""
  owner_name = models.CharField(max_length=150, default='Maria Santos')
  farm_name = models.CharField(max_length=200, default='Plantation Owner Portal')
  location = models.CharField(max_length=200, default='Quezon Province')
  email = models.EmailField(blank=True, default='m.santos@niyosense.ph')
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    verbose_name = 'Farm Profile'
    verbose_name_plural = 'Farm Profiles'

  @classmethod
  def get_profile(cls):
    profile, _ = cls.objects.get_or_create(id=1)
    return profile

  def __str__(self):
    return f'{self.farm_name} ({self.owner_name})'


class PriceSetting(models.Model):
  """Master buying rates configured by the farm owner."""

  mature_price = models.DecimalField(
      max_digits=7,
      decimal_places=2,
      default=12.00,
      help_text='Price per mature nut (PHP)',
  )
  premature_price = models.DecimalField(
      max_digits=7,
      decimal_places=2,
      default=7.00,
      help_text='Price per premature/buko nut (PHP)',
  )
  reject_price = models.DecimalField(
      max_digits=7,
      decimal_places=2,
      default=0.00,
      help_text='Price per reject nut (PHP)',
  )
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    verbose_name = 'Price Setting'
    verbose_name_plural = 'Price Settings'

  @classmethod
  def get_current_rates(cls):
    price_setting, _ = cls.objects.get_or_create(id=1)
    return price_setting

  def __str__(self):
    return (
        f'Rates: Mature=₱{self.mature_price}, Premature=₱{self.premature_price},'
        f' Reject=₱{self.reject_price}'
    )


class DeliveryBatch(models.Model):
  """Grouped delivery batch from a farmer/supplier."""

  batch_id = models.CharField(max_length=64, primary_key=True)
  farmer_name = models.CharField(max_length=150)
  operator = models.ForeignKey(
      settings.AUTH_USER_MODEL,
      on_delete=models.SET_NULL,
      null=True,
      blank=True,
      related_name='batches',
  )
  mature_price = models.DecimalField(
      max_digits=7, decimal_places=2, default=12.00
  )
  premature_price = models.DecimalField(
      max_digits=7, decimal_places=2, default=7.00
  )
  reject_price = models.DecimalField(
      max_digits=7, decimal_places=2, default=0.00
  )
  is_closed = models.BooleanField(default=False)
  created_at = models.DateTimeField(db_index=True)

  class Meta:
    ordering = ['-created_at']
    verbose_name = 'Delivery Batch'
    verbose_name_plural = 'Delivery Batches'

  def __str__(self):
    return f'{self.batch_id} - {self.farmer_name}'


class GradingLog(models.Model):
  MATURITY_CHOICES = [
      ('Premature', 'Premature'),
      ('Mature', 'Mature'),
      ('Overmature', 'Overmature'),
      ('Buko', 'Buko'),
      ('Malauhog', 'Malauhog'),
      ('Unrecognized', 'Unrecognized'),
  ]

  uuid = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  user = models.ForeignKey(
      settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='scans'
  )
  batch = models.ForeignKey(
      DeliveryBatch,
      on_delete=models.SET_NULL,
      null=True,
      blank=True,
      related_name='scans',
  )

  image = models.ImageField(upload_to='coconuts/images/%Y/%m/%d/')
  audio_file = models.FileField(upload_to='coconuts/audio/%Y/%m/%d/')

  # Raw inputs allow model labels ("Buko", "Malauhog") and skipped recordings
  visual_prediction = models.CharField(max_length=50, default='Unknown')
  audio_prediction = models.CharField(max_length=50, default='N/A')

  final_maturity_stage = models.CharField(
      max_length=30, choices=MATURITY_CHOICES
  )
  confidence_score = models.FloatField()
  device_id = models.CharField(max_length=64, blank=True, default='', db_index=True)
  bunch_count = models.PositiveIntegerField(
      default=1,
      help_text='Number of coconuts in this harvested bunch (bungkos)',
  )
  is_synced = models.BooleanField(default=True)
  created_at = models.DateTimeField(db_index=True)

  class Meta:
    ordering = ['-created_at']

  def __str__(self):
    return f'Scan {self.uuid} - {self.final_maturity_stage} ({self.bunch_count} pcs)'