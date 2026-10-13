from django.urls import path
from .views import (
    BulkSyncView,
    app_version_check_api,
    get_current_prices_api,
    sync_batch_session_api,
    farm_profile_api,
)

urlpatterns = [
    path('sync/bulk-logs/', BulkSyncView.as_view(), name='bulk-sync-logs'),
    path('system/app-version/', app_version_check_api, name='app_version_check_api'),
    path('pricing/current/', get_current_prices_api, name='get_current_prices_api'),
    path('sync/batch-session/', sync_batch_session_api, name='sync_batch_session_api'),
    path('system/farm-profile/', farm_profile_api, name='farm_profile_api'),
]