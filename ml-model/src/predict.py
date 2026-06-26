import os
import joblib
import pandas as pd

# === Chemins vers les fichiers du modèle ===
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # = ml-model/
models_dir = os.path.join(BASE_DIR, 'models')

# === Charger une seule fois (pas à chaque appel) ===
model = joblib.load(os.path.join(models_dir, 'best_model.pkl'))
scaler = joblib.load(os.path.join(models_dir, 'scaler.pkl'))

FEATURES = ['throughput', 'delay_qos', 'jitter', 'packet_loss', 'avg_bitrate']


def predict_qoe(throughput, latency, jitter, packet_loss, avg_bitrate):
    """
    Prédit le score MOS (QoE) à partir des métriques réseau.
    """
    donnees = pd.DataFrame(
        [[throughput, latency, jitter, packet_loss, avg_bitrate]],
        columns=FEATURES
    )

    donnees_scaled = scaler.transform(donnees)
    mos_predit = model.predict(donnees_scaled)[0]
    mos_predit = round(float(mos_predit), 2)
    mos_predit = max(1.0, min(5.0, mos_predit))

    niveau = get_qoe_level(mos_predit)

    return {
        'mos': mos_predit,
        'niveau': niveau
    }


def get_qoe_level(mos):
    """Convertit le score MOS en niveau de qualité (selon le cahier des charges)."""
    if mos >= 4.0:
        return "Excellente"
    elif mos >= 3.0:
        return "Bonne"
    elif mos >= 2.0:
        return "Moyenne"
    else:
        return "Faible"


if __name__ == "__main__":
    resultat = predict_qoe(
        throughput=300000,
        latency=100,
        jitter=20,
        packet_loss=1000,
        avg_bitrate=1500
    )
    print(f"Score MOS : {resultat['mos']}")
    print(f"Niveau : {resultat['niveau']}")