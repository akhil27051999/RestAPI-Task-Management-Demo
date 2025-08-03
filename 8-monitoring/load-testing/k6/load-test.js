import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 10 },
    { duration: '2m', target: 20 },
    { duration: '5m', target: 20 },
    { duration: '2m', target: 0 },
  ],
};

export default function() {
  // Test frontend
  let frontendResponse = http.get('http://task-frontend-service/');
  check(frontendResponse, {
    'frontend status is 200': (r) => r.status === 200,
    'frontend response time < 500ms': (r) => r.timings.duration < 500,
  });

  // Test API
  let apiResponse = http.get('http://task-frontend-service/api/tasks');
  check(apiResponse, {
    'api status is 200': (r) => r.status === 200,
    'api response time < 1000ms': (r) => r.timings.duration < 1000,
  });

  // Create task
  let createResponse = http.post('http://task-frontend-service/api/tasks', 
    JSON.stringify({
      title: 'K6 Test Task',
      description: 'Created by K6 load test',
      priority: 'LOW',
      completed: false
    }), 
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  check(createResponse, {
    'create task status is 201': (r) => r.status === 201,
  });

  sleep(1);
}
