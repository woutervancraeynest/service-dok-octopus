FROM ruby:3.3-slim

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test --jobs 4

COPY . .

EXPOSE 8080

CMD ["bundle", "exec", "ruby", "app.rb"]
