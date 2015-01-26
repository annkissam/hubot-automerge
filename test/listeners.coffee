chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'automerge', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/automerge')(@robot)

  it 'registers "help" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/a(?:uto)?m(?:erge)? help/i)

  it 'registers "list" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/a(?:uto)?m(?:erge)? list( (.+))?/i)

  it 'registers "remove" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/a(?:uto)?m(?:erge)? remove ([-_\.0-9a-zA-Z]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i)

  it 'registers "add" listener', ->
    expect(@robot.respond).to.have.been.calledWith(/a(?:uto)?m(?:erge)? add ([-_\.0-9a-zA-Z]+)(\:([-_\.a-zA-z0-9\/]+))? into ([-_\.a-zA-z0-9\/]+)/i)
