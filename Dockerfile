FROM ruby:2.4-alpine
MAINTAINER Mike Petersen <info@odania-it.de>

RUN apk --no-cache add ruby ruby-dev ruby-bundler build-base

ADD . /srv
WORKDIR /srv
RUN bundle install
