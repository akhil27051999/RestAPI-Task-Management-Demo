const API_BASE_URL = '/api';

const taskForm = document.getElementById('taskForm');
const tasksList = document.getElementById('tasksList');
const totalTasksEl = document.getElementById('totalTasks');
const completedTasksEl = document.getElementById('completedTasks');
const pendingTasksEl = document.getElementById('pendingTasks');

document.addEventListener('DOMContentLoaded', loadTasks);

taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const taskData = {
        title: document.getElementById('taskTitle').value,
        description: document.getElementById('taskDescription').value,
        status: 'PENDING'
    };
    
    try {
        await createTask(taskData);
        taskForm.reset();
        loadTasks();
    } catch (error) {
        alert('Error creating task: ' + error.message);
    }
});

async function loadTasks() {
    try {
        const response = await fetch(`${API_BASE_URL}/tasks`);
        const tasks = await response.json();
        displayTasks(tasks);
        updateStats(tasks);
    } catch (error) {
        console.error('Error loading tasks:', error);
        tasksList.innerHTML = '<p>Error loading tasks</p>';
    }
}

async function createTask(taskData) {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(taskData)
    });
    if (!response.ok) throw new Error('Failed to create task');
    return response.json();
}

async function updateTask(id, updates) {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates)
    });
    if (!response.ok) throw new Error('Failed to update task');
    return response.json();
}

async function deleteTask(id) {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, { method: 'DELETE' });
    if (!response.ok) throw new Error('Failed to delete task');
}

function displayTasks(tasks) {
    if (tasks.length === 0) {
        tasksList.innerHTML = '<p>No tasks found</p>';
        return;
    }
    
    tasksList.innerHTML = tasks.map(task => `
        <div class="task-item ${task.status === 'COMPLETED' ? 'completed' : ''}">
            <div class="task-info">
                <h4>${task.title}</h4>
                <p>${task.description || 'No description'}</p>
                <span class="task-status status-${task.status}">${task.status}</span>
            </div>
            <div class="task-actions">
                ${task.status !== 'COMPLETED' ? 
                    `<button class="complete-btn" onclick="completeTask(${task.id})">Complete</button>` : 
                    '<span>✓ Completed</span>'
                }
                <button class="delete-btn" onclick="removeTask(${task.id})">Delete</button>
            </div>
        </div>
    `).join('');
}

function updateStats(tasks) {
    const total = tasks.length;
    const completed = tasks.filter(task => task.status === 'COMPLETED').length;
    const pending = total - completed;
    
    totalTasksEl.textContent = total;
    completedTasksEl.textContent = completed;
    pendingTasksEl.textContent = pending;
}

async function completeTask(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/tasks/${id}`);
        const task = await response.json();
        await updateTask(id, { ...task, status: 'COMPLETED' });
        loadTasks();
    } catch (error) {
        alert('Error completing task: ' + error.message);
    }
}

async function removeTask(id) {
    if (confirm('Are you sure?')) {
        try {
            await deleteTask(id);
            loadTasks();
        } catch (error) {
            alert('Error deleting task: ' + error.message);
        }
    }
}
