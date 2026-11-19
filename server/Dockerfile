FROM ruby:3.4.13

RUN apt-get update && apt-get install -y \
  git \
  bash \
  curl \
  openssh-client \
  jq \
  libssl-dev \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" appuser
USER appuser

RUN mkdir -p /home/appuser/.ssh && chmod 700 /home/appuser/.ssh
COPY --chown=appuser:appuser ssh_known_hosts /home/appuser/.ssh/known_hosts
RUN chmod 644 /home/appuser/.ssh/known_hosts

ENV PATH="/home/appuser/.local/bin:${PATH}"
ENV BUNDLE_PATH="/home/appuser/.bundle"
RUN curl -fsSL gitpack.htlc.io | sh -s -- install https://github.com/melari/aux.git

WORKDIR /app

COPY --chown=appuser:appuser start_aux_server.sh .
COPY --chown=appuser:appuser app.rb .
COPY --chown=appuser:appuser Gemfile .
COPY --chown=appuser:appuser endpoints/ endpoints/
COPY --chown=appuser:appuser templates/ templates/
COPY --chown=appuser:appuser assets/ assets/
RUN bundle install --no-cache

RUN mkdir bare_repo.git
RUN mkdir notes
RUN mkdir config

CMD ["./start_aux_server.sh"]
