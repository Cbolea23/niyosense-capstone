from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    class Roles(models.TextChoices):
        AGGREGATOR = 'AGGREGATOR', 'Aggregator'
        MANAGER = 'MANAGER', 'Manager'

    role = models.CharField(
        max_length=20, 
        choices=Roles.choices, 
        default=Roles.AGGREGATOR
    )
    # Stored so admin can view/remind field workers of their assigned password
    plaintext_password = models.CharField(
        max_length=128, 
        blank=True, 
        default=''
    )