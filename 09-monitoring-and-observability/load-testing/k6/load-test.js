import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up to 10 users
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 20 }, // Ramp up to 20 users
    { duration: '5m', target: 20 }, // Stay at 20 users
    { duration: '2m', target: 0 },  // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'], // 95% of requests must complete below 2s
    http_req_failed: ['rate<0.05'],    // Error rate must be below 5%
    errors: ['rate<0.05'],             // Custom error rate
  },
};

const BASE_URL = __ENV.TARGET_HOST || 'http://localhost:8080';

// Test data
const taskTitles = [
  'Complete project documentation',
  'Review code changes',
  'Deploy to production',
  'Update dependencies',
  'Fix critical bug',
  'Implement new feature',
  'Write unit tests',
  'Performance optimization'
];

const taskStatuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];

let createdTaskIds = [];

export default function () {
  // Test scenarios with different weights
  const scenario = Math.random();
  
  if (scenario < 0.4) {
    // 40% - Get all tasks
    getAllTasks();
  } else if (scenario < 0.6) {
    // 20% - Create task
    createTask();
  } else if (scenario < 0.8) {
    // 20% - Get task by ID
    getTaskById();
  } else if (scenario < 0.9) {
    // 10% - Update task
    updateTask();
  } else {
    // 10% - Delete task
    deleteTask();
  }
  
  // Health check occasionally
  if (Math.random() < 0.1) {
    healthCheck();
  }
  
  sleep(1);
}

function getAllTasks() {
  const response = http.get(`${BASE_URL}/api/tasks`);
  
  const success = check(response, {
    'GET /api/tasks status is 200': (r) => r.status === 200,
    'GET /api/tasks response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
  
  if (success && response.json()) {
    const tasks = response.json();
    if (Array.isArray(tasks) && tasks.length > 0) {
      // Store some task IDs for other operations
      createdTaskIds = tasks.slice(0, 10).map(task => task.id).filter(id => id);
    }
  }
}

function createTask() {
  const taskData = {
    title: taskTitles[Math.floor(Math.random() * taskTitles.length)],
    description: `Load test task created at ${new Date().toISOString()}`,
    status: taskStatuses[Math.floor(Math.random() * taskStatuses.length)]
  };
  
  const response = http.post(`${BASE_URL}/api/tasks`, JSON.stringify(taskData), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  const success = check(response, {
    'POST /api/tasks status is 201': (r) => r.status === 201,
    'POST /api/tasks response time < 2000ms': (r) => r.timings.duration < 2000,
    'POST /api/tasks returns task with ID': (r) => {
      try {
        const task = r.json();
        return task && task.id;
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
  
  if (success && response.json() && response.json().id) {
    createdTaskIds.push(response.json().id);
    // Keep only last 20 task IDs to prevent memory issues
    if (createdTaskIds.length > 20) {
      createdTaskIds = createdTaskIds.slice(-20);
    }
  }
}

function getTaskById() {
  if (createdTaskIds.length === 0) {
    return;
  }
  
  const taskId = createdTaskIds[Math.floor(Math.random() * createdTaskIds.length)];
  const response = http.get(`${BASE_URL}/api/tasks/${taskId}`);
  
  const success = check(response, {
    'GET /api/tasks/{id} status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    'GET /api/tasks/{id} response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
}

function updateTask() {
  if (createdTaskIds.length === 0) {
    return;
  }
  
  const taskId = createdTaskIds[Math.floor(Math.random() * createdTaskIds.length)];
  const updateData = {
    title: `Updated: ${taskTitles[Math.floor(Math.random() * taskTitles.length)]}`,
    description: `Updated during load test at ${new Date().toISOString()}`,
    status: taskStatuses[Math.floor(Math.random() * taskStatuses.length)]
  };
  
  const response = http.put(`${BASE_URL}/api/tasks/${taskId}`, JSON.stringify(updateData), {
    headers: { 'Content-Type': 'application/json' },
  });
  
  const success = check(response, {
    'PUT /api/tasks/{id} status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    'PUT /api/tasks/{id} response time < 2000ms': (r) => r.timings.duration < 2000,
  });
  
  errorRate.add(!success);
}

function deleteTask() {
  if (createdTaskIds.length <= 5) {
    return; // Keep some tasks for other operations
  }
  
  const taskId = createdTaskIds.pop();
  const response = http.del(`${BASE_URL}/api/tasks/${taskId}`);
  
  const success = check(response, {
    'DELETE /api/tasks/{id} status is 204 or 404': (r) => r.status === 204 || r.status === 404,
    'DELETE /api/tasks/{id} response time < 1000ms': (r) => r.timings.duration < 1000,
  });
  
  errorRate.add(!success);
}

function healthCheck() {
  const response = http.get(`${BASE_URL}/actuator/health`);
  
  const success = check(response, {
    'Health check status is 200': (r) => r.status === 200,
    'Health check response time < 500ms': (r) => r.timings.duration < 500,
    'Health check status is UP': (r) => {
      try {
        const health = r.json();
        return health && health.status === 'UP';
      } catch (e) {
        return false;
      }
    },
  });
  
  errorRate.add(!success);
}
