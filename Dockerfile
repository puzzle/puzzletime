#################################
#          Variables            #
#################################

# Versioning
ARG RUBY_VERSION="4.0.5"
ARG BUNDLER_VERSION="4.0.10"
ARG NULLDB_VERSION="1.2.2"

# Packages
# ARG BUILD_PACKAGES="nodejs build-essential libc6"
ARG BUILD_PACKAGES
ARG RUN_PACKAGES="bash libpq5 libvips42 libvips-dev neovim postgresql-client"

# Scripts
ARG PRE_INSTALL_SCRIPT
ARG INSTALL_SCRIPT
ARG PRE_BUILD_SCRIPT
ARG BUILD_SCRIPT=" \
     SECRET_KEY_BASE=1 bundle exec rails assets:precompile \
  && rm -rf tmp/cache tmp/sockets tmp/pids \
"
ARG POST_BUILD_SCRIPT="echo \"(built at: $(date '+%Y-%m-%d %H:%M:%S'))\" > /app-src/BUILD_INFO"

# Bundler specific
ARG BUNDLE_WITHOUT="development:metrics:test"

# App specific
ARG RAILS_ENV="production"
ARG RACK_ENV="production"
ARG RAILS_HOST_NAME="unused.example.net"
ARG RAILS_DB_ADAPTER="nulldb"

# If you want to directly specify build infos
ARG BUILD_COMMIT
ARG BUILD_REPO
ARG BUILD_REPO_URL
ARG BUILD_REF

# Github specific
ARG GITHUB_SHA
ARG GITHUB_REPOSITORY
ARG GITHUB_REPOSITORY_URL
ARG GITHUB_REF_NAME

# Runtime ENV vars
ARG SENTRY_CURRENT_ENV
ARG PS1="$SENTRY_CURRENT_ENV > "
ARG TZ="Europe/Zurich"

# Custom ARGs for Puzzletime
ARG SKIP_MEMCACHE_CHECK=true

#################################
#          Build Stage          #
#################################

FROM ruby:${RUBY_VERSION} AS build

# arguments for steps
ARG PRE_INSTALL_SCRIPT
ARG BUILD_PACKAGES
ARG INSTALL_SCRIPT
ARG BUNDLER_VERSION
ARG NULLDB_VERSION
ARG PRE_BUILD_SCRIPT
ARG BUNDLE_WITHOUT
ARG BUILD_SCRIPT
ARG POST_BUILD_SCRIPT
ARG RAILS_DB_ADAPTER

# arguments potentially used by steps
ARG RACK_ENV
ARG RAILS_ENV
ARG RAILS_HOST_NAME
ARG TZ

# Custom ARGs
ARG SKIP_MEMCACHE_CHECK

# Set build shell
SHELL ["/bin/bash", "-c"]

RUN bash -vxc "${PRE_INSTALL_SCRIPT:-"echo 'no PRE_INSTALL_SCRIPT provided'"}" \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends ${BUILD_PACKAGES} \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
 && bash -vxc "${INSTALL_SCRIPT:-"echo 'no INSTALL_SCRIPT provided'"}" \
 && gem install --no-document \
        bundler:${BUNDLER_VERSION} \
        activerecord-nulldb-adapter:${NULLDB_VERSION}

WORKDIR /app-src

COPY Gemfile Gemfile.lock ./

RUN --mount=type=cache,target=/root/.bundle/cache \
    bash -vxc "${PRE_BUILD_SCRIPT:-"echo 'no PRE_BUILD_SCRIPT provided'"}" \
 && bundle config set --local deployment 'true' \
 && bundle config set --local without ${BUNDLE_WITHOUT} \
 && bundle install \
 && bundle clean \
 && rm -rf vendor/bundle/ruby/*/cache/*.gem \
 && find vendor/bundle/ruby/*/gems/ \
         -type f \
         \( -name "*.c" -o -name "*.o" -o -name "*.h" \) \
         -delete \
 && find vendor/bundle/ruby/*/gems/*/ \
         -mindepth 1 \
         -maxdepth 1 \
         -type d \
         \( -name "spec" -o -name "test" -o -name "doc" \) \
         -exec rm -rf {} +

COPY . /app-src

RUN bash -vxc "${BUILD_SCRIPT:-"echo 'no BUILD_SCRIPT provided'"}" \
 && bash -vxc "${POST_BUILD_SCRIPT:-"echo 'no POST_BUILD_SCRIPT provided'"}" \
 && rm -rf vendor/cache/ \
           vendor/bundle/ruby/*/cache \
           node_modules \
 && chgrp -R 0 /app-src \
 && chmod -R u+w,g=u /app-src


#################################
#           Run Stage           #
#################################

# This image will be replaced by Openshift
FROM ruby:${RUBY_VERSION}-slim AS app

# Set runtime shell
SHELL ["/bin/bash", "-c"]

# Add user
RUN useradd --uid 1001 --gid 0 --create-home app

# arguments for steps
ARG RUN_PACKAGES
ARG BUNDLER_VERSION
ARG BUNDLE_WITHOUT

# arguments potentially used by steps
ARG RACK_ENV
ARG RAILS_ENV

# data persisted in the image
ARG PS1
ARG TZ
ARG GITHUB_SHA
ARG GITHUB_REPOSITORY
ARG GITHUB_REPOSITORY_URL
ARG GITHUB_REF_NAME
ARG BUILD_COMMIT
ARG BUILD_REPO
ARG BUILD_REPO_URL
ARG BUILD_REF

# Custom ARGs
ARG SKIP_MEMCACHE_CHECK

ENV PS1="${PS1}" \
    TZ="${TZ}" \
    BUILD_REPO="${BUILD_REPO:-${GITHUB_REPOSITORY}}" \
    BUILD_REPO_URL="${BUILD_REPO_URL:-${GITHUB_REPOSITORY_URL}}" \
    BUILD_REF="${BUILD_REF:-${GITHUB_REF_NAME}}" \
    BUILD_COMMIT="${BUILD_COMMIT:-${GITHUB_SHA}}" \
    RAILS_ENV="${RAILS_ENV}" \
    RACK_ENV="${RACK_ENV}" \
    HOME="/app-src" \
    PATH="/app-src/bin:$PATH"

# Install dependencies, remove apt!
RUN export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends ${RUN_PACKAGES} curl less \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/* \
 && truncate -s 0 /var/log/*log

# Copy deployment ready source code from build (permissions already set in build stage)
COPY --from=build /app-src /app-src
WORKDIR /app-src

# Install specific versions of dependencies
RUN --mount=type=cache,target=/root/.bundle/cache \
    gem install bundler:${BUNDLER_VERSION} --no-document \
 && bundle config set --local deployment 'true' \
 && bundle config set --local without ${BUNDLE_WITHOUT} \
 && bundle install

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
        CMD curl -f http://localhost:3000/status/health || exit 1

USER 1001

CMD ["bundle", "exec", "puma", "-t", "8"]
