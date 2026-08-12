from rest_framework import generics, status
from rest_framework.permissions import AllowAny  # <--- MUST BE IMPORTED
from rest_framework.response import Response
from .serializers import RegisterSerializer, UserSerializer

class RegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]  # <--- EXPLICITLY PERMIT UNAUTHENTICATED ACCESS
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