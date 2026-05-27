FROM ruby:3.2.3

RUN mkdir /app
COPY server.rb /app/server.rb
RUN chown -R root:root /app

# Run as the CTF user
RUN useradd -r ctf -u 1000
USER 1000

# Run PHP-FPM and Nginx
CMD ["ruby", "/app/server.rb"]
