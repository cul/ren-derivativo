# frozen_string_literal: true

require 'rubocop/rake_task'

namespace :derivativo do
  namespace :rubocop do
    desc 'Automatically fix safe errors (quotes and frozen string literal comments)'
    rules = [
      'Layout/EmptyLineAfterGuardClause',
      'Layout/EmptyLineAfterMagicComment',
      'Layout/EmptyLines',
      'Layout/EmptyLinesAroundClassBody',
      'Layout/SpaceAroundOperators',
      'Layout/SpaceBeforeBlockBraces',
      'Layout/SpaceInsideArrayLiteralBrackets',
      'Layout/SpaceInsideBlockBraces',
      'Layout/SpaceInsideHashLiteralBraces',
      'Layout/SpaceInsidePercentLiteralDelimiters',
      'RSpec/EmptyLineAfterExampleGroup',
      'RSpec/EmptyLineAfterFinalLet',
      'RSpec/EmptyLineAfterSubject',
      'Style/EmptyMethod',
      'Style/FrozenStringLiteralComment',
      'Style/GlobalStdStream',
      'Style/StringLiterals',
      'Style/TrailingCommaInArrayLiteral'
    ]
    RuboCop::RakeTask.new(:auto_fix_safe_errors) do |t|
      t.options = [
        '--autocorrect-all',
        '--only', rules.join(',')
      ]
    end
  end
end
