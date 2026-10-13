from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve

from apps.scans.views import web_dashboard, get_server_ip, dashboard_stats_api, download_apk_page

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', web_dashboard, name='dashboard'),
    path('install/', download_apk_page, name='download_apk_page'),
    path('download-app/', download_apk_page, name='download_apk_page_alias'),
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/', include('apps.scans.urls')),
    path('api/v1/system/host-ip/', get_server_ip, name='get_server_ip'),
    path('api/v1/analytics/dashboard-stats/', dashboard_stats_api, name='dashboard_stats_api'),
]

# Media serving for standalone Docker container & development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
else:
    urlpatterns += [
        re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
    ]