from locust import HttpUser, task, between

class TaskManagementUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login or setup if needed
        pass
    
    @task(3)
    def view_dashboard(self):
        self.client.get("/")
    
    @task(2)
    def get_tasks(self):
        self.client.get("/api/tasks")
    
    @task(1)
    def create_task(self):
        self.client.post("/api/tasks", json={
            "title": "Load Test Task",
            "description": "Created by load test",
            "priority": "MEDIUM",
            "completed": False
        })
    
    @task(1)
    def update_task(self):
        # Get a task first, then update
        response = self.client.get("/api/tasks")
        if response.status_code == 200:
            tasks = response.json()
            if tasks:
                task_id = tasks[0]["id"]
                self.client.put(f"/api/tasks/{task_id}", json={
                    "completed": True
                })
