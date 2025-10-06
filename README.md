# 🤖 FifaRag - Sistema RAG para TuristAgent

Sistema de **Retrieval-Augmented Generation** con vectores pre-computados para responder preguntas sobre TuristAgent.

## 🚀 Uso Rápido

### 1️⃣ **Generar Vectores** (Una sola vez)
```bash
swift generate_vectors.swift
```
Crea `precomputed_vectors.json` con 30 documentos vectorizados.

### 2️⃣ **Probar Búsqueda Semántica** (Sin API)
```bash
swift Vector_Search_Test.swift
```
Muestra documentos más relevantes para cada query.

### 3️⃣ **RAG Completo con ChatGPT**
1. Edita `RAG_Playground.swift` línea 241:
   ```swift
   let openAIKey = "sk-tu-api-key-aqui"
   ```
2. Ejecuta:
   ```bash
   swift RAG_Playground.swift
   ```

## 📁 Archivos

- `generate_vectors.swift` - Genera vectores de 30 documentos
- `precomputed_vectors.json` - Vectores generados (287 KB)
- `Vector_Search_Test.swift` - Prueba búsqueda semántica
- `RAG_Playground.swift` - RAG completo con ChatGPT

## 🎯 Qué Hace

### **Búsqueda Semántica**
- Encuentra documentos relevantes usando vectores
- **Sin internet** - funciona offline
- **Instantáneo** - vectores pre-computados

### **RAG con ChatGPT**
- Combina búsqueda + generación de texto
- Respuestas inteligentes basadas en documentos
- **Contexto relevante** automático

## 📊 Ejemplo de Uso

```bash
# Pregunta: "¿Qué es TuristAgent?"
🔍 Documentos encontrados:
  [1] Score: 0.582 - TuristAgent es una aplicación móvil para turistas que visitan México.
  [2] Score: 0.580 - Incluye información sobre eventos culturales y festivales locales.

🤖 RESPUESTA:
TuristAgent es una aplicación móvil diseñada específicamente para turistas que visitan México. 
La app proporciona información sobre eventos culturales y festivales locales, ayudando a los 
visitantes a descubrir experiencias auténticas durante su viaje.
```

## ⚡ Ventajas

- **Rápido** - Vectores pre-computados
- **Offline** - Búsqueda sin internet
- **Preciso** - Respuestas basadas en documentos
- **Económico** - Solo genera embedding del query

## 🔧 Integración en App

```swift
// En tu app SwiftUI
let rag = PrecomputedRAG(openAIKey: "tu-key")
try rag.initialize(filePath: "precomputed_vectors")

let response = try await rag.query("¿Qué es TuristAgent?")
print(response.answer)
```

## 📝 Personalizar

Edita los documentos en `generate_vectors.swift` (líneas 90-126) y regenera:

```bash
swift generate_vectors.swift
```

¡Listo! 🎉 Tu RAG está funcionando.
