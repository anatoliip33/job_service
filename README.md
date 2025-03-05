# JobService

**A simple Elixir-based HTTP service for processing jobs with dependencies, sorting tasks in execution order, and generating a Bash script representation.**

## Installation

```bash
git clone https://github.com/your-repo/job_processor.git
cd job_processor
mix deps.get
mix run --no-halt
```

## API Endpoints  

### POST `/jobs`  
**Sorts the tasks and returns execution order in JSON.**  

#### Request:  
- **Method:** `POST`  
- **URL:** `http://localhost:4000/jobs`  
- **Headers:**  
  ```json
  {
    "Content-Type": "application/json"
  }
- **Body:**  
  ```json
  {
    "tasks": [
      { "name": "task-1", "command": "touch /tmp/file1" },
      { "name": "task-2", "command": "cat /tmp/file1", "requires": ["task-3"] },
      { "name": "task-3", "command": "echo 'Hello World!' > /tmp/file1", "requires": ["task-1"] },
      { "name": "task-4", "command": "rm /tmp/file1", "requires": ["task-2", "task-3"] }
    ]
  }
