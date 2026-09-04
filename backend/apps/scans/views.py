from django.db import transaction
from django.core.exceptions import ValidationError
from rest_framework import parsers, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import GradingLog
from .serializers import BulkSyncGradingLogSerializer


class BulkSyncView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def post(self, request, *args, **kwargs):
        log_uuid = request.data.get('uuid')

        # Gracefully handle malformed UUID string formats
        try:
            if GradingLog.objects.filter(uuid=log_uuid).exists():
                return Response(
                    {
                        "status": "ignored",
                        "reason": "Log already exists in PostgreSQL",
                    },
                    status=status.HTTP_200_OK,
                )
        except (ValidationError, ValueError):
            return Response(
                {"error": f"'{log_uuid}' is not a valid UUID format."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = BulkSyncGradingLogSerializer(data=request.data)

        if serializer.is_valid():
            with transaction.atomic():
                serializer.save(user=request.user, is_synced=True)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        print("❌ SERIALIZER VALIDATION ERRORS:", serializer.errors)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)