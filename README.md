# README
## Other Changes:
- added env to docker-compose.yml (outside of git directory):
```
- TEST_DATABASE_URL=mysql2://rails_user:password@db:3306/rails_test
```
- also changed database accesses to use root since it's the easiest way to set up multiple dbs (for test and dev)
- has_secure_password and bcrypt

## TODOS
- User, get `jwt_service_test.rb` passing
