require 'date'
require 'octokit'
require './okr'

@client = Octokit::Client.new(:access_token => ENV['GITHUB_ACCESS_TOKEN'])
@client.auto_paginate = true

user_id = @client.user.login

today = Date.today
first = Date.new(today.year, today.month)
last = Date.new(today.year, today.month).next_month - 1

monthly_results = @client.list_issues('wantedly/infrastructure', {
  state: :all,
  creator: user_id,
  labels: 'Monthly Result',
}).map do |issue|
  "- #{issue.title} ##{issue.number}"
end

weekly_goal = @client.list_issues('wantedly/infrastructure', {
  state: :all,
  labels: 'Weekly Goal',
  since: first,
}).map do |issue|
  "- #{issue.title} ##{issue.number}"
end

daily_goal = @client.list_issues('wantedly/infrastructure', {
  state: :all,
  labels: 'Daily Goal',
  since: Date.new(today.year, today.month),
}).map do |issue|
  "- #{issue.title} ##{issue.number}"
end

{
  PREVIOUS: ['<details>', '', *monthly_results, '', '</details>'].join("\n"),
  'Quarter Goal': format_objectives(get_objectives(view: :owner, page: 1, state: :current)),
  'Weekly Goal': weekly_goal.join("\n"),
  'Daily Goal': daily_goal.join("\n"),
  'GitHub Activities': {
    ':shipit: マージされた PR': "@wantedly+author:#{user_id}+merged",
    ':memo: レビューしたor関わった PR': "@wantedly+-author:#{user_id}+commenter:#{user_id}+merged",
    ':memo: 関わった&解決した Issue': "@wantedly+is:issue+commenter:#{user_id}+closed",
    ':memo: 関わった&未解決の Issue': "@wantedly+is:issue+state:open+commenter:#{user_id}+updated",
  }.map{|k,v| "- [#{k}](https://github.com/issues?q=#{v}:#{first}..#{last})"}.join("\n"),
  Description: 'WIP',
  Comment: 'WIP',
}.map do |k, v|
  puts "## #{k}\n\n"
  puts "#{v}\n\n"
end
