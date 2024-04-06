package com.githealthy.githealthy

import com.mongodb.ConnectionString
import com.mongodb.client.MongoClients
import org.bson.Document
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.json.JSONObject
import kotlinx.serialization.json.Json
import java.net.URL

@SpringBootApplication
class GithealthyApplication

fun main(args: Array<String>) {
    runApplication<GithealthyApplication>(*args)
}

@RestController
@RequestMapping("/api")
class UserController {

    private val connectionString =  "mongodb+srv://v34l:serv@githealthy.39trsfo.mongodb.net/?retryWrites=true&w=majority&appName=GitHealthy"

    private val mongoClient = MongoClients.create(connectionString)
    private val database = mongoClient.getDatabase("GitHealthy")
    private val collection = database.getCollection("users")

    @PostMapping("/add")
    fun addUser(@RequestBody userData: UserData): String {
        val userId = userData.userid

        val existingUser = collection.find(Document("userid", userId)).first()
        return if (existingUser != null) {
           "User already exists"
        } else {
            val userDocument = Document("userid", userId)
            collection.insertOne(userDocument)
            "User added successfully"
        }
    }

    @GetMapping("/{userId}/barcodes")
    fun getUserBarcodes(@PathVariable userId: String): List<Document> {
        val user = collection.find(Document("userid", userId)).first()
        return user?.getList("barcodes", Document::class.java) ?: emptyList()
    }

@PostMapping("/{userId}/barcodes/{barcode}")
fun addBarcode(
    @PathVariable userId: String,
    @PathVariable barcode: String,
    @RequestParam imageUrl: String,
    @RequestParam productName: String
): ResponseEntity<Any> {
    try {
        // Validate imageUrl and productName
        if (imageUrl.isEmpty() || productName.isEmpty()) {
            return ResponseEntity.badRequest().body("Image URL and product name are required")
        }

        // Create a document with barcode, date, image URL, and product name
        val currentDate = LocalDate.now().toString()
        val barcodeDocument = Document("barcode", barcode)
            .append("date", currentDate)
            .append("image_front_url", imageUrl)
            .append("product_name", productName)

        // Your code to update the database with the barcodeDocument
        
        return ResponseEntity.ok().build() // Return a success response
    } catch (e: Exception) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error adding barcode: ${e.message}")
    }
}


 

    @DeleteMapping("/{userId}/barcodes/{barcode}")
    fun deleteBarcode(@PathVariable userId: String, @PathVariable barcode: String): String {
        val result = collection.updateOne(Document("userid", userId), Document("\$pull", Document("barcodes", barcode)))
        return if (result.modifiedCount > 0) "Barcode deleted successfully" else "Barcode not found"
    }

    @DeleteMapping("/{userId}")
    fun deleteUser(@PathVariable userId: String): String {
    val result = collection.deleteOne(Document("userid", userId))
    return if (result.deletedCount > 0) "User deleted successfully" else "User not found"
    }
    
    data class UserData(val userid: String)
}
