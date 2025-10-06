#!/usr/bin/env swift
import Foundation
import NaturalLanguage

// ============================================================================
// GENERADOR DE VECTORES PRE-COMPUTADOS PARA RAG
// Ejecutar ANTES de compilar la app para generar vectores
// ============================================================================

class VectorPreprocessor {
    private let embedding: NLEmbedding?
    
    init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    // Generar archivo de vectores pre-calculados
    func generateVectorBundle(
        documents: [String],
        outputPath: String
    ) throws {
        guard let embedding = embedding else {
            throw RAGError.embeddingNotAvailable
        }
        
        print("🔄 Pre-procesando \(documents.count) documentos...")
        
        var vectorDocs: [PrecomputedVector] = []
        
        for (index, doc) in documents.enumerated() {
            guard let vector = embedding.vector(for: doc) else {
                print("⚠️ No se pudo vectorizar documento \(index)")
                continue
            }
            
            let vectorDoc = PrecomputedVector(
                id: UUID().uuidString,
                content: doc,
                embedding: vector.map { Float($0) }
            )
            
            vectorDocs.append(vectorDoc)
            print("✅ [\(index + 1)/\(documents.count)] Procesado")
        }
        
        // Serializar a JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(vectorDocs)
        
        // Guardar archivo
        let url = URL(fileURLWithPath: outputPath)
        try data.write(to: url)
        
        print("💾 Guardado en: \(outputPath)")
        print("📊 Total vectores: \(vectorDocs.count)")
        print("📦 Tamaño: \(Double(data.count) / 1024.0 / 1024.0) MB")
    }
}

// Modelo para vectores pre-computados
struct PrecomputedVector: Codable {
    let id: String
    let content: String
    let embedding: [Float]
}

// Errores del sistema
enum RAGError: LocalizedError {
    case embeddingNotAvailable
    case vectorizationFailed
    case bundleFileNotFound
    
    var errorDescription: String? {
        switch self {
        case .embeddingNotAvailable:
            return "NLEmbedding no disponible"
        case .vectorizationFailed:
            return "Fallo al vectorizar query"
        case .bundleFileNotFound:
            return "Archivo de vectores no encontrado en el bundle"
        }
    }
}

// ============================================================================
// DOCUMENTOS PARA EL RAG - PERSONALIZA AQUÍ
// ============================================================================

let documents = [
    // Información de la empresa
    "Nuestra empresa fue fundada en 2020 en Monterrey, Nuevo León, México.",
    "Ofrecemos servicios de desarrollo iOS con Swift y SwiftUI.",
    "Ofrecemos servicios de desarrollo Android con Kotlin y Jetpack Compose.",
    "Horario de atención: Lunes a Viernes de 9:00 AM a 6:00 PM CST.",
    "Contamos con un equipo de 15 desarrolladores senior especializados.",
    "Usamos metodologías ágiles con sprints de 2 semanas.",
    "Los proyectos típicamente tardan entre 3 a 6 meses.",
    "Implementamos MVVM y Clean Architecture en nuestros proyectos.",
    "Ofrecemos planes de mantenimiento mensual con actualizaciones y fixes.",
    "Precios: apps básicas desde $50,000 MXN, intermedias $150,000 MXN.",
    
    // Información sobre TuristAgent
    "TuristAgent es una aplicación móvil para turistas que visitan México.",
    "La app incluye un escáner de códigos QR para obtener información sobre lugares turísticos.",
    "TuristAgent proporciona guías turísticas interactivas y recomendaciones personalizadas.",
    "La aplicación funciona offline para áreas con poca conectividad.",
    "Incluye mapas detallados de las principales ciudades turísticas de México.",
    "TuristAgent ofrece traducciones automáticas a múltiples idiomas.",
    "La app cuenta con un sistema de recomendaciones basado en preferencias del usuario.",
    "Incluye información sobre eventos culturales y festivales locales.",
    "TuristAgent proporciona información sobre transporte público y rutas turísticas.",
    "La aplicación incluye reseñas y calificaciones de otros turistas.",
    
    // Información técnica
    "La aplicación está desarrollada en Swift para iOS y SwiftUI para la interfaz.",
    "Utiliza Core ML para procesamiento de imágenes y reconocimiento de códigos QR.",
    "Implementa MapKit para funcionalidad de mapas y geolocalización.",
    "Usa UserDefaults para almacenamiento local de preferencias del usuario.",
    "La app está optimizada para iOS 15.0 y versiones superiores.",
    "Implementa un sistema de caché para contenido offline.",
    "Utiliza Combine framework para manejo reactivo de datos.",
    "La arquitectura sigue el patrón MVVM con separación clara de responsabilidades.",
    "Implementa tests unitarios y de integración para garantizar calidad.",
    "La app está disponible en App Store con calificación 4.8 estrellas.",
]

// ============================================================================
// EJECUCIÓN PRINCIPAL
// ============================================================================

print("===========================================")
print("🔧 GENERADOR DE VECTORES PRE-COMPUTADOS")
print("===========================================\n")

let preprocessor = VectorPreprocessor()

do {
    try preprocessor.generateVectorBundle(
        documents: documents,
        outputPath: "./precomputed_vectors.json"
    )
    
    print("\n✅ COMPLETADO")
    print("📝 Ahora agrega 'precomputed_vectors.json' a tu proyecto Xcode")
    print("📋 Instrucciones:")
    print("   1. Arrastra precomputed_vectors.json a tu proyecto Xcode")
    print("   2. Asegúrate que esté en 'Target Membership'")
    print("   3. Verifica en Build Phases > Copy Bundle Resources")
    
} catch {
    print("❌ Error: \(error)")
    exit(1)
}