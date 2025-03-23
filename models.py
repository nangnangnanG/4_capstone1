from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    gender = models.CharField(max_length=20, choices=[
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('non-binary', 'Non-binary'),
        ('prefer not to say', 'Prefer not to say'),
    ])
    username = models.CharField(max_length=30, unique=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    provider = models.CharField(max_length=50, default='local')
    profile_image = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    last_login = models.DateTimeField(null=True, blank=True)
    is_superuser = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    
    # 새로 추가된 rank 필드
    rank = models.IntegerField(default=1)
    
    # 사용자가 올린 피드 수를 추적하는 필드
    feed_count = models.IntegerField(default=0)

    def update_rank(self):
        """
        피드 수에 따라 랭크를 업데이트하는 메서드
        
        랭크 기준:
        1. 0~9 피드: 랭크 1
        2. 10~49 피드: 랭크 2
        3. 50~99 피드: 랭크 3
        4. 100~199 피드: 랭크 4
        5. 200~499 피드: 랭크 5
        6. 500+ 피드: 랭크 6
        """
        if self.feed_count < 10:
            self.rank = 1
        elif self.feed_count < 50:
            self.rank = 2
        elif self.feed_count < 100:
            self.rank = 3
        elif self.feed_count < 200:
            self.rank = 4
        elif self.feed_count < 500:
            self.rank = 5
        else:
            self.rank = 6
        
        self.save()

    class Meta:
        db_table = 'users'


class CustomToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="custom_auth_token")
    key = models.CharField(max_length=40, unique=True)
    created = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.key:
            self.key = uuid.uuid4().hex  
        return super().save(*args, **kwargs)