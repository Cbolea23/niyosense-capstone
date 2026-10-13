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
            role=User.Roles.AGGREGATOR
        )
        return Response(
            {"success": True, "message": f"Aggregator account '{username}' created successfully.", "user": UserSerializer(user).data},
            status=status.HTTP_201_CREATED
        )