# Project solution description

In the proposed solution, the user's request journey proceeds as follows:

1. The user sends a `GET v1/cars` request with a required `user_id` parameter and optional parameters: `query`, `price_min`, `price_max`, `page`, and `per_page`.
2. The `Cars Controller` delegates execution to the `RecommendationService`, which handles the following:
  - Obtaining AI-recommended cars by checking if the recommendations returned by `BravadoRecommendationClient` are stored in the cache database. If there is no cache hit, the service calls `BravadoRecommendationClient` and stores its response in the cache database.
  - After obtaining the recommended cars, building an SQL query that incorporates the recommendations logic
  - Querying the database, processing the `PG::Result` object, and constructing an array of hashes to pass back to the Controller.

I opted to delegate the logic for labeling user preference matches to the database. The database had sufficient business logic and data available to handle this efficiently. However, this resulted in a larger, custom SQL query to meet all requirements.

In a real-life scenario, I would consider the potential dataset size for cars and recommendations returned by the AI service. I would perform detailed benchmarks to determine if moving the labeling logic to a dedicated Ruby service is more beneficial. This service could accept user preferences, perform multiple database queries, and decorate cars with match labels instead of using a single, larger SQL query.

I did not introduce dedicated serializers or presenters for data returned from `RecommendationService`, as I felt this was unnecessary at this stage. However, if desired, a dedicated class for data presentation could be introduced.

# Setup

The project can be run either via Docker or a local setup. 

- **Local Setup**:
Update `config/database.yml` and adjust the `DATABASE_URL` and `CACHE_DATABASE_URL` settings accordingly if needed. Run the following commands:

```sh
bin/rails db:prepare
```

- **Docker Setup**:
Trigger the Docker environment using:

```sh
docker-compose up --build --force-recreate api
```

This will also set up the database using instructions from `bin/docker-entrypoint`.

To verify the application's liveness, use the following `curl` command:

```sh
curl 'http://localhost:3000/v1/cars?user_id=1' | jq
```

This should return JSON data like:

```json
[
  {
    "id": 179,
    "brand": {
      "id": 39,
      "name": "Volkswagen"
    },
    "model": "Derby",
    "price": 37230,
    "rank_score": 0.945,
    "label": "perfect_match"
  },
  {
    "id": 5,
    "brand": {
      "id": 2,
      "name": "Alfa Romeo"
    },
    "model": "Arna",
    "price": 39938,
    "rank_score": 0.4552,
    "label": "perfect_match"
  }
 ]
```

For development, toggle caching with:

```sh
bin/rails dev:cache
```

# Testing 

To skip request specs and speed up test execution, run:

```sh
bundle exec rspec --tag "~skip_request_specs"
```

Request specs are designed to validate the solution against the original requirements described in the README. 
This includes loading provided seeds and forcefully resetting table IDs sequences to match the expected response format.

A downside of this approach is that, in case of an error, transactions may not commit properly. This can result in validation errors (e.g., a "name" validation error) because the database was not cleared before running the next set of examples. Additionally, if a debugger is used and exited without committing the cleanup transaction, the database state may remain inconsistent.

To resolve such issues:
- Rerun the specs.
- Drop and recreate the test database before retrying:

```sh
RAILS_ENV=test bin/rails db:drop db:create db:schema:load 
```
