from django.db import models
from django.contrib.auth.models import AbstractUser


class Utilisateur(AbstractUser):
    """
    Étend AbstractUser pour se connecter avec l'email au lieu du username.
    """
    email = models.EmailField(unique=True)  # un seul compte par email

    # On dit à Django d'utiliser l'email comme identifiant de connexion
    USERNAME_FIELD = "email"
    # username reste obligatoire en interne (Django l'exige), mais ne sert
    # plus à se connecter
    REQUIRED_FIELDS = ["username"]


class Mesure(models.Model):
    """
    Une ligne = une mesure QoS envoyée par l'app mobile + le score QoE calculé.
    Les 5 champs ci-dessous utilisent EXACTEMENT les noms attendus par le
    modèle IA (cf. ia_utils.py / FEATURES).
    """
    utilisateur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name="mesures"
    )

    throughput = models.FloatField(verbose_name="Débit (throughput)")
    delay_qos = models.FloatField(verbose_name="Latence (delay_qos)")
    jitter = models.FloatField(verbose_name="Jitter")
    packet_loss = models.FloatField(verbose_name="Perte de paquets")
    avg_bitrate = models.FloatField(verbose_name="Débit moyen (avg_bitrate)")

    score_qoe = models.FloatField(verbose_name="Score QoE (MOS)")

    niveau_qualite = models.CharField(
        max_length=20,
        choices=[
            ("Excellente", "Excellente"),
            ("Bonne", "Bonne"),
            ("Moyenne", "Moyenne"),
            ("Faible", "Faible"),
            ("Très faible", "Très faible"),
        ]
    )

    mesure_le = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-mesure_le"]

    def __str__(self):
        return f"{self.utilisateur} - {self.mesure_le} - QoE={self.score_qoe}"