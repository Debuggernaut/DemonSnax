# DemonSnax
Demonic Consumption rotation helper

Easiest way to use this addon:
- Install TellMeWhen
- Install this addon (via WoWUp, go to "Install from URL" and paste in the URL.. once I post a release anyway)
- Create TellMeWhen icons using these lua snippets:

--Icon 1: (Last Hand of Gul'dan before your tyrant, AKA "Tyrant Soon")
if DemonSnax_LastHandAlert ~= nil then return DemonSnax_LastHandAlert(); else return false; end

--Icon 2: (Cast tyrant next, AKA "Tyrant Now")
if DemonSnax_TyrantAlert ~= nil then return DemonSnax_TyrantAlert(); else return false; end

