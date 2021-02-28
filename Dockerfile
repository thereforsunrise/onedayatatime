FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && apt-get install -y --force-yes build-essential bash mysql-common libmysqlclient-dev ruby ruby-dev mysql-client

RUN mkdir /home/app
WORKDIR /home/app

RUN gem install bundler

CMD ./run.sh
