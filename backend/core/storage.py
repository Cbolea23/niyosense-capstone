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
    - Acoustic knock recordings (.wav, .m4a, .mp3, or stored in coconuts/audio/) -> 'video' resource type
      (Cloudinary categorizes all audio under 'video', enabling HTML5 audio streaming and waveform preview).
    - If a model field already stores a direct HTTPS URL, returns it directly without double-prefixing.
    - Ensures audio URLs correctly point to 'video/upload/' and include the '.wav' extension for browser players.
    """

    def _get_resource_type(self, name):
        name_str = str(name).lower()
        ext = os.path.splitext(name_str)[1]
        if ext in ('.wav', '.mp3', '.m4a', '.aac', '.ogg', '.flac') or '/audio/' in name_str or '_tap_' in name_str:
            return RESOURCE_TYPES.get('VIDEO', 'video')
        return RESOURCE_TYPES.get('IMAGE', 'image')

    def url(self, name):
        if not name:
            return ''
        name_str = str(name)
        if name_str.startswith('http://') or name_str.startswith('https://'):
            if '/audio/' in name_str and '/image/upload/' in name_str:
                return name_str.replace('/image/upload/', '/video/upload/')
            return name_str

        res_url = super().url(name)
        if ('/audio/' in name_str or '_tap_' in name_str) and '/image/upload/' in res_url:
            res_url = res_url.replace('/image/upload/', '/video/upload/')

        if ('/audio/' in name_str or '_tap_' in name_str) and not res_url.lower().endswith(('.wav', '.mp3', '.m4a')):
            res_url = f"{res_url}.wav"

        return res_url
