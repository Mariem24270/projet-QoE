import os
import joblib
import pandas as pd
from django.conf import settings

# Chemins vers les fichiers livrés par l'équipe IA.
# Place ces 2 fichiers dans ia_models/ : best_model.pkl ET scaler.pkl
MODELE_PATH = os.path.join(settings.BASE_DIR, "ia_models", "best_model.pkl")
SCALER_PATH = os.path.join(settings.BASE_DIR, "ia_models", "scaler.pkl")

# Ordre EXACT des colonnes utilisé par l'équipe IA à l'entraînement.
# Ne JAMAIS changer cet ordre : le scaler et le modèle s'attendent
# à recevoir les colonnes précisément dans cet ordre-là.
FEATURES = ["throughput", "delay_qos", "jitter", "packet_loss", "avg_bitrate"]

# Chargement paresseux : on ne charge les fichiers qu'au premier appel,
# pas à l'import du module. Si les .pkl ne sont pas encore là, le reste
# du backend (auth, historique...) continue de fonctionner normalement.
_modele = None
_scaler = None


def _charger_modele_et_scaler():
    global _modele, _scaler
    if _modele is None or _scaler is None:
        if not os.path.exists(MODELE_PATH):
            raise FileNotFoundError(
                f"Modèle IA introuvable : {MODELE_PATH}\n"
                f"Place best_model.pkl dans le dossier ia_models/."
            )
        if not os.path.exists(SCALER_PATH):
            raise FileNotFoundError(
                f"Scaler introuvable : {SCALER_PATH}\n"
                f"Place scaler.pkl dans le dossier ia_models/ "
                f"(obligatoire : le modèle a été entraîné sur des données normalisées)."
            )
        _modele = joblib.load(MODELE_PATH)
        _scaler = joblib.load(SCALER_PATH)
    return _modele, _scaler


def predire_qoe(throughput, delay_qos, jitter, packet_loss, avg_bitrate):
    """
    Prédit le score MOS (QoE) à partir des 5 métriques réseau.
    Étapes : construire un DataFrame dans le bon ordre de colonnes,
    normaliser avec le scaler de l'équipe IA, puis prédire.
    """
    modele, scaler = _charger_modele_et_scaler()

    donnees = pd.DataFrame(
        [[throughput, delay_qos, jitter, packet_loss, avg_bitrate]],
        columns=FEATURES
    )

    # ÉTAPE OBLIGATOIRE : le modèle a été entraîné sur des données mises à
    # l'échelle (MinMaxScaler). Sans cette transformation, la prédiction
    # serait fausse (pas d'erreur visible, juste un résultat incorrect).
    donnees_scaled = scaler.transform(donnees)

    score = float(modele.predict(donnees_scaled)[0])
    score = max(1.0, min(5.0, round(score, 2)))
    return score


def niveau_depuis_score(score):
    """
    Convertit le score MOS en catégorie lisible.
    On garde 5 niveaux côté backend (affichage), même si le script de
    l'équipe IA n'en utilise que 4 en interne — c'est notre choix d'UX,
    indépendant du modèle lui-même.
    """
    if score >= 4.5:
        return "Excellente"
    elif score >= 4.0:
        return "Bonne"
    elif score >= 3.0:
        return "Moyenne"
    elif score >= 2.0:
        return "Faible"
    else:
        return "Très faible"