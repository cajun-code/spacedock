require "enumerator"
require "nokogiri"
require "pathname"
require "csv"

require_relative "common"

def column_for_turn(direction, kind)
  if direction == "left"
    if kind == "turn"
      0
    else
      1
    end
  else
    if kind == "turn"
      4
    else
      3
    end
  end    
end

def process_maneuvers(moves, maneuver_string, color)
  unless maneuver_string == nil
    maneuver_string = maneuver_string.downcase.gsub("forward", "straight")
    maneuvers = maneuver_string.split(/\s*,\s*/)
    maneuvers.each do |one_move|
      speed, kind = one_move.split(/\s+/)
      if kind == "straight"
        moves.push({:color => color, :speed => speed.to_i, :kind => kind, :column => 2})
      elsif kind == "reverse"
        moves.push({:color => color, :speed => speed.to_i * -1, :kind => "straight", :column => 2})
      else
        ["left", "right"].each do |direction|
          moves.push({:color => color, :speed => speed.to_i, :kind => "#{direction}-#{kind}", :column => column_for_turn(direction, kind)})          
        end
      end
    end
  end
end

# Timestamp	Uniqueness	Ship Name	Faction	Ship Class	Attack	Agility	Hull	Shield	Ability	Action Bar	Cost	Borg Upgrade Slots	Crew Upgrade Slots	Tech Upgrade Slots	Weapon Upgrade Slots	Expansion Pack	Maneuver Grid	Firing Arcs	Build/Price Adjustment	Green Maneuvers	White Maneuvers	Red Maneuvers										
ship = <<-SHIPTEXT
9/29/2014 15:21:23	Unique	Val Jean	Independent	Maquis Raider	2	3	3	3	During the Modify Defense Dice step of the Combat Phase, you may disable up to 3 of your Upgrades to add 1 [EVADE] result to your roll for each Upgrade you disabled with this card.	Battle Stations, Evasive, Scan, Target Lock	22	0	2	0	2	71528 - Val Jean	Maquis Raider	90-degree forward, 90-degree rear														
9/29/2014 15:22:20	Non-unique	Romulan/Borg Starship	Borg, Romulan	D'deridex Class	4	2	6	4		Cloak, Evasive, Sensor Echo, Target Lock	32	1	1	1	2	71511 - Avatar of Tomed	D'deridex Class	90-degree forward														
9/29/2014 15:23:08	Non-unique	Romulan Starship	Romulan	D'deridex Class	3	2	6	3		Cloak, Evasive, Sensor Echo, Target Lock	28	0	1	1	2	71511 - Avatar of Tomed	D'deridex Class	90-degree forward														
9/29/2014 15:25:02	Unique	I.R.W. Avatar of Tomed	Borg, Romulan	D'deridex Class	4	2	6	5	When you perform a [CLOAK] Action, you may immediately perform a [REGENERATE] Action as a free Action.  If you do so, you cannot attack that round.	Cloak, Evasive, Sensor Echo, Target Lock	34	1	1	1	3	71511 - Avatar of Tomed	D'deridex Class	90-degree forward														
9/29/2014 15:27:44	Unique	I.R.W. Avatar of Tomed	Romulan	D'deridex Class	3	2	6	4	During the Roll Attack Dice step of the Combat Phase, you may roll +1 attack die.  If you do so, suffer 1 damage to your Hull.	Cloak, Evasive, Sensor Echo, Target Lock	30	0	1	1	3	71511 - Avatar of Tomed	D'deridex Class	90-degree forward														
9/30/2014 18:26:16	Unique	Queen Vessel Prime	Borg	Borg Octahedron	6	0	8	7	During the Roll Attack Dice step of the Combat Phase, your ship, or 1 friendly ship within Range 1-2 of your ship, may spend a Scan Token from beside this ship to gain +1 attack die.	Regenerate, Scan, Target Lock	42	2	2	1	1	71530 - Queen Vessel Prime		360-degree		1 Spin, 1 Forward, 2 Forward	2 Reverse, 1 Reverse, 2 Spin, 3 Spin, 3 Forward, 4 Forward	3 Reverse, 4 Spin										
9/30/2014 18:36:12	Unique	U.S.S. Enterprise-E	Federation	Sovereign Class	5	1	5	5	You may fire a Torpedo at an enemy ship without needing a Target Lock.  If you do so, place an Auxiliary Power Token beside your ship.	Battle Stations, Evasive, Scan, Target Lock	32	0	2	1	2	71531 - U.S.S. Enterprise-E		90-degree forward, 90-degree rear		1 Bank, 1 Forward, 2 Forward, 3 Forward	2 Bank, 3 Turn, 3 Bank, 4 Forward, 5 Forward	1 Reverse, 6 Forward										
9/30/2014 18:37:41	Non-unique	Federation Starship	Federation	Sovereign Class	5	1	5	4		Battle Stations, Evasive, Scan, Target Lock	30	0	1	1	2	71531 - U.S.S. Enterprise-E		90-degree forward, 90-degree rear		
10/1/2014 14:50:55	Non-unique	Borg Starship	Borg	Borg Octahedron	6	0	8	6		Regenerate, Scan, Target Lock	40	2	1	1	1	71530 - Queen Vessel Prime		360-degree		1 Forward, 1 Spin, 2 Forward	1 Reverse, 2 Reverse, 2 Spin, 3 Forward, 3 Spin, 4 Forward	3 Reverse, 4 Spin										
10/1/2014 19:20:35	Non-unique	Maquis Starship	Independent	Maquis Raider	2	3	3	2		Battle Stations, Evasive, Scan, Target Lock	20	0	1	0	2	71528 - Val Jean	Maquis Raider	90-degree forward, 90-degree rear														
SHIPTEXT


convert_terms(ship)

new_ships = File.open("new_ships.xml", "w")

shipLines = ship.split "\n"
shipLines.each do |l|
# Timestamp		Ship Name	Faction	Ship Class	Attack	Agility	Hull	Shield	Ability	Action Bar	Cost	Borg Upgrade Slots	Crew Upgrade Slots	Tech Upgrade Slots	Weapon Upgrade Slots	Expansion Pack	Maneuver Grid										*
  parts = l.split "\t"
  title = parts[2]
  shipClass = parts[4]
  unique = parts[1] == "Unique" ? "Y" : "N"
  mirrorUniverseUnique = parts[1] == "Mirror Universe Unique" ? "Y" : "N"
  faction_string = parts[3]
  faction_parts = faction_string.split(/\s*,\s*/)
  faction = faction_parts[0]
  additional_faction = faction_parts[1]
  unless faction
    throw "Faction missing"
  end
  attack = parts[5]
  agility = parts[6]
  hull = parts[7]
  shield = parts[8]
  ability = parts[9]
  action_bar = parts[10].split(/,\s*/)
  evasiveManeuvers = action_bar.include?("Evasive") ? 1 : 0
  battleStations = action_bar.include?("Battle Stations") ? 1 : 0
  cloak = action_bar.include?("Cloak") ? 1 : 0
  sensorEcho = action_bar.include?("Sensor Echo") ? 1 : 0
  targetLock = action_bar.include?("Target Lock") ? 1 : 0
  scan = action_bar.include?("Scan") ? 1 : 0
  regenerate = action_bar.include?("Regenerate") ? 1 : 0
  cost = parts[11]
  borg = parts[12]
  crew = parts[13]
  tech = parts[14]
  weapon = parts[15]
  expansion = parts[16]
  firing_arcs = parts[18]
  arc_360 = firing_arcs.include?("360-degree") ? "Y" : "N"
  setId = set_id_from_expansion(expansion)
  externalId = make_external_id(setId, title)
if cost.length == 0
	cost = (agility.to_i + attack.to_i + hull.to_i + shield.to_i) * 2
end
  shipXml = <<-SHIPXML
  <Ship>
    <Title>#{title}</Title>
    <Unique>#{unique}</Unique>
    <MirrorUniverseUnique>#{mirrorUniverseUnique}</MirrorUniverseUnique>
    <ShipClass>#{shipClass}</ShipClass>
    <Faction>#{faction}</Faction>
    <AdditionalFaction>#{additional_faction}</AdditionalFaction>
    <Attack>#{attack}</Attack>
    <Agility>#{agility}</Agility>
    <Hull>#{hull}</Hull>
    <Shield>#{shield}</Shield>
    <Ability>#{ability}</Ability>
    <Cost>#{cost}</Cost>
    <EvasiveManeuvers>#{evasiveManeuvers}</EvasiveManeuvers>
    <TargetLock>#{targetLock}</TargetLock>
    <Scan>#{scan}</Scan>
    <Battlestations>#{battleStations}</Battlestations>
    <Cloak>#{cloak}</Cloak>
    <SensorEcho>#{sensorEcho}</SensorEcho>
    <Regenerate>#{regenerate}</Regenerate>
    <Borg>#{borg}</Borg>
    <Tech>#{tech}</Tech>
    <Weapon>#{weapon}</Weapon>
    <Crew>#{crew}</Crew>
    <Has360Arc>#{arc_360}</Has360Arc>
    <Id>#{externalId}</Id>
    <Set>#{setId}</Set>
  </Ship>
  SHIPXML
  new_ships.puts shipXml
end

new_ship_class_details = File.open("new_ship_class_details.xml", "w")

shipLines.each do |l|
  parts = l.split "\t"
  ship_class = parts[4]
  ship_class_id = sanitize_title(ship_class).downcase
  maneuver_grid = parts[17]
  firing_arcs = parts[18]
  front_arc = ""
  rear_arc = ""
  firing_arc_parts = firing_arcs.split(",")
  firing_arc_parts.each do |arc_part|
    arc_part = arc_part.strip
    case arc_part.chomp
    when "90-degree forward"
      front_arc = "90"
    when "180-degree forward"
      front_arc = "180"
    when "90-degree rear"
      rear_arc = "90"
    end
  end
  moves = []
  green_maneuvers = parts[20]
  process_maneuvers(moves, green_maneuvers, "green")
  white_maneuvers = parts[21]
  process_maneuvers(moves, white_maneuvers, "white")
  red_maneuvers = parts[22]
  process_maneuvers(moves, red_maneuvers, "red")
  moves.sort! do |a,b| 
    v = b[:speed] <=> a[:speed]
    if v == 0
     v = a[:column] <=> b[:column] 
    end
    v
  end
  
  maneuver_parts = moves.collect do |one_move|
    %Q(      <Maneuver speed="#{one_move[:speed]}" kind="#{one_move[:kind]}" color="#{one_move[:color]}" />)
  end
  shipClassXml = <<-SHIPXML
  <ShipClassDetail>
    <Name>#{ship_class}</Name>
    <Id>#{ship_class_id}</Id>
    <Maneuvers>
#{maneuver_parts.join("\n")}
    </Maneuvers>
    <FrontArc>#{front_arc}</FrontArc>
    <RearArc>#{rear_arc}</RearArc>
  </ShipClassDetail>
  SHIPXML
  new_ship_class_details.puts shipClassXml
end
