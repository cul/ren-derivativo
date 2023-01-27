# frozen_string_literal: true

require 'rubocop/rake_task'

namespace :derivativo do
  namespace :rubocop do
    desc 'Automatically fix safe errors (quotes and frozen string literal comments)'
    rules = [
      'Style/StringLiterals',
      'Style/FrozenStringLiteralComment',
      'Layout/EmptyLineAfterMagicComment',
      'Layout/EmptyLineAfterGuardClause',
    ]
    RuboCop::RakeTask.new(:auto_fix_safe_errors) do |t|
      t.options = [
        '--autocorrect-all',
        '--only', rules.join(','),
      ]
    end
  end
end
