FROM ruby:3.2.3

RUN apt update && apt install -y suricata

RUN mkdir /app
COPY . /app/

RUN chown -R root:root /app
WORKDIR /app
EXPOSE 1234

RUN bundle install

# Run as the CTF user
RUN useradd -r user -u 1000
USER 1000

ENV DEBUG=true
ENV PROFILE=prod

CMD ["bundle", "exec", "ruby", "/app/server.rb"]
