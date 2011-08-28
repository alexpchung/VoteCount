#!/usr/bin/env ruby

"""
__author__ = 'Alex Chung'
__email__ = 'achung@ischool.berkeley.edu'
__ruby_version = '1.8.7'
__can_anonymously_use_as_example = True


CS194-017 Entrance Exercise
"""

require 'webrick'

$memberhash = Hash.new() #Hash of registered member agents.
$candidatehash = Hash.new() #Hash of members who received votes.

class Member < WEBrick::HTTPServlet::AbstractServlet
  
  def do_POST(request, response)
    status, content_type, body = registerMember(request)
    
    if (body == 'OK')
      response.status = status
      response['Content-Type'] = content_type
      response.body = body + "\n"
    end
  end
  
  def registerMember(request)
    agent_name = request.query['agent'] if request.query['agent']
    msg = ""
    
    if ($candidatehash.length == 0 && $memberhash[agent_name] == nil) #no more members may be added once voting has begun; Check if the member has registered before
      #accept new member
      $memberhash[agent_name] = 'not voted'
      msg = "OK"
    end
    
    return 200, "text/plain", msg
  end
end

class Vote < WEBrick::HTTPServlet::AbstractServlet
  
  def do_POST(request, response)
    status, content_type, body = registerVote(request)
    
    if (body == "OK")
      response.status = status
      response['Content-Type'] = content_type
      response.body = body + "\n"
    end
  end
  
  def registerVote(request)
    agent_name = request.query['agent'] if request.query['agent']
    vote_name = request.query['vote'] if request.query['vote']
    msg = ""
    
    if ($memberhash[agent_name] != nil && $memberhash[agent_name] != 'voted')
      $candidatehash[vote_name] = 0 if $candidatehash[vote_name] == nil
      $candidatehash[vote_name] += 1
      $memberhash[agent_name] = 'voted'
      msg = "OK"
    end
    
    return 200, "text/plain", msg
  end
end

class Victor < WEBrick::HTTPServlet::AbstractServlet
  
  def do_GET(request, response)
    status, content_type, body = checkVictor()

    response.status = status
    response['Content-Type'] = content_type
    response.body = body + "\n"
  end

  def checkVictor()
    result = "UNKNOWN"
    if ($candidatehash != nil && $candidatehash.length > 0)
      member_total = $memberhash.length
      victor_name, vote_num =  $candidatehash.find {|key, value| value > (member_total / 2)}
      if (victor_name != nil)
        result = victor_name
      end
    end
    return 200, "text/plain", result
  end
end

class ReinitializeServerState < WEBrick::HTTPServlet::AbstractServlet
  
  def do_POST(request, response)
    $memberhash = nil
    $candidatehash = nil
  end
end

if $0 == __FILE__ then
  server = WEBrick::HTTPServer.new(
    :BindAddress => '0.0.0.0', 
    :Port => 8080
  )
  server.mount "/member", Member
  server.mount "/vote", Vote
  server.mount "/victor", Victor
  server.mount "/rst", ReinitializeServerState
  trap "INT" do server.shutdown end
  server.start
end