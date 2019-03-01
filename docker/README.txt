#
# Download from Docker Hub
#
docker pull mnott/memcached
docker pull mnott/csvdb

#
# Build / Start / Stop via docker-compose:
#
docker-compose build
docker-compose up -d
docker-compose down
docker-compose kill

#
# Manual Build (--squash requires experimental features)
#
docker build --squash -t mnott/csvdb -f docker/csvdb .
docker build --squash -t mnott/memcached -f docker/memcached .
docker rmi $(docker images -f "dangling=true" -q)

#
# Manual Run / Start / Stop / Kill
#
docker run --name memcached -itd -p 11211:11211 mnott/memcached
docker run --name csvdb -itd -p 8080:80 --link memcached -v $(pwd):/var/www mnott/csvdb
docker start memcached
docker start csvdb
docker stop memcached
docker stop csvdb
docker kill memcached
docker kill csvdb

#
# Log into container
#
docker exec -it csvdb /bin/bash
docker exec -it $(docker container ls --format '{{.Names}}'|grep _csvdb_) /bin/bash
docker exec -it $(docker container ls --format '{{.Names}}'|grep _memcached_) /bin/bash

#
# Clean
#
docker container prune
docker image prune
docker rmi $(docker images -f "dangling=true" -q)
docker system prune -a --volumes

