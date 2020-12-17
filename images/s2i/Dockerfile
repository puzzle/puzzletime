FROM centos/ruby-25-centos7

USER root

ADD ./root /

ENV PATH=/opt/rh/rh-ruby25/root/usr/bin:$PATH

RUN \
  set -x && \
  yum install -y \
    # for active storage gem
    v8 ImageMagick poppler libpoppler && \
  # Call restore-artifacts sscript when assembling
  sed '/Installing application source/i $STI_SCRIPTS_PATH/restore-artifacts' \
    -i $STI_SCRIPTS_PATH/assemble && \
  # Call post-assemble script when assembling
  echo -e "\n\$STI_SCRIPTS_PATH/post-assemble" >> $STI_SCRIPTS_PATH/assemble

RUN bash -c 'gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"'
RUN bash -c 'gem install libv8 -v "8.4.255.0" --with-system-v8'

USER 1001

ENV RAILS_ENV=production
