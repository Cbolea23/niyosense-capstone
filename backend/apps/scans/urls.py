from django.urls import path
from .views import BulkSyncView, app_version_check_api

urlpatterns = [
    path('sync/bulk-logs/', BulkSyncView.as_view(), name='bulk-sync-logs'),
    path('system/app-version/', app_version_check_api, name='app_version_check_api'),
]