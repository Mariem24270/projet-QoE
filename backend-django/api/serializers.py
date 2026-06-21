from rest_framework import serializers
from .models import Utilisateur, Mesure


class InscriptionSerializer(serializers.ModelSerializer):
    # EmailField valide automatiquement le FORMAT (présence d'un @, domaine...).
    # Ça n'empêche pas une fausse adresse syntaxiquement correcte (sans
    # vérification par email, on ne peut pas garantir que la boîte existe).
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = Utilisateur
        fields = ["username", "email", "password"]

    def validate_email(self, value):
        if Utilisateur.objects.filter(email=value).exists():
            raise serializers.ValidationError("Un compte existe déjà avec cet email.")
        return value

    def create(self, validated_data):
        return Utilisateur.objects.create_user(**validated_data)


class MesureInputSerializer(serializers.Serializer):
    """
    Valide les 5 métriques QoS envoyées par l'app mobile, avec les
    NOMS EXACTS attendus par le modèle IA (throughput, delay_qos,
    jitter, packet_loss, avg_bitrate).
    """
    throughput = serializers.FloatField(min_value=0)
    delay_qos = serializers.FloatField(min_value=0)
    jitter = serializers.FloatField(min_value=0)
    packet_loss = serializers.FloatField(min_value=0)
    avg_bitrate = serializers.FloatField(min_value=0)


class MesureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mesure
        fields = [
            "id", "throughput", "delay_qos", "jitter",
            "packet_loss", "avg_bitrate", "score_qoe", "niveau_qualite", "mesure_le"
        ]
        read_only_fields = fields