FROM alpine:latest

RUN apk add --no-cache git bash

WORKDIR /app

COPY start_aux_server.sh .
RUN chmod +x start_aux_server.sh

RUN mkdir bare_repo.git
RUN mkdir notes

CMD ["./start_aux_server.sh"]
