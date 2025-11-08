# README
## Other Changes:
- added env to docker-compose.yml (outside of git directory):
```
- TEST_DATABASE_URL=mysql2://rails_user:password@db:3306/rails_test
```
- also changed database accesses to use root since it's the easiest way to set up multiple dbs (for test and dev)
- has_secure_password and bcrypt
- I'm changing the db structure a bit so that expert_assignments expert_id is a foreign key into the users table (instead of expert_profiles).
- expert_id -> user_id in expert_assignments table
- relatedly, in the "GET /api/expert-queue/updates" endpoint, expertId is an index into the Users table

## Text version of table specs
```
USERS
bigint id PK
string username UK (unique, not null)
string password_digest (not null)
datetime last_active_at


CONVERSATIONS
bigint id PK
string title (not null)
string status (not null, default: 'waiting')
bigint initiator_id FK (not null)
bigint assigned_expert_id FK (nullable)
datetime last_message_at

MESSAGES
bigint id PK
bigint conversation_id FK (not null)
bigint sender_id FK (not null)
string sender_role (not null, enum: [initiator, expert])
text content (not null)
boolean is_read (not null, default: false)

EXPERT_PROFILES
bigint id PK
bigint user_id FK (not null, unique)
text bio
json knowledge_base_links


EXPERT_ASSIGNMENTS
bigint id PK
bigint conversation_id FK (not null)
bigint expert_id FK (not null)
string status (not null, default: 'active')
datetime assigned_at (not null)
datetime resolved at
```
