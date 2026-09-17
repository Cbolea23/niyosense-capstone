import json
import socket
import subprocess
import re
import platform
from datetime import timedelta
from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Count
from django.db.models.functions import TruncMonth
from django.shortcuts import render
from django.utils import timezone
from rest_framework import parsers, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import GradingLog
from .serializers import BulkSyncGradingLogSerializer


def web_dashboard(request):
    now = timezone.now()
    today = now.date()
    total_scans = GradingLog.objects.count()
    scans_today = GradingLog.objects.filter(created_at__date=today).count()
    mature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Mature').count()
    premature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Premature').count()
    overmature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Overmature').count()
    this_month_scans = GradingLog.objects.filter(
        created_at__year=now.year, created_at__month=now.month
    ).count()
    mature_rate = round((mature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0
    premature_rate = round((premature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0
    overmature_rate = round((overmature_count / total_scans) * 100, 1) if total_scans > 0 else 0.0

    daily_labels = []
    daily_counts = []
    for i in range(6, -1, -1):
        day_date = today - timedelta(days=i)
        cnt = GradingLog.objects.filter(created_at__date=day_date).count()
        daily_labels.append('Today' if i == 0 else day_date.strftime('%b %d'))
        daily_counts.append(cnt)

    monthly_yield_qs = (
        GradingLog.objects.annotate(month=TruncMonth('created_at'))
        .values('month')
        .annotate(count=Count('uuid'))
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

    recent_logs = GradingLog.objects.select_related('user').order_by('-created_at')[:50]

    context = {
        'total_scans': total_scans,
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
    }
    return render(request, 'dashboard/index.html', context)


class BulkSyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def post(self, request, *args, **kwargs):
        log_uuid = request.data.get('uuid')
        try:
            if GradingLog.objects.filter(uuid=log_uuid).exists():
                return Response(
                    {'status': 'ignored', 'reason': 'Log already exists in PostgreSQL'},
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

        serializer = BulkSyncGradingLogSerializer(data=sync_data)
        if serializer.is_valid():
            with transaction.atomic():
                serializer.save(user=request.user, is_synced=True)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def get_server_ip(request):
    ip_address = None
    system = platform.system()

    try:
        if system == "Windows":
            output = subprocess.check_output("ipconfig", shell=True).decode('utf-8', errors='ignore')
            # Split output into individual adapter blocks
            adapter_blocks = re.split(r'(?=Ethernet adapter|Wireless LAN adapter)', output)
            
            virtual_keywords = ['vmware', 'virtualbox', 'radmin', 'vmnet', 'hyper-v', 'wsl']

            for block in adapter_blocks:
                # Skip virtual adapters entirely
                if any(v in block.lower() for v in virtual_keywords):
                    continue
                
                # Extract IPv4 and Default Gateway
                ip_match = re.search(r'IPv4 Address[\. ]*:\s*([0-9\.]+)', block)
                gateway_match = re.search(r'Default Gateway[\. ]*:\s*([0-9\.]+)', block)
                
                if ip_match:
                    ip = ip_match.group(1)
                    # Skip invalid IPs
                    if ip.startswith(("127.", "169.254.", "0.")):
                        continue
                    
                    # Prefer adapters that have a gateway (internet/LAN connected)
                    if gateway_match and not gateway_match.group(1).startswith("0."):
                        ip_address = ip
                        break
                    elif not ip_address:
                        ip_address = ip # Fallback to first valid IP
                        
        else: # Linux / WSL / macOS
            output = subprocess.check_output("ip addr show", shell=True).decode('utf-8', errors='ignore')
            # Find physical interfaces (eth, enp, wlan)
            matches = re.findall(r'inet\s+([0-9\.]+).*?\s+(eth\d|enp\d|wlan\d)', output)
            for ip, iface in matches:
                if not ip.startswith(("127.", "169.254.")):
                    ip_address = ip
                    break
                    
    except Exception as e:
        print(f"IP detection error: {e}")

    # Fallback: UDP Socket method (if parsing failed)
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

    # Final fallback
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
    total_scans = GradingLog.objects.count()
    scans_today = GradingLog.objects.filter(created_at__date=today).count()
    mature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Mature').count()
    premature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Premature').count()
    overmature_count = GradingLog.objects.filter(final_maturity_stage__iexact='Overmature').count()

    daily_labels = []
    daily_counts = []
    for i in range(6, -1, -1):
        day_date = today - timedelta(days=i)
        cnt = GradingLog.objects.filter(created_at__date=day_date).count()
        daily_labels.append('Today' if i == 0 else day_date.strftime('%b %d'))
        daily_counts.append(cnt)

    return Response({
        "success": True,
        "total_scans": total_scans,
        "scans_today": scans_today,
        "mature_count": mature_count,
        "premature_count": premature_count,
        "overmature_count": overmature_count,
        "daily_labels": daily_labels,
        "daily_counts": daily_counts,
    })