#!/usr/bin/env swift
import Foundation
import NaturalLanguage

// ============================================================================
// PRUEBA SIMPLE DE BÚSQUEDA DE VECTORES (SIN API)
// Para probar solo la funcionalidad de búsqueda semántica
// ============================================================================

// Modelo para vectores pre-computados
struct PrecomputedVector: Codable {
    let id: String
    let content: String
    let embedding: [Float]
}

// Resultado de búsqueda
struct SearchResult {
    let content: String
    let score: Float
    let id: String
}

// Store de vectores pre-computados
class PrecomputedVectorStore {
    private var documents: [PrecomputedVector] = []
    private let embedding: NLEmbedding?
    
    init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }
    
    // Cargar vectores desde archivo JSON
    func loadFromFile(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        
        print("📦 Cargando vectores desde: \(filePath)")
        
        let data = try Data(contentsOf: url)
        documents = try JSONDecoder().decode([PrecomputedVector].self, from: data)
        
        print("✅ Cargados \(documents.count) vectores pre-computados")
    }
    
    // Búsqueda semántica
    func search(query: String, topK: Int = 5) throws -> [SearchResult] {
        guard let embedding = embedding else {
            throw NSError(domain: "RAGError", code: 1, userInfo: [NSLocalizedDescriptionKey: "NLEmbedding no disponible"])
        }
        
        // Generar embedding del query
        guard let queryVector = embedding.vector(for: query) else {
            throw NSError(domain: "RAGError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Fallo al vectorizar query"])
        }
        
        let queryVectorFloat = queryVector.map { Float($0) }
        
        // Buscar en vectores pre-calculados
        var results: [(PrecomputedVector, Float)] = []
        
        for doc in documents {
            let similarity = cosineSimilarity(queryVectorFloat, doc.embedding)
            results.append((doc, similarity))
        }
        
        results.sort { $0.1 > $1.1 }
        
        return results.prefix(topK).map { doc, score in
            SearchResult(
                content: doc.content,
                score: score,
                id: doc.id
            )
        }
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    var count: Int { documents.count }
}

// ============================================================================
// PRUEBAS DE BÚSQUEDA
// ============================================================================

struct VectorSearchTest {
    static func main() {
        print("===========================================")
        print("🔍 PRUEBA DE BÚSQUEDA SEMÁNTICA")
        print("===========================================\n")
        
        // Ruta al archivo de vectores
        let vectorsPath = "./precomputed_vectors.json"
        
        // Inicializar store
        let vectorStore = PrecomputedVectorStore()
        
        do {
            // Cargar vectores
            try vectorStore.loadFromFile(filePath: vectorsPath)
            
            print("✅ Store inicializado correctamente\n")
            
            // Preguntas de prueba
            let testQueries = [
                "¿Qué es TuristAgent?",
                "tecnologías de desarrollo",
                "precios y costos",
                "funcionalidad offline",
                "características para turistas",
                "horarios de atención",
                "metodologías de trabajo",
                "arquitectura de la app"
            ]
            
            // Probar cada búsqueda
            for (index, query) in testQueries.enumerated() {
                print("🔍 BÚSQUEDA \(index + 1): \"\(query)\"")
                print("─" * 50)
                
                do {
                    let results = try vectorStore.search(query: query, topK: 3)
                    
                    for (resultIndex, result) in results.enumerated() {
                        print("📄 [\(resultIndex + 1)] Score: \(String(format: "%.3f", result.score))")
                        print("   \(result.content)")
                        print()
                    }
                    
                } catch {
                    print("❌ Error en búsqueda: \(error)")
                }
                
                print("=" * 60 + "\n")
            }
            
            // Estadísticas
            print("📊 ESTADÍSTICAS:")
            print("   • Total documentos: \(vectorStore.count)")
            print("   • Búsquedas realizadas: \(testQueries.count)")
            print("   • Todas las búsquedas usan vectores pre-computados")
            
        } catch {
            print("❌ Error al inicializar: \(error)")
        }
    }
}

// Extensión para repetir strings
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Ejecutar las pruebas
VectorSearchTest.main()
