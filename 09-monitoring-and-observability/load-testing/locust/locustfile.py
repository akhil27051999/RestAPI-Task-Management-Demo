from locust import HttpUser, task, between
import json
import random

class TaskManagementUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a user starts"""
        self.task_ids = []
    
    @task(3)
    def get_all_tasks(self):
        """Get all tasks - most common operation"""
        response = self.client.get("/api/tasks")
        if response.status_code == 200:
            tasks = response.json()
            if tasks:
                # Store task IDs for other operations
                self.task_ids = [task['id'] for task in tasks if 'id' in task]
    
    @task(2)
    def create_task(self):
        """Create a new task"""
        task_data = {
            "title": f"Load Test Task {random.randint(1, 1000)}",
            "description": f"This is a load test task created at {random.randint(1, 1000)}",
            "status": random.choice(["PENDING", "IN_PROGRESS", "COMPLETED"])
        }
        
        response = self.client.post(
            "/api/tasks",
            json=task_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 201:
            task = response.json()
            if 'id' in task:
                self.task_ids.append(task['id'])
    
    @task(2)
    def get_task_by_id(self):
        """Get a specific task by ID"""
        if self.task_ids:
            task_id = random.choice(self.task_ids)
            self.client.get(f"/api/tasks/{task_id}")
    
    @task(1)
    def update_task(self):
        """Update an existing task"""
        if self.task_ids:
            task_id = random.choice(self.task_ids)
            update_data = {
                "title": f"Updated Task {random.randint(1, 1000)}",
                "description": "Updated during load test",
                "status": random.choice(["IN_PROGRESS", "COMPLETED"])
            }
            
            self.client.put(
                f"/api/tasks/{task_id}",
                json=update_data,
                headers={"Content-Type": "application/json"}
            )
    
    @task(1)
    def delete_task(self):
        """Delete a task"""
        if len(self.task_ids) > 5:  # Keep some tasks for other operations
            task_id = self.task_ids.pop()
            self.client.delete(f"/api/tasks/{task_id}")
    
    @task(1)
    def health_check(self):
        """Check application health"""
        self.client.get("/actuator/health")
    
    @task(1)
    def metrics_check(self):
        """Check metrics endpoint"""
        self.client.get("/actuator/prometheus")
