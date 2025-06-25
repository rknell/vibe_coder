# 🎮 KANBAN BOARD DEVELOPER INSTRUCTIONS

## 🎯 MISSION OVERVIEW
This kanban system manages the Discord-style redesign of VibeCoder following **Clean Architecture** and **Warrior Protocol** standards with **granular ticket breakdown** for maximum development efficiency.

## 📋 KANBAN WORKFLOW

### 🔄 TICKET LIFECYCLE
```
Backlog → In Progress → Waiting for Test → In Test → Waiting for Review → In Review → Complete
```

### 🎯 TICKET ASSIGNMENT RULES
1. **One ticket per developer at a time** - Focus on completion over multitasking
2. **Follow dependency order** - Check \"Dependencies\" section before starting
3. **Architectural layer compliance** - Models → Services → UI Components
4. **Maximum 3-4 hour tickets** - All tickets designed for focused development sessions
5. **Communication required** - Update ticket status when moving between stages

## 🏗️ ARCHITECTURAL PROGRESSION (GRANULAR)

### 📊 PHASE 1: DATA MODEL FOUNDATION
- **DR001**: Agent Status Model *(2-3h)* - No dependencies
- **DR003**: Layout Preferences Model *(2-3h)* - No dependencies
- **DR002A**: MCP Content Infrastructure *(2h)* - No dependencies

**🚀 PARALLEL DEVELOPMENT**: All Phase 1 tickets can be developed simultaneously

### 📊 PHASE 1B: SPECIALIZED DATA MODELS
- **DR002B**: Inbox & Todo Models *(2-3h)* - Depends on DR002A
- **DR002C**: Notepad & Collection Management *(2h)* - Depends on DR002A & DR002B

**🔗 SEQUENTIAL DEPENDENCY**: DR002A → DR002B → DR002C

### 🔧 PHASE 2: SERVICE LAYER  
- **DR004**: Agent Status Service *(2-3h)* - Depends on DR001
- **DR006**: Layout Service *(2-3h)* - Depends on DR003
- **DR005A**: MCP Content Service Foundation *(2-3h)* - Depends on DR002C
- **DR005B**: MCP Server Integration *(2-3h)* - Depends on DR005A

**🚀 PARALLEL OPPORTUNITIES**: DR004 + DR006 + DR005A (after Phase 1 complete)

### 🎨 PHASE 3: UI LAYOUT FOUNDATION
- **DR007A**: Three-Panel Layout Foundation *(3-4h)* - Depends on DR003, DR006
- **DR007B**: Responsive Behavior & Animations *(3h)* - Depends on DR007A

**🔗 SEQUENTIAL DEPENDENCY**: DR007A → DR007B

### 🎯 PHASE 4: SPECIALIZED COMPONENTS
- **DR008**: Agent Sidebar Component *(3-4h)* - Depends on DR001, DR004
- **DR009**: Chat Panel Component *(2-3h)* - Depends on existing MessagingUI
- **DR010**: MCP Sidebar Component *(3-4h)* - Depends on DR002C, DR005B
- **DR011**: MCP Content Editors *(2-3h)* - Depends on DR005B

**🚀 PARALLEL DEVELOPMENT**: All Phase 4 tickets can be developed simultaneously after foundations

## 🎯 TICKET EXECUTION PROTOCOL

### 📋 **BEFORE STARTING A TICKET**
1. **Dependency Check**: Verify all dependent tickets are Complete
2. **Environment Setup**: Ensure latest code pulled and tests passing
3. **Ticket Understanding**: Read complete ticket specification
4. **Time Estimate**: Confirm ticket effort aligns with available time
5. **Status Update**: Move ticket to \"In Progress\" and communicate start

### ⚔️ **DURING TICKET DEVELOPMENT**
1. **TDD Protocol**: Write failing tests → Implement → Make tests pass
2. **Incremental Commits**: Commit frequently with clear messages
3. **Architectural Compliance**: Follow Clean Architecture + Warrior Protocols
4. **Zero Tolerance**: No linter errors, no functional widget builders
5. **Documentation**: Update inline docs and ticket notes

### 🏆 **TICKET COMPLETION CHECKLIST**
- [ ] All acceptance criteria met
- [ ] Zero linter errors (`flutter analyze`)
- [ ] All tests passing (`flutter test`)
- [ ] Test coverage >90% for new code  
- [ ] Performance benchmarks met (if specified)
- [ ] Code review ready (move to \"Waiting for Review\")

## 🔗 DEPENDENCY MANAGEMENT

### 🎯 **CRITICAL DEPENDENCY CHAINS**
```
Foundation Chain:
DR001 → DR004 → DR008 (Agent Status → Service → UI)

Content Chain:  
DR002A → DR002B → DR002C → DR005A → DR005B → DR010 → DR011
(Infrastructure → Models → Collection → Service → Integration → UI → Editors)

Layout Chain:
DR003 → DR006 → DR007A → DR007B
(Preferences → Service → Layout → Responsive)

Integration Chain:
DR007B + DR008 + DR009 + DR010 → Complete Discord UI
```

### ⚡ **PARALLEL OPPORTUNITIES**
- **Start Together**: DR001 + DR003 + DR002A (no dependencies)
- **Service Layer**: DR004 + DR006 + DR005A (after foundations)
- **Final Integration**: DR008 + DR009 + DR010 + DR011 (after core services)

## 🧪 TESTING STRATEGY

### 📋 **GRANULAR TESTING APPROACH**
- **Unit Tests**: Every ticket includes comprehensive unit test coverage
- **Integration Tests**: Test interaction points between dependent tickets  
- **Performance Tests**: Specific benchmarks for UI and service performance
- **Regression Tests**: Ensure existing functionality preserved
- **End-to-End Tests**: Complete user workflow validation

### 🎯 **TESTING CHECKPOINTS**
1. **Individual Ticket**: 90%+ unit test coverage
2. **Phase Completion**: Integration tests for phase interactions
3. **Epic Completion**: Full end-to-end Discord workflow testing

## 📊 PROGRESS TRACKING

### 🎮 **TICKET STATUS DEFINITIONS**
- **Backlog**: Ready for development, dependencies met
- **In Progress**: Actively being developed by assigned developer
- **Waiting for Test**: Development complete, testing in progress
- **In Test**: Test execution and validation
- **Waiting for Review**: Ready for code review
- **In Review**: Code review in progress
- **Complete**: All criteria met, merged, and verified

### 📈 **MILESTONE TRACKING**
- **Foundation Milestone**: All Phase 1 & 1B tickets complete
- **Service Milestone**: All Phase 2 tickets complete
- **Layout Milestone**: All Phase 3 tickets complete
- **Integration Milestone**: All Phase 4 tickets complete

## 🚨 ESCALATION PROTOCOL

### ⚠️ **BLOCKING ISSUES**
1. **Dependency Violation**: Cannot start ticket due to incomplete dependencies
2. **Technical Blocker**: Unexpected technical challenge requiring architecture decision
3. **Scope Creep**: Requirements expanding beyond ticket specification
4. **Performance Issue**: Implementation not meeting performance benchmarks

### 📢 **COMMUNICATION PROTOCOL**
- **Daily Standups**: Progress updates and blocker identification
- **Ticket Comments**: Technical decisions and implementation notes
- **Architecture Reviews**: Major design decisions require team consultation
- **Emergency Protocol**: Critical blockers require immediate team attention

## 🏆 SUCCESS METRICS

### ✅ **INDIVIDUAL TICKET SUCCESS**
- Completed within estimated time (±50%)
- All acceptance criteria met
- Zero architectural violations
- Complete test coverage
- Performance benchmarks achieved

### ✅ **EPIC SUCCESS** 
- Discord-style three-panel layout fully operational
- Real-time MCP content synchronization working
- Responsive behavior and animations smooth (60fps)
- All existing functionality preserved
- Zero regression bugs
- Performance targets met (<100ms layout, 5s content sync)

**⚰️ GRANULAR EXECUTION WITH WARRIOR PRECISION OR ARCHITECTURAL DEATH! ⚰️** 

For testings avoid using flutter commands - use `./tool/get_failed_tests.sh` to get the failed tests. This will give you the list of tests that failed and you can run them individually instead of having to dig through hundreds of tests.

You have full permission to run any testing commands you need to.