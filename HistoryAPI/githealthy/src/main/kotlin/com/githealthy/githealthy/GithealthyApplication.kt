package com.githealthy.githealthy

import com.mongodb.ConnectionString
import com.mongodb.client.MongoClients
import org.bson.Document
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.web.bind.annotation.*
import java.time.LocalDate

@SpringBootApplication
class GithealthyApplication

fun main(args: Array<String>) {
    runApplication<GithealthyApplication>(*args)
}

@RestController
@RequestMapping("/api/users")
class UserController {

    // Use environment variables or other secure methods to load sensitive information like connection strings
    private val connectionString = ""
    private val mongoClient = MongoClients.create(connectionString)
    private val database = mongoClient.getDatabase("GitHealthy")
    private val collection = database.getCollection("users")

    @PostMapping("/add")
    fun addUser(@RequestBody userData: UserData): String {
        val userId = userData.userid

        // Check if user already exists
        val existingUser = collection.find(Document("userid", userId)).first()
        return if (existingUser != null) {
            "User already exists"
        } else {
            // Add user to database
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
    fun addBarcode(@PathVariable userId: String, @PathVariable barcode: Int): Document {
        val currentDate = LocalDate.now().toString()
        val barcodeDocument = Document("barcode", barcode)
            .append("date", currentDate)
        val result = collection.updateOne(Document("userid", userId), Document("\$addToSet", Document("barcodes", barcodeDocument)))
        if (result.modifiedCount == 0L) {
            // User not found, create a new document with the user and barcode
            val newUserDocument = Document("userid", userId).append("barcodes", listOf(barcodeDocument))
            collection.insertOne(newUserDocument)
            return newUserDocument
        }
        return collection.find(Document("userid", userId)).first()!!
    }

    @DeleteMapping("/{userId}/barcodes/{barcode}")
    fun deleteBarcode(@PathVariable userId: String, @PathVariable barcode: Int): String {
        val result = collection.updateOne(Document("userid", userId), Document("\$pull", Document("barcodes", barcode)))
        return if (result.modifiedCount > 0) "Barcode deleted successfully" else "Barcode not found"
    }

    data class UserData(val userid: String)
}
