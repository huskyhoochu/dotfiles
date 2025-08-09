# Automated Work Distribution Routing Rules

## File Extension-Based Routing
```yaml
file_extensions:
  .go: "@golang-pro"
  .py: "@typescript-pro"  # Fallback until python-specific agent available
  .js: "@typescript-pro"
  .ts: "@typescript-pro"
  .jsx: "@typescript-pro"
  .tsx: "@typescript-pro"
  .rs: "@rust-engineer"
  .sql: "@postgres-pro"
  .md: "direct_response"  # Documentation handled directly
```

## Project Type-Based Routing
```yaml
project_indicators:
  go.mod: "@golang-pro"
  package.json: "@typescript-pro"
  Cargo.toml: "@rust-engineer"
  requirements.txt: "@typescript-pro"  # Fallback for Python
  pyproject.toml: "@typescript-pro"   # Fallback for Python
  docker-compose.yml: "@golang-pro"   # Often backend-related
```

## Keyword-Based Routing
```yaml
architecture_keywords:
  - "architecture": "@golang-pro"      # Go expert handles backend architecture
  - "design": "@golang-pro"
  - "system design": "@golang-pro"
  - "microservice": "@golang-pro"
  - "API design": "@golang-pro"
  - "database schema": "@postgres-pro"
  - "project structure": "@golang-pro"

language_specific_keywords:
  golang:
    - "goroutine": "@golang-pro"
    - "channel": "@golang-pro"
    - "go mod": "@golang-pro"
    - "gRPC": "@golang-pro"
    - "gin": "@golang-pro"
    - "fiber": "@golang-pro"
  
  typescript:
    - "typescript": "@typescript-pro"
    - "type safety": "@typescript-pro"
    - "interface": "@typescript-pro"
    - "generic": "@typescript-pro"
    - "tsconfig": "@typescript-pro"
  
  frontend:
    - "react": "@frontend-developer"
    - "component": "@frontend-developer"
    - "UI": "@frontend-developer"
    - "frontend": "@frontend-developer"
    - "responsive": "@frontend-developer"
    - "next.js": "@nextjs-fullstack-expert"
    - "nextjs": "@nextjs-fullstack-expert"
  
  database:
    - "postgresql": "@postgres-pro"
    - "postgres": "@postgres-pro"
    - "SQL": "@postgres-pro"
    - "database": "@postgres-pro"
    - "query": "@postgres-pro"
    - "optimization": "@postgres-pro"

  rust:
    - "rust": "@rust-engineer"
    - "cargo": "@rust-engineer"
    - "memory safety": "@rust-engineer"
    - "ownership": "@rust-engineer"
    - "borrow": "@rust-engineer"

  review:
    - "code review": "@code-reviewer"
    - "refactor": "@code-reviewer"
    - "quality": "@code-reviewer"
    - "security": "@code-reviewer"
    - "optimization": "@code-reviewer"
```

## Context-Based Priority Rules
```yaml
priority_rules:
  1. File extension (direct language identification)
  2. Project indicators (project root files)
  3. Keyword matching (task content analysis)
  4. Task complexity (simple vs complex implementation)
  5. Agent availability (load balancing)
```

## Routing Logic Flow
```
1. File path analysis → Check extensions
2. Project root scan → Identify project type
3. Request content keyword analysis → Classify task type
4. Complexity evaluation → Agent delegation vs direct response
5. Optimal agent selection → Task delegation
```

## Exception Handling Rules
```yaml
direct_response_conditions:
  - Simple definitions or explanations
  - Quick code snippets (≤5 lines)
  - General programming concept questions
  - Debugging hints or simple advice
  - Tool/library recommendations

fallback_strategies:
  unknown_language: "@golang-pro"      # Most comprehensive backend experience
  frontend_specific: "@frontend-developer"
  database_specific: "@postgres-pro"
  code_quality: "@code-reviewer"
  complex_architecture: "@golang-pro"
```

## Task Complexity Classification
```
Complexity Low + Language Specific = Direct Response
Complexity Medium + Language Specific = Language Specialist Agent
Complexity High + Architecture = Backend Architecture Expert
Complexity High + Language Specific = Language Agent + Sequential Thinking
Code Quality/Review = Code Reviewer Agent
Database Operations = PostgreSQL Expert
```

## Agent Specialization Matrix
```yaml
golang-pro:
  - Go language and ecosystem
  - Microservices architecture
  - Backend system design
  - gRPC and REST APIs
  - Concurrency patterns
  - Performance optimization

typescript-pro:
  - TypeScript type system
  - JavaScript ecosystem
  - Type safety patterns
  - Build optimization
  - Node.js backend
  - Frontend frameworks

frontend-developer:
  - React, Vue, Angular
  - UI/UX implementation
  - Responsive design
  - Component architecture
  - Web standards
  - Accessibility

nextjs-fullstack-expert:
  - Next.js framework
  - Full-stack development
  - SSR/SSG patterns
  - React ecosystem
  - Deployment optimization

postgres-pro:
  - PostgreSQL administration
  - Query optimization
  - Database design
  - Performance tuning
  - Backup/recovery
  - Security hardening

react-specialist:
  - React ecosystem
  - Component patterns
  - State management
  - Hooks optimization
  - Performance tuning

rust-engineer:
  - Rust language
  - Systems programming
  - Memory safety
  - Performance critical code
  - WebAssembly
  - CLI tools

code-reviewer:
  - Code quality analysis
  - Security vulnerabilities
  - Best practices enforcement
  - Technical debt reduction
  - Performance review
  - Documentation quality

work-distributor:
  - Task analysis and routing
  - Agent coordination
  - MCP tool enforcement
  - Quality assurance
  - Workload optimization
```
