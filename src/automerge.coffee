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
#   HUBOT_GITHUB_ORG
#
# Commands:
#   hubot automerge help - Outputs a help document explaining how to use.
#   hubot list <project> - Outputs a list of automerge branches for project.
#   hubot list - Outputs a list of all branches that are automerged for all projects.
#   hubot remove <project> - Clear project information from automerge.
#   hubot remove - Clears all the information from automerge .
#


module.exports = (robot) ->
  cronJob = require('cron').CronJob
  _ = require('underscore')
  github = require("githubot")(robot)

  # Unless enterprise
  unless (url_api_base = process.env.HUBOT_GITHUB_API)?
    url_api_base = "https://api.github.com"

  # Unless annkissam
  unless (url_org_base = process.env.HUBOT_GITHUB_ORG)?
    url_org_base = "annkissam"

  # Base listeners
  robot.respond /a(?:uto)?m(?:erge)? help/i, (msg) ->
    autoMergeHelp(msg)

  robot.respond /a(?:uto)?m(?:erge)? list( (.+))?/i, (msg) ->
    autoMergeList(msg)

  ## http://rubular.com/r/MK6ijQxE8v
  robot.respond /a(?:uto)?m(?:erge)? remove ([-_\.0-9a-zA-Z]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i, (msg) ->
    autoMergeRemove(msg)

  robot.respond /a(?:uto)?m(?:erge)? add ([-_\.0-9a-zA-Z]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i, (msg) ->
    autoMergeAdd(msg)

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
        mergesText.push "Automatically merging #{url_org_base}/#{branch.project} from #{branch.source} into #{branch.target} on push."

      msg.send mergesText.join("\n")

  ##
  autoMergeRemove = (msg) ->
    project = msg.match[1]
    source = msg.match[3] or "master"
    target = msg.match[4]

    setBranches _.reject getBranches(), (branch) ->
      branch.project is project and branch.source is source and branch.target is target

    msg.send "Stopped watching #{url_org_base}/#{project}:#{source} into #{target}."

  ##
  autoMergeAdd = (msg) ->
    project = msg.match[1]
    source = msg.match[3] or "master"
    target = msg.match[4]

    saveBranch project, source, target
    msg.send "Ok, from now on I'll merge #{url_org_base}/#{project}:#{source} into #{target} on push."

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


  # Gets all merges, fires ones that should be.
  checkMerges = ->
    #merges = getMerges()
    #_.each merges, (merge) ->
      #doMerge merge.room

  # Fires the merge message.
  doMerge = (room) ->
    #message = _.sample(MERGE_MESSAGES)
    #robot.messageRoom room, message

