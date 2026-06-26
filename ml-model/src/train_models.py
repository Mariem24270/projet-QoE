import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import MinMaxScaler
import joblib

# === 1. Charger les données nettoyées (livrées par Membre A) ===
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # = ml-model/
csv_path = os.path.join(BASE_DIR, 'dataset_clean.csv')
df = pd.read_csv(csv_path)

features = ['throughput', 'delay_qos', 'jitter', 'packet_loss', 'avg_bitrate']
X = df[features]
y = df['mos']

# === 2. Split train/test (80% / 20%) ===
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# === 3. Normalisation (fit sur train uniquement) ===
scaler = MinMaxScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled  = scaler.transform(X_test)

# === 4. Entraînement des 3 modèles ===
model_lr = LinearRegression()
model_lr.fit(X_train_scaled, y_train)

model_dt = DecisionTreeRegressor(max_depth=6, random_state=42)
model_dt.fit(X_train_scaled, y_train)

model_rf = RandomForestRegressor(n_estimators=100, max_depth=8, random_state=42)
model_rf.fit(X_train_scaled, y_train)

print("Les 3 modèles sont entraînés !")

# === 5. Sauvegarder pour l'étape suivante (évaluation) ===
models_dir = os.path.join(BASE_DIR, 'models')
os.makedirs(models_dir, exist_ok=True)   # crée le dossier s'il n'existe pas

joblib.dump(model_lr, os.path.join(models_dir, 'linear_regression.pkl'))
joblib.dump(model_dt, os.path.join(models_dir, 'decision_tree.pkl'))
joblib.dump(model_rf, os.path.join(models_dir, 'random_forest.pkl'))
joblib.dump(scaler,   os.path.join(models_dir, 'scaler.pkl'))

# Garder aussi les données de test pour l'évaluation juste après
joblib.dump((X_test_scaled, y_test), os.path.join(models_dir, 'test_data.pkl'))