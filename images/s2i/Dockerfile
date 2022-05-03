FROM centos/ruby-27-centos7

USER root

ADD ./root /

ENV PATH=/opt/rh/rh-ruby25/root/usr/bin:$PATH
ENV EXECJS_RUNTIME=Node

RUN \
  set -x && \
  yum install -y http://opensource.wandisco.com/centos/7/git/x86_64/wandisco-git-release-7-2.noarch.rpm && \
  yum install -y \
    # for active storage gem
    ImageMagick poppler libpoppler \
    # Update certificates
    cacerts ca-certificates && \
  update-ca-trust && \
  # Call restore-artifacts sscript when assembling
  sed '/Installing application source/i $STI_SCRIPTS_PATH/restore-artifacts' \
    -i $STI_SCRIPTS_PATH/assemble && \
  # Call post-assemble script when assembling
  echo -e "\n\$STI_SCRIPTS_PATH/post-assemble" >> $STI_SCRIPTS_PATH/assemble

RUN bash -c 'gem install bundler:2.2.5 --no-document'

USER 1001

ENV RAILS_ENV=production
ENV RAILS_DB_ADAPTER=nulldb
