FROM alpine:latest

RUN apk add --no-cache git bash ruby ruby-dev build-base curl git openssh-client jq openssl-dev
RUN gem install bundler --no-document

RUN adduser -D appuser
USER appuser

RUN mkdir -p /home/appuser/.ssh && chmod 700 /home/appuser/.ssh
COPY --chown=appuser:appuser ssh_known_hosts /home/appuser/.ssh/known_hosts
RUN chmod 644 /home/appuser/.ssh/known_hosts

ENV PATH="/home/appuser/.local/bin:${PATH}"
ENV BUNDLE_PATH="/home/appuser/.bundle"
RUN curl -fsSL gitpack.htlc.io | sh -s -- install https://github.com/melari/aux.git

WORKDIR /app

COPY start_aux_server.sh .
COPY app.rb .
COPY Gemfile .
COPY endpoints/ endpoints/
COPY templates/ templates/
COPY assets/ assets/
RUN bundle install --no-cache

RUN mkdir bare_repo.git
RUN mkdir notes
RUN mkdir config

CMD ["./start_aux_server.sh"]
