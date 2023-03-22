local traits = require("traits")
local object = require("object")

traits.allowedTraits("strategicImprovement","sample trait 1","fighter","bomber","fighterBomber","canBuildAirfield","photoRecon")

-- object 'traits' are strings that you can "assign" to
-- objects, and check elsewhere in your code if a particular
-- object has a particular trait.  If you have a trait "tank",
-- assigning the "tank" trait to a unit type is like
-- adding that unit type to the list of "tank"s,
-- and you can access that list with the traits module.
--
-- To prevent typos, you can only use trait strings that have
-- been registered by traits.allowedTraits.  The functions
-- traits.allowedTraits and traits.assign can take any number
-- of arguments, and you can also supply traits within tables
-- if that makes sense.

-- Unit Type Traits

traits.assign(object.uRedArmyGroup,"sample trait 1")
traits.assign(object.uConstructionTeam,"sample trait 1")
traits.assign(object.uBofors40mm,"sample trait 1")
traits.assign(object.uEarlyRadar,"sample trait 1")
traits.assign(object.uAdvancedRadar,"sample trait 1")
traits.assign(object.uFw200,"sample trait 1")
traits.assign(object.uFreightTrain,"sample trait 1")
traits.assign(object.uRailyard,"sample trait 1")
traits.assign(object.uAerialPhotos,"sample trait 1")
traits.assign(object.uSdkfz72,"sample trait 1")
traits.assign(object.u88mmFlakBattery,"sample trait 1")
traits.assign(object.uFlakTrain,"sample trait 1")
traits.assign(object.uMe109G6,"fighter")
traits.assign(object.uMe109G14,"fighter")
traits.assign(object.uMe109K4,"fighter")
traits.assign(object.uFw190A5,"fighter")
traits.assign(object.uFw190A8,"fighter")
traits.assign(object.uFw190D9,"fighter")
traits.assign(object.uTa152,"fighter")
traits.assign(object.uMilitaryPort,"sample trait 1")
traits.assign(object.uMe110,"sample trait 1")
traits.assign(object.uMe410,"sample trait 1")
traits.assign(object.uJu88C,"sample trait 1")
traits.assign(object.uJu88G,"sample trait 1")
traits.assign(object.uHe219,"sample trait 1")
traits.assign(object.uHe162,"sample trait 1")
traits.assign(object.uMe163,"sample trait 1")
traits.assign(object.uMe262,"sample trait 1")
traits.assign(object.uJu87G,"sample trait 1")
traits.assign(object.uFw190F8,"sample trait 1")
traits.assign(object.uDo335,"sample trait 1")
traits.assign(object.uDo217,"sample trait 1")
traits.assign(object.uHe277,"sample trait 1")
traits.assign(object.uArado234,"sample trait 1")
traits.assign(object.uGo229,"sample trait 1")
traits.assign(object.uSpitfireIX,"fighter")
traits.assign(object.uSpitfireXII,"fighter")
traits.assign(object.uSpitfireXIV,"fighter")
traits.assign(object.uHurricaneIV,"fighterBomber")
traits.assign(object.uTyphoon,"fighterBomber")
traits.assign(object.uTempest,"fighterBomber")
traits.assign(object.uMeteor,"sample trait 1")
traits.assign(object.uBeaufighter,"sample trait 1")
traits.assign(object.uMosquitoNFMkII,"sample trait 1")
traits.assign(object.uMosquitoNFMkXIII,"sample trait 1")
traits.assign(object.uIndustry,"sample trait 1")
traits.assign(object.uFw190A5Rocket,"sample trait 1")
traits.assign(object.uFw190A8Rocket,"sample trait 1")
traits.assign(object.uMe109G6Rocket,"sample trait 1")
traits.assign(object.uBarrageBalloons,"sample trait 1")
traits.assign(object.uP47D11,"sample trait 1")
traits.assign(object.uP47D25,"sample trait 1")
traits.assign(object.uP47D40,"sample trait 1")
traits.assign(object.uExperten,"sample trait 1")
traits.assign(object.uP38H,"sample trait 1")
traits.assign(object.uP38J,"sample trait 1")
traits.assign(object.uP51B,"sample trait 1")
traits.assign(object.uP51D,"sample trait 1")
traits.assign(object.uP80,"sample trait 1")
traits.assign(object.uStirling,"sample trait 1")
traits.assign(object.uHalifax,"sample trait 1")
traits.assign(object.uLancaster,"sample trait 1")
traits.assign(object.uPathfinder,"sample trait 1")
traits.assign(object.uA20,"bomber")
traits.assign(object.uB26,"sample trait 1")
traits.assign(object.uA26,"sample trait 1")
traits.assign(object.uB17F,"sample trait 1")
traits.assign(object.uB24J,"sample trait 1")
traits.assign(object.uB17G,"sample trait 1")
traits.assign(object.uBattleGroupGerman,"sample trait 1")
traits.assign(object.uDepletedBattleGroupGerman,"sample trait 1")
traits.assign(object.uEgonMayer,"sample trait 1")
traits.assign(object.u37inchFlak,"sample trait 1")
traits.assign(object.uHe111,"sample trait 1")
traits.assign(object.uBattleGroupAllied,"sample trait 1")
traits.assign(object.uDepletedBattleGroupAllied,"sample trait 1")
traits.assign(object.uSunderland,"sample trait 1")
traits.assign(object.uSAVE16,"sample trait 1")
traits.assign(object.uHermannGraf,"sample trait 1")
traits.assign(object.uJosefPriller,"sample trait 1")
traits.assign(object.uAdolfGalland,"sample trait 1")
traits.assign(object.uTaskForceG,"sample trait 1")
traits.assign(object.uTaskForceA,"sample trait 1")
traits.assign(object.u332ndFG,"sample trait 1")
traits.assign(object.u15thAFBombers,"sample trait 1")
traits.assign(object.uAircraftFactory,"sample trait 1")
traits.assign(object.uMe109G14Rocket,"sample trait 1")
traits.assign(object.uSAVE17,"sample trait 1")
traits.assign(object.uRefinery,"sample trait 1")
traits.assign(object.uGuntherRall,"sample trait 1")
traits.assign(object.uWalterNowotny,"sample trait 1")
traits.assign(object.uUrbanCenter,"sample trait 1")
traits.assign(object.uWhirlwind,"sample trait 1")
traits.assign(object.uB25,"sample trait 1")
traits.assign(object.uGunBattery,"sample trait 1")
traits.assign(object.uP61,"sample trait 1")
traits.assign(object.uMosquitoBIV,"sample trait 1")
traits.assign(object.uFrancisGabreski,"sample trait 1")
traits.assign(object.uGeorgePreddy,"sample trait 1")
traits.assign(object.uJohnBraham,"sample trait 1")
traits.assign(object.uJohnnieJohnson,"sample trait 1")
traits.assign(object.uWindow,"sample trait 1")
traits.assign(object.uHWSchnaufer,"sample trait 1")
traits.assign(object.uEirchHartmann,"sample trait 1")
traits.assign(object.uPanzerDivision,"sample trait 1")
traits.assign(object.uDamagedB17F,"sample trait 1")
traits.assign(object.uNeutralTerritory,"sample trait 1")
traits.assign(object.uDamagedB17G,"sample trait 1")
traits.assign(object.uP38L,"sample trait 1")
traits.assign(object.uCriticalIndustry,"sample trait 1")
traits.assign(object.uGerhardBarkhorn,"sample trait 1")
traits.assign(object.uAircraftCarrier,"sample trait 1")
traits.assign(object.uUSAAFAce,"sample trait 1")
traits.assign(object.uRAFAce,"sample trait 1")
traits.assign(object.uBarrage,"sample trait 1")
traits.assign(object.uConvoy,"sample trait 1")
traits.assign(object.uSAVE18,"sample trait 1")
traits.assign(object.uYak3,"sample trait 1")
traits.assign(object.uIl2,"sample trait 1")
traits.assign(object.u37cmFlak,"sample trait 1")
traits.assign(object.uJu188PR,"photoRecon")
traits.assign(object.uV1LaunchSite,"sample trait 1")
traits.assign(object.uV2LaunchSite,"sample trait 1")
traits.assign(object.uV1Buzzbomb,"sample trait 1")
traits.assign(object.uV2Rocket,"sample trait 1")
traits.assign(object.uMosquitoPR,"photoRecon")
traits.assign(object.uWolfPack,"sample trait 1")

-- Tribe Traits

traits.assign(object.pNeutrals,"sample trait 1")
traits.assign(object.pAllies,"sample trait 1")
traits.assign(object.pGermans,"sample trait 1")
traits.assign(object.pEvents,"sample trait 1")
traits.assign(object.pNotused,"sample trait 1")
traits.assign(object.pNotused_,"sample trait 1")
traits.assign(object.pNotused__,"sample trait 1")
traits.assign(object.pNotused___,"sample trait 1")

-- Tech Traits

traits.assign(object.aInterceptorsI,"sample trait 1")
traits.assign(object.aInterceptorsII,"sample trait 1")
traits.assign(object.aInterceptorsIII,"sample trait 1")
traits.assign(object.aEscortFightersI,"sample trait 1")
traits.assign(object.aEscortFightersII,"sample trait 1")
traits.assign(object.aNightBombingI,"sample trait 1")
traits.assign(object.aEscortFightersIII,"sample trait 1")
traits.assign(object.aNOTUSED,"sample trait 1")
traits.assign(object.aCadillacoftheSkies,"sample trait 1")
traits.assign(object.a1940sTechI,"sample trait 1")
traits.assign(object.aBomberDestroyersI,"sample trait 1")
traits.assign(object.aBomberDestroyersII,"sample trait 1")
traits.assign(object.aInterceptorsIV,"sample trait 1")
traits.assign(object.aNightFightersI,"sample trait 1")
traits.assign(object.aNightFightersII,"sample trait 1")
traits.assign(object.aTheGrandAlliance,"sample trait 1")
traits.assign(object.aNightFightersIII,"sample trait 1")
traits.assign(object.aAdvancedRadarI,"sample trait 1")
traits.assign(object.aNOTUSED_,"sample trait 1")
traits.assign(object.aAdvancedRadarII,"sample trait 1")
traits.assign(object.aEnginesI,"sample trait 1")
traits.assign(object.aNOTUSED__,"sample trait 1")
traits.assign(object.aEnginesII,"sample trait 1")
traits.assign(object.aEnginesIII,"sample trait 1")
traits.assign(object.aNightBombingII,"sample trait 1")
traits.assign(object.aJaboI,"sample trait 1")
traits.assign(object.aJaboII,"sample trait 1")
traits.assign(object.aJaboIII,"sample trait 1")
traits.assign(object.aEnginesIV,"sample trait 1")
traits.assign(object.aExperimentalDesign,"sample trait 1")
traits.assign(object.aVolksjger,"sample trait 1")
traits.assign(object.aNOTUSED___,"sample trait 1")
traits.assign(object.aCentrifugalFlowEngine,"sample trait 1")
traits.assign(object.aAxialFlowCompressor,"sample trait 1")
traits.assign(object.aNOTUSED____,"sample trait 1")
traits.assign(object.aNOTUSED_____,"sample trait 1")
traits.assign(object.aJetFighters,"sample trait 1")
traits.assign(object.aTheThirdReich,"sample trait 1")
traits.assign(object.aJetFighterDesign,"sample trait 1")
traits.assign(object.aJetBombersI,"sample trait 1")
traits.assign(object.aJetBombersII,"sample trait 1")
traits.assign(object.aWunderwaffeProgram,"sample trait 1")
traits.assign(object.aPulseJetEngines,"sample trait 1")
traits.assign(object.aVergeltungswaffen1,"sample trait 1")
traits.assign(object.aRocketry,"sample trait 1")
traits.assign(object.aVergeltungswaffen2,"sample trait 1")
traits.assign(object.aStrategicBombersI,"sample trait 1")
traits.assign(object.aStrategicBombersII,"sample trait 1")
traits.assign(object.aStrategicBombersIII,"sample trait 1")
traits.assign(object.aWindow,"sample trait 1")
traits.assign(object.aTacticalBombersI,"sample trait 1")
traits.assign(object.aTacticalBombersII,"sample trait 1")
traits.assign(object.aTacticalBombersIII,"sample trait 1")
traits.assign(object.aRocketFighters,"sample trait 1")
traits.assign(object.aNOTUSED______,"sample trait 1")
traits.assign(object.a1940sTechII,"sample trait 1")
traits.assign(object.a1940sTechIII,"sample trait 1")
traits.assign(object.aJetFighterFocus,"sample trait 1")
traits.assign(object.aJgernotprogramm,"sample trait 1")
traits.assign(object.aWildeSau,"sample trait 1")
traits.assign(object.aNightBombingIII,"sample trait 1")
traits.assign(object.aIndustryI,"sample trait 1")
traits.assign(object.aIndustryII,"sample trait 1")
traits.assign(object.aIndustryIII,"sample trait 1")
traits.assign(object.aFuelProductionI,"sample trait 1")
traits.assign(object.aFuelProductionII,"sample trait 1")
traits.assign(object.aNOTUSED_______,"sample trait 1")
traits.assign(object.aNOTUSED________,"sample trait 1")
traits.assign(object.aFuelProductionIII,"sample trait 1")
traits.assign(object.aWarEconomy,"sample trait 1")
traits.assign(object.aRationing,"sample trait 1")
traits.assign(object.aTheAxisPowers,"sample trait 1")
traits.assign(object.aJgerstab,"sample trait 1")
traits.assign(object.aFoggiaAirfields,"sample trait 1")
traits.assign(object.aOperationOverlordPrep,"sample trait 1")
traits.assign(object.aOperationNeptune,"sample trait 1")
traits.assign(object.aVistulaOderOffensive,"sample trait 1")
traits.assign(object.aTuskeegeeAirmen,"sample trait 1")
traits.assign(object.aMassProductionFocus,"sample trait 1")
traits.assign(object.aHighTechnologyFocus,"sample trait 1")
traits.assign(object.aArgumentforJetJabo,"sample trait 1")
traits.assign(object.aJetFightersPrioritized,"sample trait 1")
traits.assign(object.a1940sTechIV,"sample trait 1")
traits.assign(object.aProximityFuses,"sample trait 1")
traits.assign(object.aAircraftPrototypes,"sample trait 1")
traits.assign(object.aSearchforLongRangeFighter,"sample trait 1")
traits.assign(object.aTheAllisonPoweredMustang,"sample trait 1")
traits.assign(object.aRollsRoyceMerlin61Refit,"sample trait 1")
traits.assign(object.aAdvancedRadarIII,"sample trait 1")
traits.assign(object.aDelays,"sample trait 1")
traits.assign(object.aTacticsI,"sample trait 1")
traits.assign(object.aTacticsII,"sample trait 1")
traits.assign(object.aTacticsIII,"sample trait 1")
traits.assign(object.aRoamatWill,"sample trait 1")
traits.assign(object.aLongRangeEscortsNeeded,"sample trait 1")
traits.assign(object.aAlbertSpeersDeath,"sample trait 1")
traits.assign(object.aPoliticalSupportI,"sample trait 1")
traits.assign(object.aPoliticalSupportII,"sample trait 1")
traits.assign(object.aPoliticalSupportIII,"sample trait 1")
traits.assign(object.aPoliticalSupportIV,"sample trait 1")

-- Improvement Traits

traits.assign(object.iNothing,"sample trait 1")
traits.assign(object.iHeadquarters,"sample trait 1")
traits.assign(object.iNOTUSED,"sample trait 1")
traits.assign(object.iRedArmy,"sample trait 1")
traits.assign(object.iCivilianPopulationI,"strategicImprovement")
traits.assign(object.iFuelRefineryI,"strategicImprovement")
traits.assign(object.iAircraftFactoryI,"strategicImprovement")
traits.assign(object.iQuartermaster,"sample trait 1")
traits.assign(object.iCityI,"sample trait 1")
traits.assign(object.iCityII,"sample trait 1")
traits.assign(object.iFuelRefineryII,"strategicImprovement")
traits.assign(object.iCivilianPopulationII,"strategicImprovement")
traits.assign(object.iAircraftFactoryII,"strategicImprovement")
traits.assign(object.iCriticalIndustry,"strategicImprovement")
traits.assign(object.iCivilianPopulationIII,"strategicImprovement")
traits.assign(object.iIndustryI,"strategicImprovement")
traits.assign(object.iIndustryII,"strategicImprovement")
traits.assign(object.iAirbase,"sample trait 1")
traits.assign(object.i15thAirForce,"sample trait 1")
traits.assign(object.iOLDIndustryIII,"sample trait 1")
traits.assign(object.iNOTUSED_,"sample trait 1")
traits.assign(object.iNOTUSED__,"sample trait 1")
traits.assign(object.iFuelRefineryIII,"strategicImprovement")
traits.assign(object.iCityIII,"sample trait 1")
traits.assign(object.iRationing,"sample trait 1")
traits.assign(object.iRailyards,"strategicImprovement")
traits.assign(object.iAircraftFactoryIII,"strategicImprovement")
traits.assign(object.iExperimentalAircraft,"sample trait 1")
traits.assign(object.iFirefighters,"sample trait 1")
traits.assign(object.iIndustryIII,"strategicImprovement")
traits.assign(object.iDocks,"sample trait 1")
traits.assign(object.iNOTUSED___,"sample trait 1")
traits.assign(object.iJagdfliegerschule,"sample trait 1")
traits.assign(object.iWehrmacht,"sample trait 1")
traits.assign(object.iMilitaryPort,"strategicImprovement")
traits.assign(object.iNOTUSED____,"sample trait 1")

-- Wonder Traits

traits.assign(object.wNOTUSED,"sample trait 1")
traits.assign(object.wNOTUSED_,"sample trait 1")
traits.assign(object.wIGFarben,"sample trait 1")
traits.assign(object.wNOTUSED__,"sample trait 1")
traits.assign(object.wNOTUSED___,"sample trait 1")
traits.assign(object.wNOTUSED____,"sample trait 1")
traits.assign(object.wNOTUSED_____,"sample trait 1")
traits.assign(object.wNOTUSED______,"sample trait 1")
traits.assign(object.wKruppWorks,"sample trait 1")
traits.assign(object.wNOTUSED_______,"sample trait 1")
traits.assign(object.wNOTUSED________,"sample trait 1")
traits.assign(object.wPeenemnde,"sample trait 1")
traits.assign(object.wNOTUSED_________,"sample trait 1")
traits.assign(object.wNOTUSED__________,"sample trait 1")
traits.assign(object.wNOTUSED___________,"sample trait 1")
traits.assign(object.wAdolfHitler,"sample trait 1")
traits.assign(object.wJgernotprogramm,"sample trait 1")
traits.assign(object.wAlbertSpeersReforms,"sample trait 1")
traits.assign(object.w56thFighterGroup,"sample trait 1")
traits.assign(object.wNo617RAF,"sample trait 1")
traits.assign(object.wJG2Richthofen,"sample trait 1")
traits.assign(object.wNOTUSED____________,"sample trait 1")
traits.assign(object.wArsenalofDemocracy,"sample trait 1")
traits.assign(object.wNOTUSED_____________,"sample trait 1")
traits.assign(object.wJG26Schlageter,"sample trait 1")
traits.assign(object.wNOTUSED______________,"sample trait 1")
traits.assign(object.wNOTUSED_______________,"sample trait 1")
traits.assign(object.wNOTUSED________________,"sample trait 1")

-- Base Terrain Traits

traits.assign(object.bCityLowBase,"sample trait 1")
traits.assign(object.bRailtrackLowBase,"sample trait 1")
traits.assign(object.bGrasslandLowBase,"canBuildAirfield")
traits.assign(object.bForestLowBase,"canBuildAirfield")
traits.assign(object.bUrbanLowBase,"sample trait 1")
traits.assign(object.bHillsLowBase,"canBuildAirfield")
traits.assign(object.bRefineryLowBase,"sample trait 1")
traits.assign(object.bInstallationLowBase,"sample trait 1")
traits.assign(object.bIndustryLowBase,"sample trait 1")
traits.assign(object.bAirfieldLowBase,"sample trait 1")
traits.assign(object.bWaterLowBase,"sample trait 1")
traits.assign(object.bBombedRRLowBase,"sample trait 1")
traits.assign(object.bBombedRefineryLowBase,"sample trait 1")
traits.assign(object.bBombedUrbanLowBase,"sample trait 1")
traits.assign(object.bBombedIndustryLowBase,"sample trait 1")
traits.assign(object.bCityHighBase,"sample trait 1")
traits.assign(object.bHillsHighBase,"sample trait 1")
traits.assign(object.bGrasslandHighBase,"sample trait 1")
traits.assign(object.bForestHighBase,"sample trait 1")
traits.assign(object.bUrbanHighBase,"sample trait 1")
traits.assign(object.bCloudCoverHighBase,"sample trait 1")
traits.assign(object.bRefineryHighBase,"sample trait 1")
traits.assign(object.bSAVEHighBase,"sample trait 1")
traits.assign(object.bIndustryHighBase,"sample trait 1")
traits.assign(object.bAirfieldHighBase,"sample trait 1")
traits.assign(object.bWaterHighBase,"sample trait 1")
traits.assign(object.bRubbleHighBase,"sample trait 1")
traits.assign(object.bBombedRefineryHighBase,"sample trait 1")
traits.assign(object.bBombedRRHighBase,"sample trait 1")
traits.assign(object.bBombedIndustryHighBase,"sample trait 1")
traits.assign(object.bCityNightBase,"sample trait 1")
traits.assign(object.bRailtrackNightBase,"sample trait 1")
traits.assign(object.bGrasslandNightBase,"sample trait 1")
traits.assign(object.bForestNightBase,"sample trait 1")
traits.assign(object.bUrbanNightBase,"sample trait 1")
traits.assign(object.bCloudCoverNightBase,"sample trait 1")
traits.assign(object.bSearchlightsNightBase,"sample trait 1")
traits.assign(object.bHillsNightBase,"sample trait 1")
traits.assign(object.bBombedRRNightBase,"sample trait 1")
traits.assign(object.bAirfieldNightBase,"sample trait 1")
traits.assign(object.bWaterNightBase,"sample trait 1")
traits.assign(object.bFirestormNightBase,"sample trait 1")
traits.assign(object.bRubbleNightBase,"sample trait 1")
traits.assign(object.bBombedRRRubleNightBase,"sample trait 1")
traits.assign(object.bBombedIndustryNightBase,"sample trait 1")

-- Terrain Traits

traits.assign(object.tCityLowBase,"sample trait 1")
traits.assign(object.tCityLowFish,"sample trait 1")
traits.assign(object.tCityLowWhale,"sample trait 1")
traits.assign(object.tRailtrackLowBase,"sample trait 1")
traits.assign(object.tRailtrackLowFish,"sample trait 1")
traits.assign(object.tRailtrackLowWhale,"sample trait 1")
traits.assign(object.tGrasslandLowBase,"sample trait 1")
traits.assign(object.tForestLowBase,"sample trait 1")
traits.assign(object.tLumberLowFish,"sample trait 1")
traits.assign(object.tGameLowWhale,"sample trait 1")
traits.assign(object.tUrbanLowBase,"sample trait 1")
traits.assign(object.tUrbanLowFish,"sample trait 1")
traits.assign(object.tUrbanLowWhale,"sample trait 1")
traits.assign(object.tHillsLowBase,"sample trait 1")
traits.assign(object.tCoalLowFish,"sample trait 1")
traits.assign(object.tIronLowWhale,"sample trait 1")
traits.assign(object.tRefineryLowBase,"sample trait 1")
traits.assign(object.tRefineryLowFish,"sample trait 1")
traits.assign(object.tRefineryLowWhale,"sample trait 1")
traits.assign(object.tInstallationLowBase,"sample trait 1")
traits.assign(object.tInstallationLowFish,"sample trait 1")
traits.assign(object.tInstallationLowWhale,"sample trait 1")
traits.assign(object.tIndustryLowBase,"sample trait 1")
traits.assign(object.tAssemblyLineLowFish,"sample trait 1")
traits.assign(object.tAssemblyLineLowWhale,"sample trait 1")
traits.assign(object.tAirfieldLowBase,"sample trait 1")
traits.assign(object.tAirfieldLowFish,"sample trait 1")
traits.assign(object.tAirfieldLowWhale,"sample trait 1")
traits.assign(object.tWaterLowBase,"sample trait 1")
traits.assign(object.tWaterLowFish,"sample trait 1")
traits.assign(object.tWaterLowWhale,"sample trait 1")
traits.assign(object.tBombedRRLowBase,"sample trait 1")
traits.assign(object.tBombedRRLowFish,"sample trait 1")
traits.assign(object.tBombedRRLowWhale,"sample trait 1")
traits.assign(object.tBombedRefineryLowBase,"sample trait 1")
traits.assign(object.tBombedRefineryLowFish,"sample trait 1")
traits.assign(object.tBombedRefineryLowWhale,"sample trait 1")
traits.assign(object.tBombedUrbanLowBase,"sample trait 1")
traits.assign(object.tBombedUrbanLowFish,"sample trait 1")
traits.assign(object.tBombedUrbanLowWhale,"sample trait 1")
traits.assign(object.tBombedIndustryLowBase,"sample trait 1")
traits.assign(object.tBombedIndustryLowFish,"sample trait 1")
traits.assign(object.tBombedIndustryLowWhale,"sample trait 1")
traits.assign(object.tCityHighBase,"sample trait 1")
traits.assign(object.tCityHighFish,"sample trait 1")
traits.assign(object.tCityHighWhale,"sample trait 1")
traits.assign(object.tHillsHighBase,"sample trait 1")
traits.assign(object.tHillsHighFish,"sample trait 1")
traits.assign(object.tHillsHighWhale,"sample trait 1")
traits.assign(object.tGrasslandHighBase,"sample trait 1")
traits.assign(object.tForestHighBase,"sample trait 1")
traits.assign(object.tForestHighFish,"sample trait 1")
traits.assign(object.tForestHighWhale,"sample trait 1")
traits.assign(object.tUrbanHighBase,"sample trait 1")
traits.assign(object.tUrbanHighFish,"sample trait 1")
traits.assign(object.tUrbanHighWhale,"sample trait 1")
traits.assign(object.tCloudCoverHighBase,"sample trait 1")
traits.assign(object.tCloudCoverHighFish,"sample trait 1")
traits.assign(object.tCloudCoverHighWhale,"sample trait 1")
traits.assign(object.tRefineryHighBase,"sample trait 1")
traits.assign(object.tRefineryHighFish,"sample trait 1")
traits.assign(object.tRefineryHighWhale,"sample trait 1")
traits.assign(object.tSAVEHighBase,"sample trait 1")
traits.assign(object.tSAVEHighFish,"sample trait 1")
traits.assign(object.tSAVEHighWhale,"sample trait 1")
traits.assign(object.tIndustryHighBase,"sample trait 1")
traits.assign(object.tIndustryHighFish,"sample trait 1")
traits.assign(object.tIndustryHighWhale,"sample trait 1")
traits.assign(object.tAirfieldHighBase,"sample trait 1")
traits.assign(object.tAirfieldHighFish,"sample trait 1")
traits.assign(object.tAirfieldHighWhale,"sample trait 1")
traits.assign(object.tWaterHighBase,"sample trait 1")
traits.assign(object.tWaterHighFish,"sample trait 1")
traits.assign(object.tWaterHighWhale,"sample trait 1")
traits.assign(object.tRubbleHighBase,"sample trait 1")
traits.assign(object.tRubbleHighFish,"sample trait 1")
traits.assign(object.tRubbleHighWhale,"sample trait 1")
traits.assign(object.tBombedRefineryHighBase,"sample trait 1")
traits.assign(object.tBombedRefineryHighFish,"sample trait 1")
traits.assign(object.tBombedRefineryHighWhale,"sample trait 1")
traits.assign(object.tBombedRRHighBase,"sample trait 1")
traits.assign(object.tBombedRRHighFish,"sample trait 1")
traits.assign(object.tBombedRRHighWhale,"sample trait 1")
traits.assign(object.tBombedIndustryHighBase,"sample trait 1")
traits.assign(object.tBombedIndustryHighFish,"sample trait 1")
traits.assign(object.tBombedIndustryHighWhale,"sample trait 1")
traits.assign(object.tCityNightBase,"sample trait 1")
traits.assign(object.tCityNightFish,"sample trait 1")
traits.assign(object.tCityNightWhale,"sample trait 1")
traits.assign(object.tRailtrackNightBase,"sample trait 1")
traits.assign(object.tRailtrackNightFish,"sample trait 1")
traits.assign(object.tRailtrackNightWhale,"sample trait 1")
traits.assign(object.tGrasslandNightBase,"sample trait 1")
traits.assign(object.tForestNightBase,"sample trait 1")
traits.assign(object.tForestNightFish,"sample trait 1")
traits.assign(object.tForestNightWhale,"sample trait 1")
traits.assign(object.tUrbanNightBase,"sample trait 1")
traits.assign(object.tUrbanNightFish,"sample trait 1")
traits.assign(object.tUrbanNightWhale,"sample trait 1")
traits.assign(object.tCloudCoverNightBase,"sample trait 1")
traits.assign(object.tCloudCoverNightFish,"sample trait 1")
traits.assign(object.tCloudCoverNightWhale,"sample trait 1")
traits.assign(object.tSearchlightsNightBase,"sample trait 1")
traits.assign(object.tSearchlightsNightFish,"sample trait 1")
traits.assign(object.tSearchlightsNightWhale,"sample trait 1")
traits.assign(object.tHillsNightBase,"sample trait 1")
traits.assign(object.tHillsNightFish,"sample trait 1")
traits.assign(object.tHillsNightWhale,"sample trait 1")
traits.assign(object.tBombedRRNightBase,"sample trait 1")
traits.assign(object.tBombedRRNightFish,"sample trait 1")
traits.assign(object.tBombedRRNightWhale,"sample trait 1")
traits.assign(object.tAirfieldNightBase,"sample trait 1")
traits.assign(object.tAirfieldNightFish,"sample trait 1")
traits.assign(object.tAirfieldNightWhale,"sample trait 1")
traits.assign(object.tWaterNightBase,"sample trait 1")
traits.assign(object.tWaterNightFish,"sample trait 1")
traits.assign(object.tWaterNightWhale,"sample trait 1")
traits.assign(object.tFirestormNightBase,"sample trait 1")
traits.assign(object.tFirestormNightFish,"sample trait 1")
traits.assign(object.tFirestormNightWhale,"sample trait 1")
traits.assign(object.tRubbleNightBase,"sample trait 1")
traits.assign(object.tRubbleNightFish,"sample trait 1")
traits.assign(object.tRubbleNightWhale,"sample trait 1")
traits.assign(object.tBombedRRRubleNightBase,"sample trait 1")
traits.assign(object.tBombedRRRubleNightFish,"sample trait 1")
traits.assign(object.tBombedRRRubbleNightWhale,"sample trait 1")
traits.assign(object.tBombedIndustryNightBase,"sample trait 1")
traits.assign(object.tBombedIndustryNightFish,"sample trait 1")
traits.assign(object.tBombedIndustryNightWhale,"sample trait 1")

return {}

