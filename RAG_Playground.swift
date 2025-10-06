#!/usr/bin/env swift
import Foundation
import NaturalLanguage

// ============================================================================
// PLAYGROUND PARA PROBAR RAG CON VECTORES PRE-COMPUTADOS
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

// Respuesta del RAG
struct RAGResponse {
    let answer: String
    let sources: [String]
    let scores: [Float]
}

// Errores del sistema
enum RAGError: LocalizedError {
    case embeddingNotAvailable
    case vectorizationFailed
    case bundleFileNotFound
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .embeddingNotAvailable:
            return "NLEmbedding no disponible"
        case .vectorizationFailed:
            return "Fallo al vectorizar query"
        case .bundleFileNotFound:
            return "Archivo de vectores no encontrado"
        case .apiError(let message):
            return "Error de API: \(message)"
        }
    }
}

// ============================================================================
// STORE DE VECTORES PRE-COMPUTADOS
// ============================================================================

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
    
    // Búsqueda (RÁPIDA - sin generar embeddings)
    func search(query: String, topK: Int = 3) throws -> [SearchResult] {
        guard let embedding = embedding else {
            throw RAGError.embeddingNotAvailable
        }
        
        // Solo generamos embedding del query (1 vez)
        guard let queryVector = embedding.vector(for: query) else {
            throw RAGError.vectorizationFailed
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
// RAG SYSTEM CON CHATGPT
// ============================================================================

class PrecomputedRAG {
    private let vectorStore: PrecomputedVectorStore
    private let apiKey: String
    private let systemPrompt: String
    
    init(openAIKey: String, systemPrompt: String? = nil) {
        self.vectorStore = PrecomputedVectorStore()
        self.apiKey = openAIKey
        self.systemPrompt = systemPrompt ?? """
        Eres un asistente especializado en TuristAgent, una aplicación móvil para turistas en México.
        Responde SOLO con información del contexto proporcionado.
        Si no sabes algo, di "No tengo esa información en mi base de conocimientos".
        Sé conciso, preciso y amigable.
        """
    }
    
    // Inicializar (cargar vectores del archivo)
    func initialize(filePath: String) throws {
        try vectorStore.loadFromFile(filePath: filePath)
    }
    
    // Query principal
    func query(_ question: String, topK: Int = 3) async throws -> RAGResponse {
        // 1. Buscar documentos relevantes (rápido - usa vectores pre-computados)
        let results = try vectorStore.search(query: question, topK: topK)
        
        print("🔍 Documentos encontrados:")
        for (index, result) in results.enumerated() {
            print("  [\(index + 1)] Score: \(String(format: "%.3f", result.score))")
            print("      \(result.content)")
            print()
        }
        
        // 2. Construir contexto
        let context = results
            .enumerated()
            .map { index, result in
                "[Fuente \(index + 1)] \(result.content)"
            }
            .joined(separator: "\n\n")
        
        // 3. Crear prompt
        let prompt = """
        \(systemPrompt)
        
        CONTEXTO:
        \(context)
        
        PREGUNTA: \(question)
        
        RESPUESTA:
        """
        
        // 4. Llamar a ChatGPT
        let answer = try await callChatGPT(prompt: prompt)
        
        return RAGResponse(
            answer: answer,
            sources: results.map { $0.content },
            scores: results.map { $0.score }
        )
    }
    
    private func callChatGPT(prompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RAGError.apiError("Respuesta inválida")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw RAGError.apiError("HTTP \(httpResponse.statusCode): \(errorData)")
        }
        
        let chatResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        return chatResponse.choices.first?.message.content ?? "No se pudo obtener respuesta"
    }
}

// Respuesta de OpenAI
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// ============================================================================
// PRUEBAS DEL RAG
// ============================================================================

struct RAGPlayground {
    static func main() async {
        print("===========================================")
        print("🤖 RAG PLAYGROUND - TURISTAGENT")
        print("===========================================\n")
        
        // ⚠️ IMPORTANTE: Reemplaza con tu API key de OpenAI
        let openAIKey = "your_api_key_here"
        
        // Verificar que la API key esté configurada
        if openAIKey == "your_api_key_here" {
            print("❌ ERROR: Debes configurar tu API key de OpenAI")
            print("📝 Edita la variable 'openAIKey' en este archivo")
            print("🔗 Obtén tu key en: https://platform.openai.com/api-keys")
            return
        }
        
        // Ruta al archivo de vectores
        let vectorsPath = "./precomputed_vectors.json"
        
        // Inicializar RAG
        let rag = PrecomputedRAG(openAIKey: openAIKey)
        
        do {
            // Cargar vectores
            try rag.initialize(filePath: vectorsPath)
            
            print("✅ RAG inicializado correctamente\n")
            
            // Preguntas de prueba
            let testQuestions = [
                "¿Qué es TuristAgent?",
                "¿En qué tecnologías está desarrollada la app?",
                "¿Cuáles son los precios de desarrollo?",
                "¿La app funciona offline?",
                "¿Qué funcionalidades tiene para turistas?"
            ]
            
            // Probar cada pregunta
            for (index, question) in testQuestions.enumerated() {
                print("=" * 50)
                print("❓ PREGUNTA \(index + 1): \(question)")
                print("=" * 50)
                
                do {
                    let response = try await rag.query(question)
                    
                    print("🤖 RESPUESTA:")
                    print(response.answer)
                    print()
                    
                } catch {
                    print("❌ Error: \(error)")
                }
                
                print("\n" + "─" * 50 + "\n")
            }
            
        } catch {
            print("❌ Error al inicializar RAG: \(error)")
        }
    }
}

// Extensión para repetir strings (útil para formateo)
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Ejecutar el playground
Task {
    await RAGPlayground.main()
}
