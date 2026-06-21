from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import InscriptionView, PredictionView, HistoriqueView, LoginView

urlpatterns = [
    path("api/inscription/", InscriptionView.as_view(), name="inscription"),
    path("api/login/", LoginView.as_view(), name="login"),
    path("api/refresh/", TokenRefreshView.as_view(), name="refresh"),
    path("api/predict/", PredictionView.as_view(), name="predict"),
    path("api/historique/", HistoriqueView.as_view(), name="historique"),
]

