from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .serializers import RegisterSerializer, UserSerializer

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {
                "user": UserSerializer(user).data,
                "message": "User registered successfully."
            },
            status=status.HTTP_201_CREATED
        )


@api_view(['GET', 'POST'])
@permission_classes([permissions.AllowAny])
def manage_aggregators_api(request):
    if request.method == 'GET':
        aggregators = User.objects.filter(role=User.Roles.AGGREGATOR).order_by('-date_joined')
        data = UserSerializer(aggregators, many=True).data
        return Response({"success": True, "users": data})

    elif request.method == 'POST':
        username = request.data.get('username', '').strip()
        password = request.data.get('password', '').strip()
        first_name = request.data.get('first_name', '').strip()
        last_name = request.data.get('last_name', '').strip()
        email = request.data.get('email', '').strip()

        if not username or not password:
            return Response(
                {"success": False, "error": "Username and password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {"success": False, "error": f"Username '{username}' already exists."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            username=username,
            password=password,
            email=email,
            first_name=first_name,
            last_name=last_name,
            role=User.Roles.AGGREGATOR,
            plaintext_password=password
        )
        return Response(
            {"success": True, "message": f"Aggregator account '{username}' created successfully.", "user": UserSerializer(user).data},
            status=status.HTTP_201_CREATED
        )


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([permissions.AllowAny])
def aggregator_detail_api(request, user_id):
    try:
        user = User.objects.get(id=user_id, role=User.Roles.AGGREGATOR)
    except User.DoesNotExist:
        return Response({"success": False, "error": "Aggregator account not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        scans_count = user.scans.count() if hasattr(user, 'scans') else 0
        user_data = UserSerializer(user).data
        user_data['total_scans'] = scans_count
        return Response({"success": True, "user": user_data})

    elif request.method == 'PUT':
        first_name = request.data.get('first_name')
        last_name = request.data.get('last_name')
        email = request.data.get('email')
        password = request.data.get('password')
        is_active = request.data.get('is_active')

        if first_name is not None:
            user.first_name = first_name.strip()
        if last_name is not None:
            user.last_name = last_name.strip()
        if email is not None:
            user.email = email.strip()
        if is_active is not None:
            user.is_active = bool(is_active)
        if password and str(password).strip():
            clean_pw = str(password).strip()
            user.set_password(clean_pw)
            user.plaintext_password = clean_pw

        user.save()
        user_data = UserSerializer(user).data
        user_data['total_scans'] = user.scans.count() if hasattr(user, 'scans') else 0
        return Response({
            "success": True,
            "message": f"Account '{user.username}' updated successfully.",
            "user": user_data
        })

    elif request.method == 'DELETE':
        username = user.username
        user.delete()
        return Response({
            "success": True,
            "message": f"Account '{username}' deleted successfully."
        })
