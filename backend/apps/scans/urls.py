from django.urls import path
from .views import BulkSyncView

urlpatterns = [
    path('sync/bulk-logs/', BulkSyncView.as_view(), name='bulk-sync-logs'),
]