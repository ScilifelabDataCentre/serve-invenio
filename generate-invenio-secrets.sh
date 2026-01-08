#!/bin/bash
# generate-invenio-secrets.sh

# Generate random values and base64 encode them

password=$(openssl rand -base64 32 | base64)

# Generate exactly 32 alphanumeric characters
rabbitmq_password_plain=$(head -c 100 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
#echo "Generated plain password: $rabbitmq_password_plain"
rabbitmq_password=$(echo -n "${rabbitmq_password_plain}" | base64)
#echo "Generated base64 password: $rabbitmq_password"


rabbitmq_erlang_cookie=$(openssl rand -base64 32 | base64)
FLOWER_BASIC_AUTH_CREDENTIALS_plain=$(head -c 100 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
FLOWER_BASIC_AUTH_CREDENTIALS=$(echo -n "${FLOWER_BASIC_AUTH_CREDENTIALS_plain}" | base64)


INVENIO_SECRET_KEY=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_LOGIN_SALT=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_PASSWORD_SALT=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_CONFIRM_SALT=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_RESET_SALT=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_CHANGE_SALT=$(openssl rand -base64 32 | base64)
INVENIO_SECURITY_REMEMBER_SALT=$(openssl rand -base64 32 | base64)
INVENIO_CSRF_SECRET_SALT=$(openssl rand -base64 32 | base64)
DATACITE_USERNAME=$(openssl rand -base64 32 | base64)
DATACITE_PASSWORD=$(openssl rand -base64 32 | base64)

cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: invenio-cluster-secrets
type: Opaque
data:
  # PostgreSQL
  password: $password
  postgres-password: $password
  
  # RabbitMQ
  rabbitmq-password: $rabbitmq_password
  rabbitmq-erlang-cookie: $rabbitmq_erlang_cookie
  
  # Flower
  FLOWER_BASIC_AUTH_CREDENTIALS: $FLOWER_BASIC_AUTH_CREDENTIALS
  
  # Invenio secret keys
  INVENIO_SECRET_KEY: $INVENIO_SECRET_KEY
  INVENIO_SECURITY_LOGIN_SALT: $INVENIO_SECURITY_LOGIN_SALT
  INVENIO_SECURITY_PASSWORD_SALT: $INVENIO_SECURITY_PASSWORD_SALT
  INVENIO_SECURITY_CONFIRM_SALT: $INVENIO_SECURITY_CONFIRM_SALT
  INVENIO_SECURITY_RESET_SALT: $INVENIO_SECURITY_RESET_SALT
  INVENIO_SECURITY_CHANGE_SALT: $INVENIO_SECURITY_CHANGE_SALT
  INVENIO_SECURITY_REMEMBER_SALT: $INVENIO_SECURITY_REMEMBER_SALT
  INVENIO_CSRF_SECRET_SALT: $INVENIO_CSRF_SECRET_SALT
  DATACITE_USERNAME: $DATACITE_USERNAME
  DATACITE_PASSWORD: $DATACITE_PASSWORD
EOF
