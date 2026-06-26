import os
import joblib
import shutil
import pandas as pd
# === 1. Localiser les dossiers ===
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # = ml-model/
models_dir = os.path.join(BASE_DIR, 'models')

# === 2. D'après ton évaluation : Random Forest est le meilleur ===
best_model_path = os.path.join(models_dir, 'random_forest.pkl')

# === 3. Créer une copie clairement nommée pour l'équipe Backend ===
final_model_path = os.path.join(models_dir, 'best_model.pkl')
shutil.copy(best_model_path, final_model_path)

print(f"Meilleur modèle copié vers : {final_model_path}")

# === 4. Vérification : recharger et tester rapidement ===
model = joblib.load(final_model_path)
scaler = joblib.load(os.path.join(models_dir, 'scaler.pkl'))

# Exemple de prédiction avec des valeurs fictives
exemple = pd.DataFrame([[300000, 100, 20, 1000, 1500]],
                        columns=['throughput', 'delay_qos', 'jitter', 'packet_loss', 'avg_bitrate'])
exemple_scaled = scaler.transform(exemple)
prediction = model.predict(exemple_scaled)

print(f"Test de prédiction : MOS = {prediction[0]:.2f}")