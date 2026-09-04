from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from apps.scans.views import web_dashboard

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', web_dashboard, name='dashboard'),
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/', include('apps.scans.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)