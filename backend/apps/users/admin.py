from django.contrib import admin
from django.contrib.auth import get_user_model
from apps.scans.models import GradingLog  # Direct import from your scans app

User = get_user_model()

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'is_staff', 'is_active')
    list_filter = ('role', 'is_staff')
    search_fields = ('username', 'email')

@admin.register(GradingLog)
class GradingLogAdmin(admin.ModelAdmin):
    list_display = ('uuid', 'user', 'final_maturity_stage', 'confidence_score', 'is_synced', 'created_at')
    list_filter = ('final_maturity_stage', 'is_synced')
    search_fields = ('uuid', 'user__username')