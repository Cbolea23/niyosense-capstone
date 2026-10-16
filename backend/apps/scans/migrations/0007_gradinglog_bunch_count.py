# Generated for NiyoSense Bungkos Cluster Sampling

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('scans', '0006_farmprofile_gradinglog_device_id'),
    ]

    operations = [
        migrations.AddField(
            model_name='gradinglog',
            name='bunch_count',
            field=models.PositiveIntegerField(
                default=1,
                help_text='Number of coconuts in this harvested bunch (bungkos)',
            ),
        ),
    ]
