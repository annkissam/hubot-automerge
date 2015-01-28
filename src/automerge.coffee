# Description:
#   Have Hubot do automatic merges in github repos using the Merge API.
#   ref: https://developer.github.com/v3/repos/merging/
#
# Dependencies:
#   "cron": "~1.0.4"
#   "githubot": "0.4.x"
#   "underscore": "~1.6.0"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#   HUBOT_GITHUB_API
#
# Commands:
#   hubot automerge help - Outputs a help document explaining how to use.
#


module.exports = (robot) ->
  cronJob = require('cron').CronJob
  _ = require('underscore')
  github = require("githubot")(robot)

  # Unless enterprise
  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
    url_api_base = "https://api.github.com"

  # Base listeners
  robot.respond /a(?:uto)?m(?:erge)? help/i, (msg) ->
    autoMergeHelp(msg)

  robot.respond /a(?:uto)?m(?:erge)? list( (.+))?/i, (msg) ->
    autoMergeList(msg)

  ## http://rubular.com/r/MK6ijQxE8v
  robot.respond /a(?:uto)?m(?:erge)? remove ([-_\.0-9a-zA-Z\/]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i, (msg) ->
    autoMergeRemove(msg)

  robot.respond /a(?:uto)?m(?:erge)? add ([-_\.0-9a-zA-Z\/]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i, (msg) ->
    autoMergeAdd(msg)

  robot.respond /a(?:uto)?m(?:erge)? webhook/i, (msg) ->
    autoMergeWebHook(msg)

  autoMergeWebHook = (msg) ->
    msg.send "#{process.env.HUBOT_HEROKU_KEEPALIVE_URL}hubot/automerge?room=#{msg.message.metadata.room}"

  ## TODO
  autoMergeHelp = (msg) ->
    message = []
    #message.push robot.name + " list merges - See all merges for this room."
    msg.send message.join("\n")

  ##
  autoMergeList = (msg) ->
    branches = getBranches()
    if _.isEmpty branches
      msg.send "Well this is awkward. You haven't got any branches set up. Yet. :1up:"
    else
      mergesText = []
      _.each branches, (branch) ->
        mergesText.push "Automatically merging #{branch.project} from #{branch.source} into #{branch.target} on push."

      msg.send mergesText.join("\n")

  ##
  autoMergeRemove = (msg) ->
    project = msg.match[1]
    source = msg.match[3] or "master"
    target = msg.match[4]

    setBranches _.reject getBranches(), (branch) ->
      branch.project is project and branch.source is source and branch.target is target

    msg.send "Stopped watching #{project}:#{source} into #{target}."

  ##
  autoMergeAdd = (msg) ->
    project = msg.match[1]
    source = msg.match[3] or "master"
    target = msg.match[4]

    saveBranch project, source, target
    msg.send "Ok, from now on I'll merge #{project}:#{source} into #{target} on push."

  # Returns all branches.
  getBranches =  ->
    robot.brain.get("branches") or []

  # Updates the brain's merge knowledge.
  setBranches = (branches) ->
    robot.brain.set "branches", branches

  # Stores a branch in the brain.
  saveBranch = (project, source, target) ->
    branches = getBranches()
    newMerge =
      project: project
      source: source
      target: target

    branches.push newMerge
    setBranches branches

  # Route to receive the webhook.
  robot.router.post "/hubot/automerge", (req, res) ->
    url = require('url')
    querystring = require('querystring')

    query = querystring.parse(url.parse(req.url).query)
    data = req.body
    room = query.room

    try
      merges = checkMerges data
      _.each merges, (merge) ->
        robot.messageRoom doMerge(merge.project, merge.source, merge.target)
    catch error
      robot.messageRoom room, "Whoa, I got an error: #{error}"
      console.log "github automerge notifier error: #{error}. Request: #{req.body}"

    res.end ""

  # Fires the merge message.
  doMerge = (project, source, target) ->
    console.log project, source, target
    github.branches(project).merge source, { base: target }, (merge) ->
      if merge.message
        merge.message
      else
        "Merged the crap out of it"

  # Gets all merges, fires ones that should be.
  checkMerges = (data) ->
    project = data.repository.full_name
    ref = data.ref

    matchingBranches = _.filter getBranches(), (branch) ->
      branch.project is project and "refs/heads/#{branch.source}" is ref

    return matchingBranches
