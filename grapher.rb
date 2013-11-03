#!/usr/bin/env ruby
#https://github.com/bbatsov/ruby-style-guide

require 'logger'
require 'neography'
require_relative 'scraper'

class GraphBot

  def initialize
    Neography.configure do |config|
      config.protocol       = "http://"
      config.server         = "localhost"
      config.port           = 7474
      config.max_threads    = 20
      config.parser         = MultiJsonParser
    end
    @neo = Neography::Rest.new
    @log = Logger.new(STDERR)
    @log.level = Logger::INFO
    @nodes = []
    @scrapeBot = ScrapeBot.new
  end

  def count_edges
    edges_query = "START r=rel(*) RETURN count(r)"
    q_relations = @neo.execute_query edges_query
    @log.info "#{q_relations["data"][0][0]} relations"
    q_relations["data"][0][0]
  end

  def count_nodes
    nodes_query = "START n=node(*) RETURN count(n)"
    q_nodes = @neo.execute_query nodes_query
    @log.info "#{q_nodes["data"][0][0]} nodes"
    q_nodes["data"][0][0]
  end

  def db_delete_all
    db_delete_all_query = "START n=node(*) MATCH n-[r?]-() WHERE ID(n) <> 0 DELETE n,r"
    @neo.execute_query db_delete_all_query
    #@neo.execute_query "MATCH (n) DELETE (n)"
    #@neo.execute_query "START r=rel(*) DELETE r"
    @log.warn "Neo4j database cleared"
  end

  def retrieve_node(name)
    @log.debug "Retrieve #{name}"
    find_query = "MATCH (x:Hero) WHERE x.name = \"#{hero}\" RETURN x;"
    @neo.execute_query find_query
  end

  def create_nodes(heroes)
    create_nodes_query = "CREATE\n"
    heroes.each do |hero|
      @log.info "Creating node for #{hero}"
      create_nodes_query << "(#{hero.gsub('-','')}:Hero {name:\"#{hero}\"}),\n"
    end
    #create_nodes_query = create_nodes_query[0..-3] + ";"
    create_nodes_query
  end


  def create_edges(heroes)
    query = ""
    heroes.each do |hero|
      @log.info "Building edges for #{hero}!"
      @scrapeBot.matchups(hero).each do |opponent|
        opponent_name = opponent[:name].downcase.gsub(' ', '-')
        relation = "advantage: #{opponent[:advantage]}"
        build_relation_query = "(#{hero})-[#{relation}]->(#{opponent_name}),\n"
        query << build_relation_query
        @log.debug "#{hero} => #{opponent_name}"
      end
    end
    query
  end

  def run
    @log.info "GraphBot run"
    #db_delete_all
    heroes = @scrapeBot.heroes
    #@neo.execute_query create_nodes(heroes)
    puts create_edges(heroes)
  end

end

#graphBot = GraphBot.new
#graphBot.count_nodes
#graphBot.count_edges
#graphBot.db_delete_all
#graphBot.count_nodes
#graphBot.count_edges

GraphBot.new.run
