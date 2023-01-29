# Derivativo 1.5 (a transitional version between 1.0 and 2.0)

## Setup instructions

TODO

## To run tests

With rubocop:
`bundle exec rake derivativo:ci`

Without rubocop:
`bundle exec rake derivativo:ci_nocop`

## Rubocop

To run rubocop, just run: `rubocop`

To regenerate the .rubocop_todo.yml file and automatically create TODO items for any unresolved rubocop errors, just run:
```
rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 10000
```
