import json
import os
import platform
import re
import shutil
import socket
import subprocess
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Count, Sum
from django.db.models.functions import TruncMonth, Coalesce
from django.shortcuts import render, redirect
from django.utils import timezone
from rest_framework import parsers, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import GradingLog, PriceSetting, DeliveryBatch, FarmProfile
from .serializers import (
    BulkSyncGradingLogSerializer,
    PriceSettingSerializer,
    DeliveryBatchSerializer,
)


def _sum_bunch(queryset):
    """Helper to sum bunch_count (number of coconuts) for a GradingLog queryset."""
    return queryset.aggregate(total=Coalesce(Sum('bunch_count'), 0))['total'] or 0


def web_dashboard(request):
    farm_profile = FarmProfile.get_profile()

    if request.method == 'POST' and 'update_farm_profile' in request.POST:
        farm_profile.owner_name = request.POST.get('owner_name', farm_profile.owner_name).strip()
        farm_profile.farm_name = request.POST.get('farm_name', farm_profile.farm_name).strip()
        farm_profile.location = request.POST.get('location', farm_profile.location).strip()
        farm_profile.email = request.POST.get('email', farm_profile.email).strip()
        farm_profile.save()
        return redirect('/#tab-settings')

    if request.method == 'POST' and 'update_prices' in request.POST:
        # Farm Owner updates master buying rates
        price_setting = PriceSetting.get_current_rates()
        try:
            price_setting.mature_price = Decimal(request.POST.get('mature_price', '12.00'))
            price_setting.premature_price = Decimal(request.POST.get('premature_price', '7.00'))
            price_setting.reject_price = Decimal(request.POST.get('reject_price', '0.00'))
            price_setting.save()
        except Exception:
            pass
        return redirect('/#tab-settings')

    now = timezone.now()
    today = now.date()
    total_bunches = GradingLog.objects.count()
    total_scans = _sum_bunch(GradingLog.objects.all())
    scans_today = _sum_bunch(GradingLog.objects.filter(created_at__date=today))
    mature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Mature'))
    premature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Premature'))
    overmature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Overmature'))
    this_month_scans = _sum_bunch(
        GradingLog.objects.filter(created_at__year=now.year, created_at__month=now.month)
    )
    mature_rate = round((mature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0
    premature_rate = round((premature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0
    overmature_rate = round((overmature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0

    daily_labels = []
    daily_counts = []
    for i in range(6, -1, -1):
        day_date = today - timedelta(days=i)
        cnt = _sum_bunch(GradingLog.objects.filter(created_at__date=day_date))
        daily_labels.append('Today' if i == 0 else day_date.strftime('%b %d'))
        daily_counts.append(cnt)

    monthly_yield_qs = (
        GradingLog.objects.annotate(month=TruncMonth('created_at'))
        .values('month')
        .annotate(count=Coalesce(Sum('bunch_count'), 0))
        .order_by('month')
    )
    monthly_labels = []
    monthly_counts = []
    for entry in monthly_yield_qs:
        if entry['month']:
            monthly_labels.append(entry['month'].strftime('%b %Y'))
            monthly_counts.append(entry['count'])
    if not monthly_labels:
        monthly_labels = [now.strftime('%b %Y')]
        monthly_counts = [0]

    recent_logs = GradingLog.objects.select_related('user', 'batch').order_by('-created_at')[:50]

    from django.contrib.auth import get_user_model
    User = get_user_model()
    aggregators = User.objects.filter(role=getattr(User.Roles, 'AGGREGATOR', 'AGGREGATOR')).order_by('-date_joined')

    # Deliveries and Payouts Data for Owner
    current_prices = PriceSetting.get_current_rates()
    batches = DeliveryBatch.objects.select_related('operator').order_by('-created_at')[:30]
    batch_summaries = []
    total_farm_payout = Decimal('0.00')

    for b in batches:
        b_scans = b.scans.all()
        m_cnt = sum((s.bunch_count or 1) for s in b_scans if 'mature' in s.final_maturity_stage.lower() and 'premature' not in s.final_maturity_stage.lower())
        p_cnt = sum((s.bunch_count or 1) for s in b_scans if 'premature' in s.final_maturity_stage.lower() or 'malauhog' in s.final_maturity_stage.lower())
        r_cnt = sum((s.bunch_count or 1) for s in b_scans) - m_cnt - p_cnt
        payout = (Decimal(m_cnt) * b.mature_price) + (Decimal(p_cnt) * b.premature_price) + (Decimal(r_cnt) * b.reject_price)
        total_farm_payout += payout

        batch_summaries.append({
            'batch': b,
            'total_scans': m_cnt + p_cnt + r_cnt,
            'mature_count': m_cnt,
            'premature_count': p_cnt,
            'reject_count': r_cnt,
            'payout': payout,
        })

    context = {
        'total_scans': total_scans,
        'total_bunches': total_bunches,
        'scans_today': scans_today,
        'mature_count': mature_count,
        'premature_count': premature_count,
        'overmature_count': overmature_count,
        'this_month_scans': this_month_scans,
        'mature_rate': mature_rate,
        'premature_rate': premature_rate,
        'overmature_rate': overmature_rate,
        'daily_labels_json': json.dumps(daily_labels),
        'daily_counts_json': json.dumps(daily_counts),
        'monthly_labels_json': json.dumps(monthly_labels),
        'monthly_counts_json': json.dumps(monthly_counts),
        'logs': recent_logs,
        'aggregators': aggregators,
        'current_prices': current_prices,
        'batch_summaries': batch_summaries,
        'total_farm_payout': total_farm_payout,
        'farm_profile': farm_profile,
        'app_version': '1.3.5',
        'model_pipeline': 'Multimodal Audio-Visual v2.4.2 (V2 Retrained)',
        'inference_engine': 'TFLite (Dual-Modality Late Fusion)',
    }
    return render(request, 'dashboard/index.html', context)


@api_view(['GET', 'POST'])
@permission_classes([permissions.AllowAny])
def farm_profile_api(request):
    """API to fetch or update farm owner profile."""
    profile = FarmProfile.get_profile()
    if request.method == 'POST':
        profile.owner_name = request.data.get('owner_name', profile.owner_name).strip()
        profile.farm_name = request.data.get('farm_name', profile.farm_name).strip()
        profile.location = request.data.get('location', profile.location).strip()
        profile.email = request.data.get('email', profile.email).strip()
        profile.save()
        return Response({
            'success': True,
            'owner_name': profile.owner_name,
            'farm_name': profile.farm_name,
            'location': profile.location,
            'email': profile.email,
        })
    return Response({
        'owner_name': profile.owner_name,
        'farm_name': profile.farm_name,
        'location': profile.location,
        'email': profile.email,
    })


# --- REST API Endpoints for Pricing & Delivery Batches ---

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_current_prices_api(request):
    """Mobile app fetches the master buying rates set by the farm owner."""
    prices = PriceSetting.get_current_rates()
    serializer = PriceSettingSerializer(prices)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def sync_batch_session_api(request):
    """Mobile app syncs completed farmer delivery sessions to the central server."""
    batch_id = request.data.get('batch_id')
    farmer_name = request.data.get('farmer_name', 'Unknown')
    mature_price = request.data.get('mature_price', 12.0)
    premature_price = request.data.get('premature_price', 7.0)
    reject_price = request.data.get('reject_price', 0.0)
    is_closed = request.data.get('is_closed', False)
    created_at = request.data.get('created_at') or timezone.now()

    batch, created = DeliveryBatch.objects.update_or_create(
        batch_id=batch_id,
        defaults={
            'farmer_name': farmer_name,
            'operator': request.user,
            'mature_price': Decimal(str(mature_price)),
            'premature_price': Decimal(str(premature_price)),
            'reject_price': Decimal(str(reject_price)),
            'is_closed': is_closed,
            'created_at': created_at,
        }
    )
    return Response({'status': 'success', 'batch_id': batch.batch_id}, status=status.HTTP_200_OK)


class BulkSyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def post(self, request, *args, **kwargs):
        log_uuid = request.data.get('uuid')
        try:
            existing_log = GradingLog.objects.filter(uuid=log_uuid).first()
            if existing_log:
                new_bunch = request.data.get('bunch_count')
                if new_bunch is not None:
                    try:
                        existing_log.bunch_count = max(1, int(new_bunch))
                        existing_log.save(update_fields=['bunch_count'])
                    except (ValueError, TypeError):
                        pass
                return Response(
                    {'status': 'updated', 'reason': 'Log already exists in PostgreSQL; bunch_count synchronized.'},
                    status=status.HTTP_200_OK,
                )
        except (ValidationError, ValueError):
            return Response(
                {'error': f"'{log_uuid}' is not a valid UUID format."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Copy request data to safely normalize key names ('audio' -> 'audio_file')
        sync_data = request.data.copy()
        if 'audio' in request.FILES and 'audio_file' not in sync_data:
            sync_data['audio_file'] = request.FILES['audio']

        # Link batch if batch_id provided
        batch_id = sync_data.get('batch_id')
        delivery_batch = None
        if batch_id:
            delivery_batch = DeliveryBatch.objects.filter(batch_id=batch_id).first()

        serializer = BulkSyncGradingLogSerializer(data=sync_data)
        if serializer.is_valid():
            with transaction.atomic():
                serializer.save(user=request.user, batch=delivery_batch, is_synced=True)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        print("❌ BulkSync validation errors:", serializer.errors, "Payload:", sync_data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_server_ip(request):
    ip_address = None
    system = platform.system()

    try:
        if system == "Windows":
            output = subprocess.check_output("ipconfig", shell=True).decode('utf-8', errors='ignore')
            adapter_blocks = re.split(r'(?=Ethernet adapter|Wireless LAN adapter)', output)
            virtual_keywords = ['vmware', 'virtualbox', 'radmin', 'vmnet', 'hyper-v', 'wsl']

            for block in adapter_blocks:
                if any(v in block.lower() for v in virtual_keywords):
                    continue
                ip_match = re.search(r'IPv4 Address[\. ]*:\s*([0-9\.]+)', block)
                gateway_match = re.search(r'Default Gateway[\. ]*:\s*([0-9\.]+)', block)
                if ip_match:
                    ip = ip_match.group(1)
                    if ip.startswith(("127.", "169.254.", "0.")):
                        continue
                    if gateway_match and not gateway_match.group(1).startswith("0."):
                        ip_address = ip
                        break
                    elif not ip_address:
                        ip_address = ip
                        
        elif shutil.which("ip"):
            output = subprocess.check_output("ip addr show", shell=True, stderr=subprocess.DEVNULL).decode('utf-8', errors='ignore')
            matches = re.findall(r'inet\s+([0-9\.]+).*?\s+(eth\d|enp\d|wlan\d)', output)
            for ip, iface in matches:
                if not ip.startswith(("127.", "169.254.")):
                    ip_address = ip
                    break
    except Exception:
        pass

    if not ip_address:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            detected = s.getsockname()[0]
            s.close()
            if detected and not detected.startswith(("127.", "169.254.")):
                ip_address = detected
        except Exception:
            pass

    if not ip_address:
        ip_address = "127.0.0.1"
    
    port = request.get_port() or '8000'
    server_url = f"http://{ip_address}:{port}"
    
    return Response({
        "success": True,
        "ip_address": ip_address,
        "server_url": server_url
    })


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def dashboard_stats_api(request):
    now = timezone.now()
    today = now.date()
    total_bunches = GradingLog.objects.count()
    total_scans = _sum_bunch(GradingLog.objects.all())
    scans_today = _sum_bunch(GradingLog.objects.filter(created_at__date=today))
    mature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Mature'))
    premature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Premature'))
    overmature_count = _sum_bunch(GradingLog.objects.filter(final_maturity_stage__iexact='Overmature'))

    daily_labels = []
    daily_counts = []
    for i in range(6, -1, -1):
        day_date = today - timedelta(days=i)
        cnt = _sum_bunch(GradingLog.objects.filter(created_at__date=day_date))
        daily_labels.append('Today' if i == 0 else day_date.strftime('%b %d'))
        daily_counts.append(cnt)

    return Response({
        "success": True,
        "total_scans": total_scans,
        "total_bunches": total_bunches,
        "scans_today": scans_today,
        "mature_count": mature_count,
        "premature_count": premature_count,
        "overmature_count": overmature_count,
        "daily_labels": daily_labels,
        "daily_counts": daily_counts,
    })


def download_apk_page(request):
    return render(request, 'dashboard/download_apk.html')


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def app_version_check_api(request):
    apk_rel_path = 'media/downloads/niyosense.apk'
    apk_abs_path = os.path.join(settings.BASE_DIR, apk_rel_path)
    file_exists = os.path.exists(apk_abs_path)
    file_size_bytes = os.path.getsize(apk_abs_path) if file_exists else 0
    file_size_mb = round(file_size_bytes / (1024 * 1024), 1)

    host = request.get_host()
    scheme = 'https' if request.is_secure() or request.headers.get('x-forwarded-proto') == 'https' else 'http'
    download_url = f"{scheme}://{host}/media/downloads/niyosense.apk?v=1.3.4"
    install_page_url = f"{scheme}://{host}/install/"

    return Response({
        "success": True,
        "latest_version": "1.3.4",
        "latest_build_number": 6,
        "release_title": "NiyoSense Field v1.3.4",
        "release_notes": "Lock price editing to Owner-only from dashboard, enhanced in-app updater, and batch session payout tracking.",
        "download_url": download_url,
        "install_page_url": install_page_url,
        "file_size_mb": file_size_mb,
        "available": file_exists,
    })