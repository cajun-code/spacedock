require "enumerator"
require "nokogiri"
require "pathname"
require "csv"

require_relative "common"

# Title	Type	Faction	Cost	Effect	Effect	Effect	Effect	Set
reference_text = <<-TOKENTEXT
,Title,Type,Faction,Cost,Effect,Effect,Effect,Effect,Set,errata
,Energy Dampening Token (EDT),Token,,,"As soon as the ship receives the EDT, disable all of its remaining Shields and remove its (cloak) Token, if any. While the ship has the EDT, it cannot attack or raise its Shields.",During the Planning Phase the owner does not assign a maneuver dial to this ship.,"During the Activation Phase the owner moves the ship as if it were assigned a White 1 (straight) Maneuver. After executing this Maneuver, remove all EDTs from this ship It may now perform Actions and attack as normal.",,"#71128
Gor Portas",
,Tribble Token,Token,,,During the End Phase add 1 Tribble Token to your Ship Card (regardless of the number of Tribble Tokens it already has).,"If your ship has 1-3 Tribble Tokens, add +1 attack die whenever you attack and +1 defense die whenever you defend. Ignore this rule if your ship includes any Klingon Captains or Crew","If your Ship has 4-5 Tribble Tokens, there is no effect. If your ship has 6 or more Tribble Tokens, roll 1 less attack die whenever you attack and 1 less defense die whenever you defend. This penalty is doubled if your ship includes any Klingon Captains or Klingon Crew.","Your ship gains the following Action:
Action: If your ship is not Cloaked, disable all of your remaining Shields and target a ship at range 1-2 that is not Cloaked and has no Active Shields. Place any number of your Tribble Tokens beside the target ship's Ship Card. You cannot transfer any Tribble Token that you received this round.","#71125
Gr'oth",
,Muon Token,Token,,,A Muon Token stays with a ship until it is removed.,"During the Activation Phase after the ship moves, the ship takes damage to its Hull equal to the number of its current Maneuver -1. The type of maneuver does not matter, just the number.","After the ship performs a Green or White Maneuver, it can spend an Action to remove the Muon Token.",,"#71124
Apnex",
*,Elite Attack Die,Resource,any,5,"Once during every round, a player may choose to exchange 1 of their attack dice with the Elite Attack Die.  Players may not roll this die more than once per round, regardless of how many ships they have in their fleet.","The pips on the Elite Attack Die are: [2 Hit], [Critical], [Critical], [Hit], [Hit], [Hit], [Battle Stations], [Battle Stations]","The [2 Hit] result may be canceled by 1 [Evade] result. The [2 Hit] result inflices 2 damage if it is not canceled. When canceling the attack dice with [Evade] results, the order that the dice are cancelled is: [Hit] first, then [2 Hit], then [Critical].",,"OP 1
Participation",
*,Command Tokens,Resource,any,5,"Players receive a set of 10 Command Tokens and choose 5 of these to use during the tournament.
A player may only use Command Tokens for his/her ships.
When a Command Token is used, is is flipped over and may not be used again in that Battle.
*You may only use one command token per round","[Evade]: Place an [Evade] token next to your ship as a Free Action this round.
[Battlestations]: Place a [Battlestations] token next to your ship as a Free Action this round.
[Scan]: Place a [Scan] token next to your ship as a Free Action this round.
[Target Lock]: You may target lock 1 enemy ship as a free action this round. *This action follows the normal rules for target locking.","[Red Re-roll]: You may choose any number of your attack dice and re-roll them once. You must keep the results of the second roll.
[Green Re-reoll]: You may choose any number of your defense dice and re-roll them once. You must keep the results of the second roll.
[Plus Red]: Before rolling any of your attack dice, you may add +1 attack die to the current attack.","[Plus Green]: Before rolling any of your defense dice, you may add +1 defense die to the current defense.
[Set Red]: Before rolling any of your attack dice, you may set 1 of your dice on any side of your choice. This die may not be rolled or re-rolled during this round.
[Set Green]: Before rolling any of your defense dice, you may set 1 of your dice on any side of your choice. This die may not be rolled or re-rolled during this round.","OP 2
Participation",*
*,Reinforce-ment Sideboard,Resource,any,10,"1) Prior to the event, players select upto* 1 of each of the following card types and places them in the appropriate section on the Reinforcements Sideboard: 1 captain card, 1 (talent) upgrade, 1 (crew) upgrade, 1 (tech) upgrade, and 1 (weapon) upgrade. The total cost of these cards may not exceed 20 SP. Faction penalties do not apply, but any ship-specific penalties (like the U.S.S. Defiant's cloaking device)  do*.","2) Once per turn* during the activation phase of any round, a player may use a ship's action to:
a) Equip that ship with one upgrade card from his sideboard. The ship must have an upgrade slot of the appropriate type available to do this.
-OR-
b) Exchange 1 upgrade from his ship with 1 upgrade of the same type from his sideboard.
-OR-
c) Exchange 1 captain card from his ship with 1 captain from his sideboard.","3) Upgrades that may only be purchased for certain ship types can only be equipped onto or exchanged to that specific ship type.

4) Place an auxiliary power token beside a ship if the upgrade that is equipped onto or exchanged to that ship is of a different faction or if the upgrade would have an additional cost applied to that ship (i.e. “This Upgrade costs +5 squadron points I purchased for...”).","5) A captain or upgrade may be exchanged multiple times during the game.

6) If a captain or Upgrade which is currently affected by a game effect (i.e. a critical damage card, disabled token, etc.) is moved to a player's sideboard, that captain or upgrade is no longer affected by that game effect. NOTE: if the game effect is a critical damage card, flip the critical damage card face down and leave it with the ship.","OP 3
Participation",*
*,Flagship Resource,Resource,any,10,"1) Players receive a set of 4 flagship cards (with 2 options on each card) and choose 1 of those options to use during the tournament. There are 4 Independent options and 1 option for each faction: Federation, Klingon, Romulan, and Dominion. If a Federation, Klingon, Romulan, or Dominion flagship option is chosen, players must assign a ship of the same faction as their flagship. If an Independent option is chosen, players may assign any ship as their flagship and pay no faction penalty. *An independent faction flagship is now independent faction in addition to its original faction.","2) Flagship cards are oversized cards that are placed beneath your ship card. These cards will have additional stats that increase the printed values* of your ship (primary weapon, agility, hull, shields). In addition, flagship cards may add bonus text-based abilities, actions, and upgrade slots to the assigned ship card.

3) Players may use the bonus text-based ability in addition to their ship's normal text-based ability (if applicable) during the battle.","4) If a ship card does not have the bonus action in its action bar, that ship is now considered to have that action in its action bar. If a ship card already has the bonus action in its action bar, that ship may use this action as a free action every round.

5) If there is a bonus (talent) upgrade slot on your chosen flagship option, you may choose a (talent) upgrade even if your captain does not have the (talent) icon on the captain card. This talent is considered to be attached to the captain*",6) Players also receive a special plastic base and pegs that will show which ship is your flagship at a glance. The color of the base and pegs is black.,"OP 4
Participation",*
,Attack Squadron,Resource,any,20,"1. Players may only include 1 Attack Squadron when building their fleets for the tournament. This counts as their one resource for the tournament. Each Attack Squadron is comprised of one pre-painted miniature, a plastic base, two pegs, Ship Token, Maneuver Dial, Ship Card, A Maneuver Reference Card, 4 Attack Squadron tokens, two Attack Squadron ID tokens, and Shield Tokens (if applicable). ","2. Attack Squadrons are treated as normal ships with the following exceptions:
a. Attack Squadrons can only attack enemy ships at a range 1-2.
b. Attack Squadrons can not be equipped with any upgrades or captain cards.
","c. Each Attack Squadron Token has Primary Weapon, Agility, Hull, and Shield values, as well as a Captain Skill number on them. The Attack Squadron tokens are placed in a stack on top of the ship's card in descending order (from highest to lowest) of their Captain Skill values. NOTE: The value listed on the token at the top of the stack are always considered the Attack Squadron's current abilities and Captain Skill.","d. When an Attack Squadron sustains damage to its Hull, do not draw The Damage Cards as normal. Instead, remove one token from the top of the stack. Tokens removed in this way are removed from the game and may not be restored. Once there are no tokens left in the stack, the Attack Squadron is destroyed. Note: Only 1 Attack Squadron token may be removed by any single attack, regardless of how much damage is dealt by the attack.

e. If an Attack Squadron has Shields, the Shields are fully repaired and activated every time a new Attack Squadron token is revealed.",,
,United Force,Admirals Order's,Jan 2014,0,You may only deploy this Order if your Captain and all Upgrades on each of your ships match the same Faction as the ship itself.,"While the United Force Order is a part of your fleet:

1) During Set Up, you may spend an additional 10 SP on Upgrades, as long as each Upgrade is deployed to a ship of its own Faction. You cannot change these upgrades between Battle Rounds of a tournamnt.","2) Once per round, you may re-roll any one of your dice (even if it has already been re-rolled).

3) You cannot place a Captain or Upgrade from the Reinforcements Sideboard onto a ship of a different Faction.",f. All critical damage sustained by an Attack Squadron is immediately converted into normal damage.,Online,
,Strike Force,Admirals Order's,Jan 2014,5,You may only deploy this Order if your Fleet includes exactly 2 Ships.,"While the Strike Force Order is a part of your fleet:

1) Once during each Activation Phase, one of your ships may perfor one Action on its Action Bar as a free Action.","2) Once during each Combat Phase, one of you non-Cloaked Ships may roll 1 extra attack die OR 1 extra defense die. You must add the extra die before rolling your other dice during that attack or defense.",,Online,
,Adaptation Token,Token,,,"1) While an Adaptation Token is on a [Tech] Upgrade, Seven of Nine's ship is now considered to also possess that [Tech] Upgrade (even if Seven is disabled). The original Upgrade Card is unaffected and can be used freely by its owner. If the original Upgrade is disabled or discarded, Seven's ship is still considered to possess that [Tech] Upgrade and can freely use it.","2) If using the [Tech] Upgrade would normally require the Upgrade to be disabled or discarded, then when Seven's ship uses the Upgrade, remove the Adaptation Token. The Original Upgrade is unaffected.","3) Only 1 Adaptation Token may be in play at the same time. If Seven of Nine uses her ability on another [Tech] Upgrade, remove the Adaptation Token from the previous Upgrade.

4) If Seven of ine is discarded, discard the Adaptation Token.",,#71280 Vovager,
,Ablative Generator Token,Token,,,"A ship with an AGT assigned to it follows these special rules:

1) As soon as the ship revceives the AGT, disable all of its remaining Shields and remove its [Cloak] token, if any.","2) While the ship has the AGT, it cannot raise its Shields or Cloak

3) Convert all [crit] results against the ship to [hit] results","4) Place all damage Cards that the ship receives beneath the Ablative Generator Upgrade Card. If the player removes the AGT from beside the ship, the Damage Cards remain beneath the Ablative Generator card.","5) Once the Ablative Generator receives 5 Damage Cards, discard the Upgrade Card (and all 5 Damage Cards), and then remove the AGT from beside the ship. All excess damage affects the ship as normal.",#71280 Vovager,
,Borg Tractor Beam Token,Token,Borg,,"A ship with a white BTBT assigned to it follows these special rules.

1) As soon as the ship receives the BTBT, disable 2 of that ship's Active Shields (if the ship was cloaked, remove the [cloak] Token and raise all of its Shields except 2).","2) While the ship has the BTBT, it cannot raise its Shields or Cloak.

3)During the Planning Phase, the owner may not select a Maneuver whose number is greater than 2.","4) At the end of the Activation Phase, if the ship is no longer within Range 1 of the ship with the corresponding BTBT (the one that matches the white token's letter), remove the BTBTs from both ships.",,#71283 Borg Sphere,
,Drone Tokens,Mechanic,Borg,,"Each Drone Token has a Drone number listed on the face, as well as a Captain Skill Number listed on the back. The Drone Tokens are placed in a stack on top of the Captain Card in descending order (from highest to lowest) of their Drone numbers.","NOTE: The Drone number listed on the token at the top of the stack is always considered the ship's current Captain Skill. At the start of the game, place the Drone Token that has the starting Captain Skill beside the ship (this will be the reverse side of the token that reads “START” on the face).","When a Drone Token is used, remove one Token from the top of the stack and flip it over. Then remove the Drone Token that is beside the ship from play and replace it with the token that you just removed from the stack. ",NOTE: The Captain Skill that is listed  on the Token beside the ship should always be equal to the number of Drone Tokens left on the Captain Card.,#71283 Borg Sphere,
,Regenerate,Action,,,Ships with the [Regenerate] icon in their Action Bar may perform the REGENERATE Action.,A Ship the performs the [Regenerate] Action immediately repairs 1 damage of its choice to its Hull (critical or normal).,A ship cannot attack during the round that it performs the [regenerate] Action.,,,
,Spin Maneuver,Mechanic,,,The Spin Maneuver [left straight] or [right straight] uses the same movement template as a Straight Maneuver [forward].,"However, before executing a Spin Maneuver, the player rotates their ship 90°. In order to rotate a ship, place a [1 straight] Maneuver Template touching the side of the ship's base with the top edge of the template even with the front eedge of the ship base (as shown in A below).","Then, rotate the ship 90° (either right or left depending on the selected maneuver) so that the top edge of the [1 straight] maneuver template is even with the side of the ship base (as shown in B below).","After rotating the ship, complete the selected maneuver as normal using the appropriate maneuver template.",#71283 Borg Sphere,
TOKENTEXT

convert_terms(reference_text)

reference_lines = CSV.parse(reference_text)

new_reference = File.open("new_reference.xml", "w")

reference_item_lines = reference_text.split "\n"

def no_quotes(a)
  a.gsub("\"", "")
end

def parse_set(setId)
  unless setId
    return ""
  end
  setId = no_quotes(setId)
  if setId =~ /\#(\d+).*/
    return $1
  end
  return setId.gsub(" ", "").gsub("\"", "")
end

def make_reference_external_id(title)
  "#{sanitize_title(title)}_reference".downcase()
end

reference_lines.shift

reference_lines.each do |parts|
#  ,Title,Type,Faction,Cost,Effect,Effect,Effect,Effect,Set,errata
    parts.shift
    title = parts.shift
    type = parts.shift
    unless type == "Resource"
      faction = parts.shift
      parts.shift
      effects = []
      effects.push(parts.shift())
      effects.push(parts.shift())
      effects.push(parts.shift())
      effects.push(parts.shift())
      setId = parts.shift
      setId = parse_set(setId)
      externalId = make_reference_external_id(title)
      upgradeXml = <<-SHIPXML
      <Reference>
        <Title>#{title}</Title>
        <Ability>#{effects.join("\n").chomp}</Ability>
        <Type>#{type}</Type>
        <Id>#{externalId}</Id>
      </Reference>
      SHIPXML
      new_reference.puts upgradeXml
    end
end
