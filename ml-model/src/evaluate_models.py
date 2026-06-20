import pandas as pd
import numpy as np
import os
import joblib
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# === 1. Localiser le dossier models/ ===
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # = ml-model/
models_dir = os.path.join(BASE_DIR, 'models')

# === 2. Recharger les modèles et les données de test ===
model_lr = joblib.load(os.path.join(models_dir, 'linear_regression.pkl'))
model_dt = joblib.load(os.path.join(models_dir, 'decision_tree.pkl'))
model_rf = joblib.load(os.path.join(models_dir, 'random_forest.pkl'))
X_test_scaled, y_test = joblib.load(os.path.join(models_dir, 'test_data.pkl'))

# === 3. Évaluer chaque modèle ===
models = {
    'Régression Linéaire': model_lr,
    'Arbre de Décision': model_dt,
    'Random Forest': model_rf
}

results = []
for name, model in models.items():
    y_pred = model.predict(X_test_scaled)

    mae = mean_absolute_error(y_test, y_pred)
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2 = r2_score(y_test, y_pred)

    results.append({'Modèle': name, 'MAE': mae, 'RMSE': rmse, 'R²': r2})

# === 4. Tableau comparatif ===
df_results = pd.DataFrame(results)
print(df_results.to_string(index=False))

# === 5. Identifier le meilleur modèle ===
best_model_name = df_results.loc[df_results['RMSE'].idxmin(), 'Modèle']
print(f"\nMeilleur modèle : {best_model_name}")