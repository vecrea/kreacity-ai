import json
import requests
import uuid

# Créer un vecteur avec 4096 dimensions, toutes à 0.1
vector = [0.1] * 4096

# Exemple avec UUID
uuid_str = str(uuid.uuid4())
print(f"UUID généré: {uuid_str}")

# Exemple avec entier
int_id = 12345

# Test avec UUID
point_uuid = {
    "points": [
        {
            "id": uuid_str,
            "vector": vector,
            "payload": {
                "title": "Test avec UUID",
                "content": "Test content"
            }
        }
    ]
}

print("Envoi du point avec UUID...")
response = requests.put(
    "http://localhost:6333/collections/documents/points",
    headers={"Content-Type": "application/json"},
    data=json.dumps(point_uuid)
)
print(f"Réponse insertion UUID: {response.text}")

print("Vérification du point avec UUID...")
response = requests.get(
    f"http://localhost:6333/collections/documents/points/{uuid_str}"
)
print(f"Réponse vérification UUID: {response.text}")

# Test avec entier
point_int = {
    "points": [
        {
            "id": int_id,
            "vector": vector,
            "payload": {
                "title": "Test avec entier",
                "content": "Test content"
            }
        }
    ]
}

print("Envoi du point avec entier...")
response = requests.put(
    "http://localhost:6333/collections/documents/points",
    headers={"Content-Type": "application/json"},
    data=json.dumps(point_int)
)
print(f"Réponse insertion entier: {response.text}")

print("Vérification du point avec entier...")
response = requests.get(
    f"http://localhost:6333/collections/documents/points/{int_id}"
)
print(f"Réponse vérification entier: {response.text}")
