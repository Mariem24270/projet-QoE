from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework import status
from django.contrib.auth import authenticate

from .serializers import InscriptionSerializer, MesureInputSerializer, MesureSerializer
from .models import Mesure
from .ia_utils import predire_qoe, niveau_depuis_score
from rest_framework_simplejwt.tokens import RefreshToken

from rest_framework import status
from .models import Utilisateur



class InscriptionView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = [] # <-- INDISPENSABLE : Empêche Django de chercher un Token JWT pour s'inscrire !

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
    permission_classes = [AllowAny]
    authentication_classes = []  # Indispensable pour éviter les conflits de token

    def post(self, request):
        username_or_email = request.data.get('username')
        password = request.data.get('password')

        # Par défaut, on suppose qu'il a saisi son e-mail
        email_to_authenticate = username_or_email

        # Si l'utilisateur a saisi son NOM D'UTILISATEUR (pas de @), on cherche son email en BDD
        if username_or_email and "@" not in username_or_email:
            try:
                user_obj = Utilisateur.objects.get(username=username_or_email)
                email_to_authenticate = user_obj.email
            except Utilisateur.DoesNotExist:
                pass  # Si pas trouvé, on laisse l'ancienne valeur pour que authenticate gère l'échec

        # Puisque USERNAME_FIELD = "email", on doit passer l'adresse email dans le paramètre 'username' !
        user = authenticate(username=email_to_authenticate, password=password)

        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                'token': str(refresh.access_token),
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Identifiants incorrects ou rejetés.'}, status=status.HTTP_400_BAD_REQUEST)
        


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