FROM ruby:2.7-alpine
MAINTAINER Mike Petersen <info@odania-it.de>

RUN apk --no-cache add ruby ruby-dev ruby-bundler build-base git

ADD . /srv
WORKDIR /srv

RUN addgroup -g 1000 app
RUN adduser -u 1000 -G app -S app
RUN chown app:app -R /srv

USER app
ENV HOME /srv

RUN bundle install --path .vendor
