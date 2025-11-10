# Описание проекта (RacingProject)

## Модели данных
```python
from django.db import models
from django.contrib.auth.models import User

# Профиль пользователя
class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    ROLE_CHOICES = [
        ("admin", "Администратор"),
        ("user", "Пользователь"),
    ]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default="user")

    def isAdmin(self):
        return self.role == 'admin'

    def __str__(self):
        return f"{self.user.username} — {self.get_role_display()}"


class Team(models.Model):
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name


class Car(models.Model):
    model = models.CharField(max_length=200)
    description = models.TextField(blank=True)

    def __str__(self):
        return f"Модель: {self.model}"


class Participant(models.Model):
    CLASS_CHOICES = [
        ("Pro", "Профессионал"),
        ("Amateur", "Любитель"),
        ("A", "Класс A"),
        ("B", "Класс B"),
        ("C", "Класс C"),
    ]

    description = models.TextField(blank=True)
    experience_years = models.PositiveIntegerField(default=0)
    participant_class = models.CharField(max_length=20, choices=CLASS_CHOICES, default="Amateur")
    team = models.ForeignKey(Team, on_delete=models.SET_NULL, related_name="participants", null=True, blank=True)
    profile = models.OneToOneField(Profile, on_delete=models.CASCADE, related_name="participant")

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        team_name = self.team.name if self.team else "без команды"
        return f"{self.profile.user.username} ({self.get_participant_class_display()}) — команда: {team_name}"


class Race(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    location = models.CharField(max_length=255, blank=True)
    date = models.DateField()
    created_by = models.ForeignKey(Profile, on_delete=models.SET_NULL, related_name="created_races", null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date"]

    def __str__(self):
        return f"Гонка: {self.name} — {self.date}"


class Registration(models.Model):
    participant = models.ForeignKey(Participant, on_delete=models.CASCADE, related_name="registrations")
    car = models.ForeignKey(Car, on_delete=models.CASCADE, related_name="registrations")
    race = models.ForeignKey(Race, on_delete=models.CASCADE, related_name="registrations")

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("participant", "race", "car")

    def __str__(self):
        return f"{self.participant} — автомобиль: {self.car.model} — гонка: {self.race.name}"


class RaceSession(models.Model):
    race = models.ForeignKey(Race, on_delete=models.CASCADE, related_name="sessions")
    name = models.CharField(max_length=100, default="Заезд")
    order = models.PositiveIntegerField(default=1)
    start_time = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return f"{self.race.name} — {self.name} №{self.order}"


class RaceResult(models.Model):
    registration = models.ForeignKey(Registration, on_delete=models.CASCADE, related_name="results")
    session = models.ForeignKey(RaceSession, on_delete=models.CASCADE, related_name="results")
    total_time = models.DurationField()

    class Meta:
        unique_together = ("registration", "session")
        ordering = ["total_time"]

    def __str__(self):
        return f"{self.registration} — результат заезда №{self.session.order}: {self.total_time}"


class Comment(models.Model):
    COMMENT_TYPE = [
        ("cooperation", "Вопрос о сотрудничестве"),
        ("race_question", "Вопрос о гонках"),
        ("other", "Другое"),
    ]

    race = models.ForeignKey(Race, on_delete=models.CASCADE, related_name="comments")
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="comments")
    comment_type = models.CharField(max_length=20, choices=COMMENT_TYPE, default="other")
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Комментарий от {self.profile.user.username} к гонке '{self.race.name}': {self.text[:30]}"

```

## Формы
```python
from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import Participant, Car, Registration, Comment, Race, RaceSession, RaceResult

class ProfileRegistrationForm(UserCreationForm):
    email = forms.EmailField(required=True)
    class Meta:
        model = User
        fields = ("username","email","password1","password2")

class ParticipantForm(forms.ModelForm):
    class Meta:
        model = Participant
        fields = ("description","experience_years","participant_class","team")

class CarForm(forms.ModelForm):
    class Meta:
        model = Car
        fields = ("model","description")

class RaceRegistrationForm(forms.ModelForm):
    class Meta:
        model = Registration
        fields = ("participant","car")
    def __init__(self, *args, **kwargs):
        profile = kwargs.pop('profile', None)
        race = kwargs.pop('race', None)
        super().__init__(*args, **kwargs)
        if profile is not None:
            self.fields['participant'].initial = profile.participant
            self.fields["participant"].widget = forms.HiddenInput()
        if race is not None:
            # hide participants already registered for this race (optional)
            pass

class RaceForm(forms.ModelForm):
    class Meta:
        model = Race
        fields = ["name", "description", "location", "date"]
        widgets = {
            "date": forms.DateInput(attrs={"type": "date"}),
        }

class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ("comment_type","text")
        widgets = {
            "text": forms.Textarea(attrs={"rows":3})
        }

class RaceSessionForm(forms.ModelForm):
    class Meta:
        model = RaceSession
        fields = ["name", "order", "start_time"]
        widgets = {
            "start_time": forms.DateTimeInput(
                attrs={"type": "datetime-local"},
                format="%Y-%m-%dT%H:%M"
            ),
        }

class RaceResultForm(forms.ModelForm):
    class Meta:
        model = RaceResult
        fields = ("registration","total_time")

```

## URL адреса и Пользовательский функционал
```python
from django.urls import path
from . import views
from django.contrib.auth import views as auth_views

app_name = 'racing'

urlpatterns = [
    path('', views.races_list, name='races_list'),
    path('accounts/login/', views.index, name='index'),
    path('login/', views.AppLoginView.as_view(), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='racing:races_list'), name='logout'),
    path('register/', views.register, name='register'),
    path('participant/create/', views.participant_create, name='participant_create'),
    path('car/create/', views.car_create, name='car_create'),
    path('races/', views.races_list, name='races_list'),
    path("races/create/", views.race_create, name="race_create"),
    path('races/<int:pk>/', views.race_detail, name='race_detail'),
    path('races/<int:race_pk>/register/', views.race_register, name='race_register'),
    path('races/<int:race_pk>/toggle-registration/', views.race_unregister, name='race_unregister'),
    path('races/<int:race_pk>/comment/', views.add_comment, name='add_comment'),
    path('races/<int:race_pk>/race_session_create/', views.race_session_create, name='race_session_create'),
    path('races/<int:race_pk>/sessions/<int:session_pk>/result/add', views.add_result, name='add_result'),
]
```

## Представления
```python
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib.auth.views import LoginView, LogoutView
from django.core.paginator import Paginator
from django.urls import reverse
from django.views.decorators.http import require_POST
from .models import Profile, Participant, Car, Race, Registration, RaceSession, RaceResult, Comment
from .forms import ProfileRegistrationForm, ParticipantForm, CarForm, RaceRegistrationForm, CommentForm, RaceForm, RaceSessionForm, RaceResultForm

def next_redirect(request, urlname):
    next_url = request.GET.get("next")
    if next_url:
        return redirect(next_url)
    
    return redirect(urlname)

def index(request):
    # simple index showing login (or welcome if authenticated)
    # if request.user.is_authenticated:
    #     return redirect('racing:races_list')
    return render(request, 'racing/index.html')

class AppLoginView(LoginView):
    template_name = 'racing/login.html'

def register(request):
    if request.method == 'POST':
        form = ProfileRegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            # create Profile automatically in signal or here
            profile, _ = Profile.objects.get_or_create(user=user)
            login(request, user)
            return redirect('racing:races_list')
    else:
        form = ProfileRegistrationForm()
    return render(request, 'racing/register.html', {'form': form})

@login_required
def participant_create(request):
    try:
        existing = request.user.profile.participant
    except Exception:
        existing = None

    if request.method == 'POST':
        form = ParticipantForm(request.POST)
        if form.is_valid():
            if not existing:
                return next_redirect(request, 'racing:races_list')
            
            participant = form.save(commit=False)
            participant.profile = request.user.profile
            participant.save()

            return next_redirect(request, 'racing:races_list')
    else:
        form = ParticipantForm()
    return render(request, 'racing/participant_form.html', {'form': form})

@login_required
def car_create(request):
    if request.method == 'POST':
        form = CarForm(request.POST)
        if form.is_valid():
            car = form.save()
            return redirect('racing:races_list')
    else:
        form = CarForm()
    return render(request, 'racing/car_form.html', {'form': form})

def races_list(request):
    qs = Race.objects.all().order_by('-date')
    paginator = Paginator(qs, 2)
    page = request.GET.get('page', 1)
    races = paginator.get_page(page)
    try:
        registered_races = request.user.profile.participant.registrations.values_list('race_id', flat=True)
    except Exception:
        registered_races = []
        
    return render(request, 'racing/races_list.html', {'races': races, 'registered_races': registered_races})

def race_detail(request, pk):
    race = get_object_or_404(Race, pk=pk)
    sessions = race.sessions.all().order_by('order').prefetch_related('results__registration__participant','results')
    participants = Participant.objects.filter(registrations__race=race).distinct()

    registrations = race.registrations.all().order_by('created_at')
    
    comment_form = CommentForm()
    return render(request, 'racing/race_detail.html', {'race': race, 'sessions': sessions, 'comment_form': comment_form})

@login_required
def race_register(request, race_pk):
    race = get_object_or_404(Race, pk=race_pk)
    cars = Car.objects.all()
    profile = request.user.profile
    try:
        participant = profile.participant
    except Exception:
        return redirect(f"{reverse('racing:participant_create')}?next=/races/{race_pk}/register/")

    exists = Registration.objects.filter(
        participant=participant,
        race=race
    ).exists()
    # уже зарегестрированно
    if exists:
        return redirect('racing:race_detail', pk=race.pk)
    
    if request.method == 'POST':
        form = RaceRegistrationForm(request.POST, profile=profile, race=race)
        if form.is_valid():
            reg = form.save(commit=False)
            reg.race = race        # <-- обязательное заполнение
            reg.save()
            return redirect('racing:race_detail', pk=race.pk)
    else:
        form = RaceRegistrationForm(profile=profile, race=race)
    return render(request, 'racing/race_register.html', {'race': race, 'form': form, 'cars': cars, 'participant': participant})

@login_required
def race_create(request):
    profile = request.user.profile
    if not profile.isAdmin():
        redirect('racing:races_list')

    if request.method == "POST":
        form = RaceForm(request.POST)
        if form.is_valid():
            race = form.save(commit=False)
            race.created_by = request.user.profile  # ← кто создал гонку
            race.save()
            return next_redirect(request, "racing:races_list")  # после создания — в список гонок
    else:
        form = RaceForm()

    return render(request, "racing/race_create.html", {"form": form})


@login_required
def race_unregister(request, race_pk):
    race = get_object_or_404(Race, pk=race_pk)
    profile = request.user.profile
    participant = profile.participant

    Registration.objects.filter(
        participant=participant,
        race=race
    ).delete()
    # race = get_object_or_404(Race, pk=race_pk)
    # participant_id = request.POST.get('participant_id')
    # car_id = request.POST.get('car_id')
    # participant = get_object_or_404(Participant, pk=participant_id, profile=request.user.profile)
    # car = get_object_or_404(Car, pk=car_id)
    # reg, created = Registration.objects.get_or_create(participant=participant, car=car, race=race)
    # if not created:
    #     reg.delete()
    return next_redirect(request, 'racing:races_list')

@login_required
@require_POST
def add_comment(request, race_pk):
    race = get_object_or_404(Race, pk=race_pk)
    form = CommentForm(request.POST)
    if form.is_valid():
        comment = form.save(commit=False)
        comment.race = race
        comment.profile = request.user.profile
        comment.save()
    return redirect('racing:race_detail', pk=race.pk)

@login_required
def race_session_create(request, race_pk):
    profile = request.user.profile
    if not profile.isAdmin():
        redirect('racing:races_list')

    race = get_object_or_404(Race, pk=race_pk)

    if request.method == "POST":
        form = RaceSessionForm(request.POST)
        if form.is_valid():
            race_session = form.save(commit=False)
            race_session.race = race
            race_session.save()
            return next_redirect(request, "racing:races_list")  # после создания — в список гонок
    else:
        form = RaceSessionForm()

    return render(request, "racing/race_session_create.html", {"form": form})

@login_required
def add_result(request, race_pk, session_pk):
    profile = request.user.profile
    if not profile.isAdmin():
        redirect('racing:races_list')

    race = get_object_or_404(Race, pk=race_pk)
    session = get_object_or_404(RaceSession, pk=session_pk, race=race)

    if request.method == "POST":
        form = RaceResultForm(request.POST)
        if form.is_valid():
            result = form.save(commit=False)
            result.session = session
            result.save()
            return redirect('racing:race_detail', pk=race.pk)
    else:
        form = RaceResultForm(initial={"session": session})

    return render(request, "racing/result_create.html", {"form": form, "race": race, "session": session})

```

## Панель администратора
```python
from django.contrib import admin
from .models import (
    Profile, Team, Car, Participant, Race, Registration,
    RaceSession, RaceResult, Comment
)

# -------------------------
# Profile Admin
# -------------------------
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role')
    list_filter = ('role',)
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'user__email')
    ordering = ('user__username',)


# -------------------------
# Team Admin
# -------------------------
@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ('name',)
    search_fields = ('name', 'description')


# -------------------------
# Car Admin
# -------------------------
@admin.register(Car)
class CarAdmin(admin.ModelAdmin):
    list_display = ('model',)
    search_fields = ('model',)


# -------------------------
# Participant Admin
# -------------------------
class RegistrationInline(admin.TabularInline):
    model = Registration
    extra = 0

@admin.register(Participant)
class ParticipantAdmin(admin.ModelAdmin):
    list_display = ('profile', 'participant_class', 'team', 'experience_years', 'created_at')
    list_filter = ('participant_class', 'team')
    search_fields = (
        'profile__user__username',
        'profile__user__first_name',
        'profile__user__last_name',
        'team__name',
    )
    date_hierarchy = 'created_at'
    inlines = [RegistrationInline]


# -------------------------
# Race Admin
# -------------------------
class RaceSessionInline(admin.TabularInline):
    model = RaceSession
    extra = 0

@admin.register(Race)
class RaceAdmin(admin.ModelAdmin):
    list_display = ('name', 'location', 'date', 'created_by', 'created_at')
    search_fields = ('name', 'location', 'created_by__user__username')
    list_filter = ('date',)
    date_hierarchy = 'date'
    inlines = [RaceSessionInline]


# -------------------------
# RaceSession Admin
# -------------------------
class RaceResultInline(admin.TabularInline):
    model = RaceResult
    extra = 0

@admin.register(RaceSession)
class RaceSessionAdmin(admin.ModelAdmin):
    list_display = ('name', 'race', 'order', 'start_time')
    search_fields = ('name', 'race__name')
    list_filter = ('race',)
    inlines = [RaceResultInline]


# -------------------------
# Registration Admin
# -------------------------
class RaceResultInlineForRegistration(admin.TabularInline):
    model = RaceResult
    extra = 0

@admin.register(Registration)
class RegistrationAdmin(admin.ModelAdmin):
    list_display = ('participant', 'race', 'car', 'created_at')
    search_fields = (
        'participant__profile__user__username',
        'race__name',
        'car__model',
    )
    list_filter = ('race',)
    date_hierarchy = 'created_at'
    inlines = [RaceResultInlineForRegistration]


# -------------------------
# RaceResult Admin
# -------------------------
@admin.register(RaceResult)
class RaceResultAdmin(admin.ModelAdmin):
    list_display = ('registration', 'session', 'total_time')
    search_fields = ('registration__participant__profile__user__username', 'session__race__name')
    list_filter = ('session', )


# -------------------------
# Comment Admin
# -------------------------
@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ('profile', 'race', 'comment_type', 'text', 'created_at')
    list_filter = ('comment_type',)
    search_fields = (
        'profile__user__username',
        'profile__user__first_name',
        'profile__user__last_name',
        'race__name',
        'text'
    )
    date_hierarchy = 'created_at'

```

