# Automated Work Distribution System

## Core Principles
1. **All complex tasks must use sequential-thinking MCP for systematic planning**
2. **All code-related operations must use serena MCP for analysis and implementation**
3. **Tasks are automatically routed to the most appropriate specialist agent**

## Work Distribution Rules

### Language-Specific Task Routing
- Go projects: @golang-pro
- TypeScript/JavaScript projects: @typescript-pro  
- Rust projects: @rust-engineer
- Database operations: @postgres-pro
- Frontend/UI work: @frontend-developer
- Next.js full-stack: @nextjs-fullstack-expert
- React components: @react-specialist
- Code quality/review: @code-reviewer

### Architecture and Design Tasks
- Backend architecture: @golang-pro (comprehensive backend experience)
- System design: @golang-pro
- Database architecture: @postgres-pro
- Frontend architecture: @frontend-developer
- Full-stack architecture: @nextjs-fullstack-expert

### Support Tasks
- Code review and quality: @code-reviewer
- Performance optimization: appropriate domain expert
- Documentation: handle directly or route to domain expert

## Automatic Routing Logic
Task requests are processed in the following order:

1. **Sequential-thinking analysis for complex tasks**
   ```
   Analyze task complexity and domain requirements
   ```

2. **Task classification**
   - File extension analysis (.go, .ts, .js, .rs, .sql, etc.)
   - Project type detection (go.mod, package.json, Cargo.toml, etc.)
   - Keyword analysis ("architecture", "design", "database", "frontend", etc.)
   - Complexity evaluation

3. **Route to appropriate specialist agent**
   ```
   Based on analysis results, delegate to the most qualified expert
   ```

4. **Enforce MCP tool usage**
   ```
   Agents must use serena MCP for all code-related operations
   ```

## MCP Tool Usage Requirements
- **Sequential Thinking**: Mandatory for complex architecture design, multi-step planning, system optimization
- **Serena**: Required for all code reading, writing, searching, refactoring, and analysis operations
- **Agent delegation**: When applicable agent exists, route complex work to specialists
- **Direct response**: Only for simple questions, definitions, and basic explanations

## Available Specialist Agents

### Primary Development Agents
- **golang-pro**: Go language expert, microservices, backend architecture
- **typescript-pro**: TypeScript specialist, type safety, build optimization
- **frontend-developer**: UI/UX expert, React/Vue/Angular, responsive design
- **postgres-pro**: PostgreSQL specialist, database optimization, performance

### Specialized Agents  
- **nextjs-fullstack-expert**: Next.js full-stack development, SSR/SSG
- **react-specialist**: React ecosystem, component architecture, state management
- **rust-engineer**: Rust systems programming, memory safety, performance
- **code-reviewer**: Code quality, security analysis, best practices

### Meta Coordination
- **work-distributor**: Task analysis, agent coordination, quality assurance

## Task Flow Examples

### Go Microservice Implementation
```
User: "Implement gRPC-based user authentication service in Go"
→ Sequential-thinking analysis → Go domain detected → @golang-pro delegation
→ Sequential-thinking + serena MCP usage enforced
```

### Frontend Component Development
```
User: "Create responsive user dashboard component with TypeScript"
→ Sequential-thinking analysis → Frontend + TypeScript detected → @frontend-developer delegation
→ Sequential-thinking for architecture + serena for implementation
```

### Database Optimization
```
User: "Optimize PostgreSQL query performance for analytics workload"
→ Sequential-thinking analysis → Database domain detected → @postgres-pro delegation
→ Sequential-thinking for strategy + serena for SQL analysis
```

### Complex Architecture Design
```
User: "Design scalable microservices architecture for e-commerce platform"
→ Sequential-thinking analysis → Architecture + Backend detected → @golang-pro delegation
→ Comprehensive sequential-thinking planning + serena for implementation examples
```

## Quality Assurance

### Pre-delegation Checklist
- [ ] Sequential-thinking analysis completed for complex tasks
- [ ] Appropriate specialist agent identified
- [ ] Required MCP tools specified
- [ ] Clear task scope and deliverables defined
- [ ] Success criteria established

### Post-delegation Monitoring
- Track agent work progress and quality
- Verify proper MCP tool utilization
- Validate intermediate deliverables
- Provide additional support when needed
- Ensure knowledge transfer and documentation

## Success Metrics
- **Routing Accuracy**: >90% correct agent selection
- **MCP Compliance**: 100% sequential-thinking usage for complex tasks
- **Code Quality**: 100% serena MCP utilization for code operations
- **Response Time**: Task analysis and delegation within 30 seconds
- **Completion Rate**: >95% successful task completion

## Direct Response Criteria
Handle directly without agent delegation for:
- Simple concept explanations and definitions
- Quick code snippets (≤5 lines)
- General programming questions
- Basic debugging hints
- Tool/library recommendations

## Fallback Strategy
When no specialized agent is available:
1. **Go-related work** → @golang-pro (most comprehensive backend experience)
2. **Frontend work** → @frontend-developer
3. **Database work** → @postgres-pro
4. **Code quality** → @code-reviewer
5. **Complex technical work** → Most relevant available specialist

Always ensure optimal task distribution to qualified specialists while enforcing consistent MCP tool usage for maximum quality and efficiency.
