from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, parsers
from django.db import transaction
from .models import GradingLog
from .serializers import BulkSyncGradingLogSerializer

class BulkSyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def post(self, request, *args, **kwargs):
        log_uuid = request.data.get('uuid')

        # Idempotency check: Skip duplicate scan if UUID exists
        if GradingLog.objects.filter(uuid=log_uuid).exists():
            return Response(
                {"status": "ignored", "reason": "Log already exists in PostgreSQL"},
                status=status.HTTP_200_OK
            )

        serializer = BulkSyncGradingLogSerializer(data=request.data)

        if serializer.is_valid():
            with transaction.atomic():
                serializer.save(user=request.user, is_synced=True)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)