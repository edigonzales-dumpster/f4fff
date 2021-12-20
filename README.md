# f4fff

## Vorbereitung
```
multipass mount /Users/stefan/sources/f4fff foo:/home/ubuntu/sources/f4fff
```

```
multipass shell foo
```

```
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

```
sudo apt-get install postgis
```
(wegen shp2pgsql)

```
mkdir -m 0777 ~/pgdata-fff
mkdir --mode=0777 ~/pgdata-fff
docker run --rm --name pubdb -p 54322:5432 -v ~/pgdata-fff:/var/lib/postgresql/data:delegated -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=pub ghcr.io/baosystems/postgis:13-3.1
```

```
CREATE SCHEMA fff AUTHORIZATION postgres;
```

```
shp2pgsql -s 2056 -I -S data/partial/fruchtfolgeflaechen.shp fff.fruchtfolgeflaechen_partial > fff_partial.sql
shp2pgsql -s 2056 -I -S data/full/fruchtfolgeflaechen.shp fff.fruchtfolgeflaechen_full > fff_full.sql

psql -h localhost -p 54322 -d pub -U postgres -W -f fff_partial.sql
psql -h localhost -p 54322 -d pub -U postgres -W -f fff_full.sql
```


## Export

```
java -jar /Users/stefan/apps/ili2pg-4.6.1/ili2pg-4.6.1.jar --dbhost 192.168.64.2 --dbdatabase pub --dbport 54322 --dbusr postgres --dbpwd postgres --strokeArcs --disableValidation --defaultSrsCode 2056 --createEnumTabs --createGeomIdx --models SO_ALW_Fruchtfolgeflaechen_Publikation_20201109 --dbschema fff_out --schemaimport
```

```
java -jar /Users/stefan/apps/ili2pg-4.6.1/ili2pg-4.6.1.jar --dbhost 192.168.64.2 --dbdatabase pub --dbport 54322 --dbusr postgres --dbpwd postgres --disableValidation --defaultSrsCode 2056  --models SO_ALW_Fruchtfolgeflaechen_Publikation_20201109 --dbschema fff_out --export fubar.xtf

xmllint --format fubar.xtf -o fubar.xtf

java -jar /Users/stefan/apps/ilivalidator-1.11.12/ilivalidator-1.11.12.jar --log fubar.log fubar.xtf
```




