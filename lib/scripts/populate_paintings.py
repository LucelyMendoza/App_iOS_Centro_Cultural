#!/usr/bin/env python3
"""
Script para poblar Firestore con pinturas - Versión CORREGIDA
Ejecutar: python populate_firestore_fixed.py
"""

import json
import requests
from urllib.parse import quote

# Configuración de Firebase
FIREBASE_CONFIG = {
    "apiKey": "AIzaSyDpXCHbi1i7bpxnG7hyICxRgKXo9z1nY1c",
    "projectId": "beaconlocalization",
}

def add_painting_to_firestore(painting_id, painting_data):
    """Agregar una pintura a Firestore usando REST API CORRECTA"""
    
    # URL CORRECTA de Firestore REST API
    base_url = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_CONFIG['projectId']}/databases/(default)/documents"
    collection_path = "galerias/galeria1/pinturas"
    doc_url = f"{base_url}/{collection_path}/{painting_id}"
    
    # Convertir datos a formato Firestore
    firestore_data = {
        "fields": {
            "title": {"stringValue": painting_data["title"]},
            "author": {"stringValue": painting_data["author"]},
            "year": {"stringValue": painting_data["year"]},
            "details": {"stringValue": painting_data["details"]},
            "imagePath": {"stringValue": painting_data["imagePath"]},
            "position": {
                "mapValue": {
                    "fields": {
                        "x": {"doubleValue": painting_data["position"]["x"]},
                        "y": {"doubleValue": painting_data["position"]["y"]},
                        "z": {"doubleValue": painting_data["position"]["z"]}
                    }
                }
            },
            "detectionRadius": {"doubleValue": painting_data["detectionRadius"]}
        }
    }
    
    # Headers para la petición
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        # Hacer petición PATCH para crear/actualizar el documento
        response = requests.patch(
            doc_url,
            headers=headers,
            json=firestore_data,
            params={"key": FIREBASE_CONFIG["apiKey"]}
        )
        
        if response.status_code in [200, 201]:
            print(f"✅ Pintura {painting_id} creada exitosamente")
            return True
        else:
            print(f"❌ Error creando {painting_id}: {response.status_code}")
            print(f"   Respuesta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error de conexión para {painting_id}: {e}")
        return False

def main():
    """Función principal"""
    
    # Lista de pinturas
    paintings = [
        {
            'title': 'El Jardín de las Delicias',
            'author': 'El Bosco',
            'year': '1490-1500',
            'details': 'Tríptico que representa el paraíso, la tierra y el infierno',
            'imagePath': 'gs://tu-bucket/pinturas/jardin_delicias.jpg',
            'position': {'x': 0.8, 'y': 0.7, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Última Cena',
            'author': 'Leonardo da Vinci',
            'year': '1495-1498',
            'details': 'Representación de la última cena de Jesús con sus discípulos',
            'imagePath': 'gs://tu-bucket/pinturas/ultima_cena.jpg',
            'position': {'x': 1.2, 'y': 0.5, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'El Nacimiento de Venus',
            'author': 'Sandro Botticelli',
            'year': '1484-1486',
            'details': 'Venus emergiendo del mar como una mujer adulta',
            'imagePath': 'gs://tu-bucket/pinturas/nacimiento_venus.jpg',
            'position': {'x': 2.0, 'y': 0.8, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'Las Meninas',
            'author': 'Diego Velázquez',
            'year': '1656',
            'details': 'Retrato de la infanta Margarita y su séquito',
            'imagePath': 'gs://tu-bucket/pinturas/meninas.jpg',
            'position': {'x': 2.5, 'y': 1.0, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Ronda de Noche',
            'author': 'Rembrandt',
            'year': '1642',
            'details': 'Retrato grupal de la milicia cívica de Ámsterdam',
            'imagePath': 'gs://tu-bucket/pinturas/ronda_noche.jpg',
            'position': {'x': 0.5, 'y': 1.5, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'El Beso',
            'author': 'Gustav Klimt',
            'year': '1907-1908',
            'details': 'Pareja abrazada con vestimentas decorativas doradas',
            'imagePath': 'gs://tu-bucket/pinturas/el_beso.jpg',
            'position': {'x': 1.8, 'y': 1.7, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'Guernica',
            'author': 'Pablo Picasso',
            'year': '1937',
            'details': 'Representación del bombardeo de Guernica durante la guerra civil española',
            'imagePath': 'gs://tu-bucket/pinturas/guernica.jpg',
            'position': {'x': 2.2, 'y': 2.0, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Persistencia de la Memoria',
            'author': 'Salvador Dalí',
            'year': '1931',
            'details': 'Relojes derritiéndose en un paisaje onírico',
            'imagePath': 'gs://tu-bucket/pinturas/relojes_dali.jpg',
            'position': {'x': 0.7, 'y': 2.3, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'El Grito',
            'author': 'Edvard Munch',
            'year': '1893',
            'details': 'Figura andrógina en un momento de angustia existencial',
            'imagePath': 'gs://tu-bucket/pinturas/el_grito.jpg',
            'position': {'x': 1.5, 'y': 2.5, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Libertad Guiando al Pueblo',
            'author': 'Eugène Delacroix',
            'year': '1830',
            'details': 'Representación alegórica de la Revolución de Julio',
            'imagePath': 'gs://tu-bucket/pinturas/libertad_guiando.jpg',
            'position': {'x': 2.8, 'y': 0.3, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'Las Tres Gracias',
            'author': 'Rubens',
            'year': '1630-1635',
            'details': 'Representación mitológica de las diosas de la belleza',
            'imagePath': 'gs://tu-bucket/pinturas/tres_gracias.jpg',
            'position': {'x': 0.3, 'y': 1.0, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Joven de la Perla',
            'author': 'Johannes Vermeer',
            'year': '1665',
            'details': 'Retrato de una joven con un pendiente de perla',
            'imagePath': 'gs://tu-bucket/pinturas/joven_perla.jpg',
            'position': {'x': 1.0, 'y': 2.0, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'El Juicio Final',
            'author': 'Miguel Ángel',
            'year': '1536-1541',
            'details': 'Fresco que representa el segundo advenimiento de Cristo',
            'imagePath': 'gs://tu-bucket/pinturas/juicio_final.jpg',
            'position': {'x': 2.5, 'y': 1.5, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'Los Girasoles',
            'author': 'Vincent van Gogh',
            'year': '1888',
            'details': 'Serie de cuadros con girasoles en un jarrón',
            'imagePath': 'gs://tu-bucket/pinturas/girasoles.jpg',
            'position': {'x': 0.5, 'y': 2.8, 'z': 1.5},
            'detectionRadius': 0.8,
        },
        {
            'title': 'La Creación de Adán',
            'author': 'Miguel Ángel',
            'year': '1511',
            'details': 'Escena del Génesis donde Dios da vida a Adán',
            'imagePath': 'gs://tu-bucket/pinturas/creacion_adan.jpg',
            'position': {'x': 2.0, 'y': 0.3, 'z': 1.5},
            'detectionRadius': 0.8,
        },
    ]
    
    print("🎨 Iniciando población de pinturas en Firestore...")
    print(f"📍 Proyecto: {FIREBASE_CONFIG['projectId']}")
    print(f"📁 Colección: galerias/galeria1/pinturas")
    print(f"🔗 URL API: https://firestore.googleapis.com/v1/projects/{FIREBASE_CONFIG['projectId']}/databases/(default)/documents")
    print("-" * 50)
    
    success_count = 0
    total_count = len(paintings)
    
    # Procesar cada pintura
    for i, painting in enumerate(paintings):
        painting_id = f"p{i + 3}"  # p3 a p17
        print(f"📝 Procesando {painting_id}: {painting['title']}")
        
        if add_painting_to_firestore(painting_id, painting):
            success_count += 1
    
    print("-" * 50)
    print(f"✅ Proceso completado: {success_count}/{total_count} pinturas creadas")
    
    if success_count == total_count:
        print("🎉 ¡Todas las pinturas fueron creadas exitosamente!")
        print("🔍 Verifica en: https://console.firebase.google.com/u/0/project/beaconlocalization/firestore")
    else:
        print(f"⚠️  {total_count - success_count} pinturas tuvieron errores")

if __name__ == "__main__":
    main()