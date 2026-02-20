#!/bin/bash

 sudo docker build -t opencode-env .

sudo docker run -it  --add-host=host.docker.internal:host-gateway -e http_proxy=http://host.docker.internal:8118  -e https_proxy=http://host.docker.internal:8118  \
     --rm opencode-env 



    #    \
    #    \
    #  \
    #   - /projects:/projects \
      