package com.yourcompany.yourapp

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import kotlinx.android.synthetic.main.activity_main.*
import androidx.recyclerview.widget.RecyclerView

class MainActivity : AppCompatActivity() {

    private val taskList = mutableListOf<String>()
    private lateinit var taskAdapter: TaskAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        taskAdapter = TaskAdapter(taskList)
        recyclerViewTasks.layoutManager = LinearLayoutManager(this)
        recyclerViewTasks.adapter = taskAdapter

        buttonAdd.setOnClickListener {
            val task = editTextTask.text.toString()
            if (task.isNotEmpty()) {
                taskList.add(task)
                taskAdapter.notifyItemInserted(taskList.size - 1)
                editTextTask.text.clear()
            }
        }
    }
}
