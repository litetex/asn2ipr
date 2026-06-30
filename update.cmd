docker build -t asng .
docker network create --ipv6 asng-net || echo "Already exists"
docker run --rm -it -v %cd%\source:/workdir -v %cd%\zonefiles:/zonefiles -v %cd%\out:/out --network=asng-net asng
docker network rm asng-net || echo "Failed to remove"
