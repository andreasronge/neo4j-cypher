require 'spec_helper'


describe "Cypher Cookbook Examples" do

  describe "5.1.1. Find Groups" do
    # See http://docs.neo4j.org/chunked/stable/cypher-cookbook-hyperedges.html
    #To find out in what roles a user is for a particular groups (here Group2), the following Cypher Query can traverse this HyperEdge node and provide answers.
    #
    #                                      START n=node:node_auto_index(name = "User1")
    #                                      MATCH n-[:hasRoleInGroup]->hyperEdge-[:hasGroup]->group, hyperEdge-[:hasRole]->role
    #                                      WHERE group.name = "Group2"
    #                                      RETURN role.name

    it "can be written in many lines" do
      Proc.new do
        # START n=node:node_auto_index(name = "User1")
        n = lookup('node_auto_index', "name", "User1").as(:n)

        # MATCH n-[:hasRoleInGroup]->hyperEdge-[:hasGroup]->group
        n > ':hasRoleInGroup' > :hyperEdge > ':hasGroup' > :group

        # , hyperEdge-[:hasRole]->role
        node(:hyperEdge) > ':hasRole' > :role

        # WHERE group.name = "Group2"
        node(:group)[:name] == 'Group2'

        # RETURN role.name
        ret(node(:role)[:name])
      end.should be_cypher('START n=node:node_auto_index(name="User1") MATCH (n)-[:hasRoleInGroup]->(hyperEdge)-[:hasGroup]->(group),(hyperEdge)-[:hasRole]->(role) WHERE group.name = "Group2" RETURN role.name')
    end

    it 'can be written in one line' do
      Proc.new do
        lookup('node_auto_index', "name", "User1") > ':hasRoleInGroup' > node(:hyperEdge).match { |n| n > ':hasRole' > node(:role).ret{|r|r[:name]} } > ':hasGroup' > node(:group).where{|g| g[:name] == 'Group2'}
      end.should be_cypher('START v1=node:node_auto_index(name="User1") MATCH (v1)-[:hasRoleInGroup]->(hyperEdge)-[:hasGroup]->(group),(hyperEdge)-[:hasRole]->(role) WHERE (group.name = "Group2") RETURN role.name')

    end
  end


  describe '5.1.2. Find all groups and roles for a user' do
    #5.1.2. Find all groups and roles for a user
    #                                   Here, find all groups and the roles a user has, sorted by the roles names.
    #
    #                                                                                                           Query
    #
    #                                   START n=node:node_auto_index(name = "User1")
    #                                   MATCH n-[:hasRoleInGroup]->hyperEdge-[:hasGroup]->group, hyperEdge-[:hasRole]->role
    #                                   RETURN role.name, group.name
    #                                   ORDER BY role.name asc

    it 'can be written in many lines' do
      Proc.new do
        n = lookup('node_auto_index', 'name', 'User1').as(:n)
        # instead of using symbol and string we wrap them in node and rel functions, which might be more readable

        n > ':hasRoleInGroup' > node(:hyperEdge) > rel(':hasGroup') > node(:group)
        node(:hyperEdge) > rel(':hasRole') > node(:role)

        ret(node(:role)[:name], node(:group)[:name]).asc(node(:role)[:name])

      end.should be_cypher('START n=node:node_auto_index(name="User1") MATCH (n)-[:hasRoleInGroup]->(hyperEdge)-[:hasGroup]->(group),(hyperEdge)-[:hasRole]->(role) RETURN role.name,group.name ORDER BY role.name')
    end

    it 'can be written in one line' do
      Proc.new do
        lookup('node_auto_index', 'name', 'User1') > ':hasRoleInGroup' > node(:hyperEdge).match do |hyperEdge|
          hyperEdge > rel(':hasRole') > node(:role).ret{|role| role[:name].asc}
        end > rel(':hasGroup') > node(:group).ret {|group| group[:name]}
      end.should be_cypher('START v1=node:node_auto_index(name="User1") MATCH (v1)-[:hasRoleInGroup]->(hyperEdge)-[:hasGroup]->(group),(hyperEdge)-[:hasRole]->(role) RETURN role.name,group.name ORDER BY role.name')
    end

  end

  describe '5.1.3 Find common groups based on shared roles' do
    #5.1.3. Find common groups based on shared roles
    #Assume you have a more complicated graph:
    #
    #                                       2 user nodes User1, User2
    #User1 is in Group1, Group2, Group3.
    #    User1 has Role1, Role2 in Group1; Role2, Role3 in Group2; Role3, Role4 in Group3 (hyper edges)
    #User2 is in Group1, Group2, Group3
    #User2 has Role2, Role5 in Group1; Role3, Role4 in Group2; Role5, Role6 in Group3 (hyper edges)
    #The graph for this looks like the following (nodes like U1G2R23 representing the HyperEdges):
    #
    # START u1=node:node_auto_index(name = "User1"),u2=node:node_auto_index(name = "User2")
    # MATCH u1-[:hasRoleInGroup]->hyperEdge1-[:hasGroup]->group,
    #      hyperEdge1-[:hasRole]->role,
    #      u2-[:hasRoleInGroup]->hyperEdge2-[:hasGroup]->group,
    #      hyperEdge2-[:hasRole]->role
    # RETURN group.name, count(role)
    # ORDER BY group.name asc
    it 'can be written in many lines' do
      Proc.new do
        u1 = lookup('node_auto_index', 'name', 'User1').as(:u1)
        u2 = lookup('node_auto_index', 'name', 'User2').as(:u2)
        group = node(:group)
        role = node(:role)

        u1 > rel(':hasRoleInGroup') > node(:hyperEdge1) > rel(':hasGroup') > group
        node(:hyperEdge1) > rel(':hasRole') > role
        u2 > rel(':hasRoleInGroup') > node(:hyperEdge2) > rel(':hasGroup') > group
        node(:hyperEdge2) > rel(':hasRole') > role
        ret(group[:name].asc, count(role))
      end.should be_cypher('START u1=node:node_auto_index(name="User1"),u2=node:node_auto_index(name="User2") MATCH (u1)-[:hasRoleInGroup]->(hyperEdge1)-[:hasGroup]->(group),(hyperEdge1)-[:hasRole]->(role),(u2)-[:hasRoleInGroup]->(hyperEdge2)-[:hasGroup]->(group),(hyperEdge2)-[:hasRole]->(role) RETURN group.name,count(role) ORDER BY group.name')
    end
  end

  describe "5.2. Basic Friend finding based on social neighborhood " do
    it do
      Proc.new do
        joe=node(3)
        friends_of_friends = node(:friends_of_friends)
        joe > ':knows' > node(:friend) > ':knows' > friends_of_friends
        r = rel('r?:knows').as(:r)
        joe > r > friends_of_friends
        r.null
        ret(friends_of_friends[:name], count).desc(count).asc(friends_of_friends[:name])
      end.should be_cypher(%{START v1=node(3) MATCH (v1)-[:knows]->(friend)-[:knows]->(friends_of_friends),(v1)-[r?:knows]->(friends_of_friends) WHERE (r is null) RETURN friends_of_friends.name,count(*) ORDER BY count(*) DESC, friends_of_friends.name})
    end

    it "also works with outgoing method instead of < operator" do
      Proc.new do
        joe=node(3)
        friends_of_friends = joe.outgoing(:knows).outgoing(:knows)
        joe.outgoing(rel?(:knows).null, friends_of_friends)
        ret(friends_of_friends[:name], count).desc(count).asc(friends_of_friends[:name])
      end.should be_cypher(%{START v3=node(3) MATCH (v3)-[:`knows`]->(v4),(v4)-[:`knows`]->(v2),(v3)-[v1?:`knows`]->(v2) WHERE (v1 is null) RETURN v2.name,count(*) ORDER BY count(*) DESC, v2.name})
    end

  end


end