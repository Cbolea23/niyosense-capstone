from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve

from django.shortcuts import redirect
from apps.scans.views import (
    web_dashboard,
    owner_login,
    owner_logout,
    get_server_ip,
    dashboard_stats_api,
    download_apk_page,
)

def download_apk_redirect(request):
    return redirect('https://github.com/Cbolea23/niyosense-capstone/releases/download/v1.5.2/niyosense.apk')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', web_dashboard, name='dashboard'),
    path('login/', owner_login, name='owner_login'),
    path('logout/', owner_logout, name='owner_logout'),
    path('lock/', owner_logout, name='owner_lock'),
    path('install/', download_apk_page, name='download_apk_page'),
    path('download-app/', download_apk_page, name='download_apk_page_alias'),
    path('media/downloads/niyosense.apk', download_apk_redirect, name='apk_download_direct'),
    path('api/v1/auth/', include('apps.users.urls')),
    path('api/v1/', include('apps.scans.urls')),
    path('api/v1/system/host-ip/', get_server_ip, name='get_server_ip'),
    path('healthz', get_server_ip, name='health_check'),
    path('healthz/', get_server_ip, name='health_check_slash'),
    path('api/v1/analytics/dashboard-stats/', dashboard_stats_api, name='dashboard_stats_api'),
    # Tolerant fallback routes in case a mobile device included /install/ in its Server URL
    re_path(r'^(?:install|download-app)/+api/v1/auth/', include('apps.users.urls')),
    re_path(r'^(?:install|download-app)/+api/v1/', include('apps.scans.urls')),
]

# Media serving for standalone Docker container & development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
else:
    urlpatterns += [
        re_path(r'^media/(?P<path>.*)$', serve, {'document_root': settings.MEDIA_ROOT}),
    ]
