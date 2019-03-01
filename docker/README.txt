#
# Build / Start via docker-compose:
#
docker-compose build
docker-compose up

#
# Build
#
docker build -t csvdb/csvdb:0.1 -f docker/csvdb .
docker build -t csvdb/memcached:0.1 -f docker/memcached .

#
# Build using docker-compose
#
docker-compose build

#
# Experimental: Build / Squash (will work with docker-compose latest tags)
#
docker build --squash -t csvdb:latest -f docker/csvdb .
docker build --squash -t memcached:latest -f docker/memcached .


#
# Run
#
docker run --name memcached -itd -p 11211:11211 csvdb/memcached:0.1
docker run --name csvdb -itd -p 8080:80 --link memcached -v $(pwd):/var/www csvdb/csvdb:0.1 /bin/bash

#
# Run using docker-compose
#
docker-compose up -d

#
# Stop
#
docker stop csvdb
docker stop memcached

#
# Stop using docker-compose
#
docker-compose down

#
# Start
#
docker start memcached
docker start csvdb
docker exec -it csvdb /bin/bash

#
# Clean
#
docker container prune
docker image prune
docker rmi $(docker images -f "dangling=true" -q)


