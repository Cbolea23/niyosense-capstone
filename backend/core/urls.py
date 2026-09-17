from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from apps.scans.views import web_dashboard, get_server_ip, dashboard_stats_api

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', web_dashboard, name='dashboard'),
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/', include('apps.scans.urls')),
    path('api/v1/system/host-ip/', get_server_ip, name='get_server_ip'),
    path('api/v1/analytics/dashboard-stats/', dashboard_stats_api, name='dashboard_stats_api'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)