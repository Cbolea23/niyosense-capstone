import os
from django.core.files.storage import FileSystemStorage

try:
    from cloudinary_storage.storage import MediaCloudinaryStorage, RESOURCE_TYPES
except ImportError:
    MediaCloudinaryStorage = FileSystemStorage
    RESOURCE_TYPES = {'IMAGE': 'image', 'VIDEO': 'video', 'RAW': 'raw'}


class NiyoSenseMediaCloudinaryStorage(MediaCloudinaryStorage):
    """
    Adaptive Cloudinary storage backend for NiyoSense.
    
    Automatically routes:
    - Coconut husk photos (.jpg, .jpeg, .png) -> 'image' resource type.
    - Acoustic knock recordings (.wav, .m4a, .mp3) -> 'video' resource type
      (Cloudinary categorizes audio under 'video', enabling HTML5 audio streaming and waveform preview).
    - If a model field already stores a direct HTTPS URL, returns it directly without double-prefixing.
    """

    def _get_resource_type(self, name):
        ext = os.path.splitext(name)[1].lower()
        if ext in ('.wav', '.mp3', '.m4a', '.aac', '.ogg', '.flac'):
            return RESOURCE_TYPES.get('VIDEO', 'video')
        return RESOURCE_TYPES.get('IMAGE', 'image')

    def url(self, name):
        if name and (str(name).startswith('http://') or str(name).startswith('https://')):
            return str(name)
        return super().url(name)
