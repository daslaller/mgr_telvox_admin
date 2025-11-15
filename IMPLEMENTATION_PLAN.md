# MGR Telavox Admin - Comprehensive Implementation Plan

## Overview
This server app manages the connection between MGR (MyGadgetRepairs) and Telavox, polling for incoming calls, checking customers in MGR, and posting events to Firestore for the companion app to react to.

## Architecture Flow

```
Incoming Telavox Call
    ↓
Poll Telavox API (customized_poll_service)
    ↓
Check Customer in MGR API (mygadgetrepairs_client)
    ↓
Post to Firestore (synchronized_tracked_time_list)
    ↓
Companion App Reacts (via Firestore listeners)
```

## Core Components

### 1. Configuration Management
**Purpose**: Store and manage server-side settings (polling intervals, API credentials, etc.)

**Implementation**:
- Use existing `config_widget` package for UI
- Create configs for:
  - `telavox_config`: Telavox API credentials (JWT token or username/password)
  - `mgr_config`: MGR API key
  - `polling_config`: Polling interval, retry settings, etc.
  - `firestore_config`: Firestore collection paths, document structure

**Location**: `lib/Services/ConfigService.dart`

### 2. Polling Service
**Purpose**: Periodically poll Telavox API for incoming calls

**Implementation**:
- Use `customized_poll_service` with `AsyncSyncResultRepeatEngine` or `AdvancedRepeatEngine`
- Poll `TelavoxResource.callHistory` endpoint
- Filter for incoming calls only
- Track processed calls to avoid duplicates
- Configurable polling interval from config

**Location**: `lib/Services/TelavoxPollingService.dart`

**Key Features**:
- Start/Stop control
- Dynamic interval updates
- Error handling with retries
- Event stream for call events

### 3. Call Processing Service
**Purpose**: Process incoming calls, check MGR, and post to Firestore

**Implementation**:
- Receive call events from polling service
- Extract caller ID from Telavox call
- Query MGR API for customer matching caller ID
- Create call event document
- Post to Firestore using `SynchronizedTimedSet`

**Location**: `lib/Services/CallProcessingService.dart`

**Flow**:
1. Receive `TelavoxCall` from polling service
2. Extract `callerId` (phone number)
3. Query MGR: `Resources.customerCollection` with phone number filter
4. If customer found, create enriched call event
5. Add to `SynchronizedTimedSet<CallEvent>`
6. `FirebaseSyncService` automatically posts to Firestore

### 4. Firestore Integration
**Purpose**: Post call events to Firestore for companion app consumption

**Implementation**:
- Use `SynchronizedTimedSet<CallEvent>` to manage active calls
- Use `FirebaseSyncService` to sync to Firestore
- Collection path: `incomingCalls` (configurable)
- Document structure:
  ```dart
  {
    'callerId': String,
    'customerId': String?,
    'customerName': String?,
    'customerEmail': String?,
    'direction': String,
    'status': String,
    'timestamp': DateTime,
    'addedAt': DateTime,
    'expiresAt': DateTime,
    'syncStatus': String,
    'lastModifiedAt': DateTime,
  }
  ```

**Location**: `lib/Services/FirestoreCallService.dart`

### 5. User Management
**Purpose**: Manage which users can access the companion app

**Implementation**:
- Use existing `user_manager` package
- Add "Add Companion User" button in UI
- Store companion users in Firestore
- Integration with existing user management system

**Location**: `lib/Widgets/CompanionUserManager.dart`

### 6. Main Service Orchestrator
**Purpose**: Coordinate all services, manage lifecycle

**Implementation**:
- Singleton service that manages:
  - Polling service lifecycle
  - Call processing pipeline
  - Firestore sync service
  - Configuration updates
- Start/Stop functionality
- State management (running/stopped/paused)

**Location**: `lib/Services/MgrTelavoxService.dart`

### 7. UI Components

#### 7.1 Main Dashboard
**Location**: `lib/Widgets/MainDashboard.dart`

**Features**:
- Run/Stop button (large, prominent)
- Status indicator (running/stopped)
- Statistics display:
  - Total calls processed
  - Active calls
  - Last poll time
  - Errors count
- Quick actions:
  - View active calls
  - Manage users
  - Configure settings

#### 7.2 Run/Stop Control
**Location**: `lib/Widgets/ServiceControlWidget.dart`

**Features**:
- Large toggle button (Play/Pause icon)
- Visual state indicators
- Confirmation dialogs for stop
- Loading states during start/stop

#### 7.3 Configuration Panel
**Location**: `lib/Widgets/ConfigPanel.dart`

**Features**:
- Use existing `ConfigWidget` from `config_widget` package
- Sections for:
  - Telavox credentials
  - MGR API key
  - Polling settings
  - Firestore settings
- Real-time validation
- Save/Reset buttons

#### 7.4 User Management Panel
**Location**: `lib/Widgets/CompanionUserManager.dart`

**Features**:
- "Add Companion User" button (+ icon)
- List of companion users
- User search functionality
- Role assignment (if needed)
- Remove user functionality
- Integration with `user_manager` package

#### 7.5 Active Calls Monitor
**Location**: `lib/Widgets/ActiveCallsWidget.dart`

**Features**:
- Real-time list of active calls
- Call details (caller, customer, timestamp)
- Filter/search functionality
- Auto-refresh

## Data Models

### CallEvent Model
**Location**: `lib/Models/CallEvent.dart`

```dart
class CallEvent {
  final String uniqueIdentifier; // MD5 hash of callerId
  final String callerId;
  final String direction;
  final String status;
  final DateTime timestamp;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final Map<String, dynamic> metadata;
  
  Map<String, dynamic> toJson();
  factory CallEvent.fromTelavoxCall(TelavoxCall call, MgrCustomer? customer);
}
```

## Implementation Steps

### Phase 1: Foundation (Core Services)
1. ✅ Create `CallEvent` model
2. ✅ Create `ConfigService` wrapper
3. ✅ Create `TelavoxPollingService` with polling engine
4. ✅ Create `CallProcessingService` with MGR integration
5. ✅ Create `FirestoreCallService` with synchronized timed set
6. ✅ Create `MgrTelavoxService` orchestrator

### Phase 2: UI Components
7. ✅ Create `ServiceControlWidget` (Run/Stop button)
8. ✅ Create `MainDashboard` with status and stats
9. ✅ Create `ConfigPanel` using config_widget
10. ✅ Create `CompanionUserManager` widget
11. ✅ Create `ActiveCallsWidget` for monitoring

### Phase 3: Integration
12. ✅ Integrate all services in main app
13. ✅ Wire up UI to services
14. ✅ Add error handling and logging
15. ✅ Add state persistence (remember running state)

### Phase 4: Testing & Polish
16. ✅ Test polling with mock data
17. ✅ Test MGR customer lookup
18. ✅ Test Firestore posting
19. ✅ Test start/stop functionality
20. ✅ Test user management
21. ✅ Add loading states and error messages
22. ✅ Add logging and debugging tools

## File Structure

```
lib/
├── main.dart (existing)
├── Models/
│   └── CallEvent.dart
├── Services/
│   ├── ConfigService.dart
│   ├── TelavoxPollingService.dart
│   ├── CallProcessingService.dart
│   ├── FirestoreCallService.dart
│   └── MgrTelavoxService.dart
├── Widgets/
│   ├── MainDashboard.dart
│   ├── ServiceControlWidget.dart
│   ├── ConfigPanel.dart
│   ├── CompanionUserManager.dart
│   ├── ActiveCallsWidget.dart
│   ├── config_widget.dart (existing)
│   └── login_widget.dart (existing)
└── Utils/
    └── Logging.dart
```

## Configuration Schema

### telavox_config
```json
{
  "authType": "jwt|basic",
  "jwtToken": "",
  "username": "",
  "password": "",
  "pollIntervalSeconds": 30
}
```

### mgr_config
```json
{
  "apiKey": "",
  "baseUrl": "https://api.mygadgetrepairs.com"
}
```

### polling_config
```json
{
  "intervalSeconds": 30,
  "maxRetries": 3,
  "enableErrorRecovery": true,
  "concurrency": 1
}
```

### firestore_config
```json
{
  "collectionPath": "incomingCalls",
  "callLifetimeMinutes": 60,
  "cleanupIntervalMs": 250
}
```

## State Management

Use `ChangeNotifier` pattern for service state:
- `MgrTelavoxService` extends `ChangeNotifier`
- Expose `isRunning`, `isPaused`, `lastPollTime`, `stats`
- UI widgets listen to state changes
- Update UI reactively when service state changes

## Error Handling

1. **API Errors**:
   - Retry with exponential backoff
   - Log errors to console
   - Show user-friendly error messages
   - Continue polling on non-fatal errors

2. **Configuration Errors**:
   - Validate before starting service
   - Show validation errors in UI
   - Prevent start if invalid

3. **Firestore Errors**:
   - Retry failed writes
   - Log sync failures
   - Queue failed events for retry

## Security Considerations

1. **API Credentials**:
   - Store in Firestore configs (encrypted at rest)
   - Never log credentials
   - Validate before use

2. **Firestore Rules**:
   - Restrict write access to authenticated users
   - Validate document structure
   - Set appropriate TTL for call documents

3. **User Management**:
   - Only admins can add/remove companion users
   - Validate user permissions

## Testing Strategy

1. **Unit Tests**:
   - Test call processing logic
   - Test MGR customer lookup
   - Test Firestore document creation

2. **Integration Tests**:
   - Test polling → processing → Firestore flow
   - Test start/stop functionality
   - Test configuration updates

3. **Manual Testing**:
   - Test with real Telavox API (test account)
   - Test with real MGR API
   - Test Firestore posting
   - Test companion app reaction

## Dependencies

All required packages are already in `pubspec.yaml`:
- ✅ `telavox_client`
- ✅ `mygadgetrepairs_client`
- ✅ `customized_poll_service`
- ✅ `synchronized_tracked_time_list`
- ✅ `user_manager`
- ✅ `config_widget`
- ✅ `firebase_core`, `cloud_firestore`, `firebase_auth`

## Next Steps

1. Review and approve this plan
2. Start with Phase 1: Foundation
3. Implement services one by one
4. Test each service independently
5. Integrate services together
6. Build UI components
7. Final integration and testing

## Notes

- **Companion App**: This app only POSTS events to Firestore. The companion app listens to Firestore and reacts. We do NOT manage companion app settings here.
- **Polling**: All polling is server-side only. The companion app does NOT poll - it only reacts to Firestore events.
- **Configs**: All configurations are for this server app only (polling intervals, API keys, etc.)

