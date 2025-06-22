package com.example.todoapp

import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

class MainActivity : AppCompatActivity() {
    private lateinit var taskAdapter: TaskAdapter
    private val taskList = mutableListOf<Task>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val taskInput = findViewById<EditText>(R.id.taskInput)
        val addButton = findViewById<Button>(R.id.addButton)
        val recyclerView = findViewById<RecyclerView>(R.id.recyclerView)

        taskAdapter = TaskAdapter(taskList) { position ->
            taskList.removeAt(position)
            taskAdapter.notifyItemRemoved(position)
        }

        recyclerView.layoutManager = LinearLayoutManager(this)
        recyclerView.adapter = taskAdapter

        addButton.setOnClickListener {
            val taskText = taskInput.text.toString()
            if (taskText.isNotBlank()) {
                taskList.add(Task(taskText))
                taskAdapter.notifyItemInserted(taskList.size - 1)
                taskInput.text.clear()
            }
        }
    }
}
