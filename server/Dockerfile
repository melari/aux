FROM alpine:latest

RUN apk add --no-cache git bash ruby ruby-dev build-base && gem install bundler --no-document

WORKDIR /app

COPY start_aux_server.sh .
COPY app.rb .
COPY Gemfile .
RUN bundle install --no-cache
RUN chmod +x start_aux_server.sh

RUN mkdir bare_repo.git
RUN mkdir notes

RUN curl -fsSL gitpack.htlc.io | sh -s -- install git@github.com:melari/aux.git

CMD ["./start_aux_server.sh"]
