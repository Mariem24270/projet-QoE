from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework import status
from django.contrib.auth import authenticate

from .serializers import InscriptionSerializer, MesureInputSerializer, MesureSerializer
from .models import Mesure
from .ia_utils import predire_qoe, niveau_depuis_score


class InscriptionView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = InscriptionSerializer(data=request.data)
        if serializer.is_valid():
            utilisateur = serializer.save()
            refresh = RefreshToken.for_user(utilisateur)
            return Response({
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """
    POST /api/login/
    Login par EMAIL + mot de passe (pas username).
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")

        if not email or not password:
            return Response(
                {"erreur": "Email et mot de passe requis."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # USERNAME_FIELD = "email" dans models.py -> authenticate() utilise
        # bien l'email ici, malgré le nom du paramètre "username" côté Django.
        utilisateur = authenticate(request, username=email, password=password)

        if utilisateur is None:
            return Response(
                {"erreur": "Email ou mot de passe incorrect."},
                status=status.HTTP_401_UNAUTHORIZED
            )

        refresh = RefreshToken.for_user(utilisateur)
        return Response({
            "access": str(refresh.access_token),
            "refresh": str(refresh),
        }, status=status.HTTP_200_OK)


class PredictionView(APIView):
    # AllowAny : tout le monde peut appeler cet endpoint, connecté ou non.
    # On distingue les deux cas À L'INTÉRIEUR de la vue (voir plus bas).
    permission_classes = [AllowAny]

    def post(self, request):
        input_serializer = MesureInputSerializer(data=request.data)
        if not input_serializer.is_valid():
            return Response(input_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        donnees = input_serializer.validated_data

        try:
            score = predire_qoe(
                donnees["throughput"],
                donnees["delay_qos"],
                donnees["jitter"],
                donnees["packet_loss"],
                donnees["avg_bitrate"],
            )
        except FileNotFoundError as e:
            return Response(
                {"erreur": "Le modèle IA n'est pas encore disponible.", "detail": str(e)},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        niveau = niveau_depuis_score(score)

        # request.user.is_authenticated vaut True seulement si un token JWT
        # valide a été envoyé dans la requête (Authorization: Bearer ...).
        # Sinon, request.user est un AnonymousUser et is_authenticated vaut False.
        utilisateur_connecte = request.user.is_authenticated

        if utilisateur_connecte:
            # Étape 3 du cahier des charges : sauvegarde uniquement si connecté.
            mesure = Mesure.objects.create(
                utilisateur=request.user,
                throughput=donnees["throughput"],
                delay_qos=donnees["delay_qos"],
                jitter=donnees["jitter"],
                packet_loss=donnees["packet_loss"],
                avg_bitrate=donnees["avg_bitrate"],
                score_qoe=score,
                niveau_qualite=niveau,
            )
            reponse = MesureSerializer(mesure).data
            reponse["sauvegarde"] = True
            return Response(reponse, status=status.HTTP_201_CREATED)
        else:
            # Pas connecté : on renvoie le résultat mais on ne sauvegarde rien.
            return Response({
                "throughput": donnees["throughput"],
                "delay_qos": donnees["delay_qos"],
                "jitter": donnees["jitter"],
                "packet_loss": donnees["packet_loss"],
                "avg_bitrate": donnees["avg_bitrate"],
                "score_qoe": score,
                "niveau_qualite": niveau,
                "sauvegarde": False,
            }, status=status.HTTP_200_OK)


class HistoriqueView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        mesures = request.user.mesures.all()
        serializer = MesureSerializer(mesures, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)