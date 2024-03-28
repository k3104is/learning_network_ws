#!/bin/bash

# make html file using cat's hear document
cat << 'EOF' > index.html
<!doctype html>
<html>
  <head>
    <title>Hello, World</title>
  </head>
  <body>
    <h1>Hello, World</h1>
  </body>
</html>
EOF

# launch http server
sudo python3 -m http.server -b 127.0.0.1 80 &
sleep 1

# connect server using http client(one of these)
#echo -en "GET / HTTP/1.0\r\n\r\n" | nc 127.0.0.1 80
curl -X GET -D - http://127.0.0.1/
#python3 ./http_clt_using_socket.py

# kill task
jobs -l | awk -F' ' '{print $2}' | xargs sudo kill > /dev/null 2>&1
sleep 1
jobs > /dev/null 2>&1

# delete html file
rm index.html
