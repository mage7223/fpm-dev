#!/bin/bash
# Local .env
ENV_FILE=.env
HOST_PROJECT=$(cd .. && basename $(pwd))

if [ -a $ENV_FILE ]; then
    export $(grep -v '^#' $ENV_FILE | xargs)
fi

DOCKER_RUN="docker-compose exec -T db"
DOCKER_MYSQL="/usr/bin/mysql -u $DB_USER_TARGET -p$DB_PASS_TARGET -h localhost"

SQL_FILE=$EXISTING_SQL_FILE

DB_CONTAINER_ID=$(docker-compose ps -q db)

if [ "$DB_CONTAINER_ID" == "" ]; then
    docker-compose up -d
fi


echo "CREATE SCHEMA $DB_NAME_SOURCE DEFAULT CHARACTER SET utf8mb4 ;" | $DOCKER_RUN $DOCKER_MYSQL

echo "Granting permissions on schema for user $DB_USER"
echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';" |  $DOCKER_RUN $DOCKER_MYSQL -D$DB_NAME

echo "Importing $SQL_FILE from disk to docker DB"
gunzip -c $SQL_FILE |  $DOCKER_RUN $DOCKER_MYSQL -D$DB_NAME

echo "Granting permissions on schema for user $DB_USER"
echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';" |  $DOCKER_RUN $DOCKER_MYSQL -D$DB_NAME

if [ "$DB_CONTAINER_ID" == "" ]; then
    docker-compose down
fi
