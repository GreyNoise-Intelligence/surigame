Starting the services:

`pathing`:

```
docker build . --progress=plain -t pathing && docker run --rm -p4000:4000 -ti pathing
```

`sighting`:

```
docker build --progress=plain -t sighting . && docker run --rm -it -p 4080:80 sighting
```

