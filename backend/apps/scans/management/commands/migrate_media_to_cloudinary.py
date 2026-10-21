import os
from django.conf import settings
from django.core.management.base import BaseCommand
from apps.scans.models import GradingLog

try:
    import cloudinary.uploader
except ImportError:
    cloudinary = None


class Command(BaseCommand):
    help = 'Uploads existing local media files (images & audio) to Cloudinary and updates GradingLog records.'

    def handle(self, *args, **options):
        if not getattr(settings, 'USE_CLOUDINARY', False):
            self.stderr.write(self.style.ERROR(
                'Cloudinary is not configured! Please set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET in your .env file.'
            ))
            return

        logs = GradingLog.objects.all()
        img_uploaded = 0
        aud_uploaded = 0

        self.stdout.write(f'Scanning {logs.count()} GradingLog records for local media...')

        for log in logs:
            updated = False
            # 1. Image migration
            if log.image:
                img_name = str(log.image)
                if not img_name.startswith('http'):
                    local_img_path = os.path.join(settings.MEDIA_ROOT, img_name)
                    if os.path.exists(local_img_path):
                        self.stdout.write(f'Uploading image: {img_name}')
                        try:
                            res = cloudinary.uploader.upload(
                                local_img_path,
                                resource_type='image',
                                folder='coconuts/images',
                                overwrite=False
                            )
                            log.image = res.get('secure_url', log.image)
                            updated = True
                            img_uploaded += 1
                        except Exception as e:
                            self.stderr.write(f'Failed to upload {img_name}: {e}')

            # 2. Audio migration
            if log.audio_file:
                aud_name = str(log.audio_file)
                if not aud_name.startswith('http'):
                    local_aud_path = os.path.join(settings.MEDIA_ROOT, aud_name)
                    if os.path.exists(local_aud_path):
                        self.stdout.write(f'Uploading audio: {aud_name}')
                        try:
                            res = cloudinary.uploader.upload(
                                local_aud_path,
                                resource_type='video',
                                folder='coconuts/audio',
                                overwrite=False
                            )
                            log.audio_file = res.get('secure_url', log.audio_file)
                            updated = True
                            aud_uploaded += 1
                        except Exception as e:
                            self.stderr.write(f'Failed to upload {aud_name}: {e}')

            if updated:
                log.save(update_fields=['image', 'audio_file'])

        self.stdout.write(self.style.SUCCESS(
            f'Migration complete! Uploaded {img_uploaded} images and {aud_uploaded} audio files to Cloudinary.'
        ))
