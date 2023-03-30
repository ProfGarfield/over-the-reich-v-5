local flag = require("flag")
local counter = require("counter")
local text = require("text")
local gen = require("generalLibrary")

local object = gen.makeDataTable({},"object")
-- This line forbids reassignment of keys of the object table
-- This should prevent errors
gen.forbidReplacement(object)

-- Civilization Advances
-- recommended key prefix 'a'

object.aInterceptorsI           = civ.getTech(0)
object.aInterceptorsII          = civ.getTech(1)
object.aInterceptorsIII         = civ.getTech(2)
object.aEscortFightersI         = civ.getTech(3)
object.aEscortFightersII        = civ.getTech(4)
object.aNightBombingI           = civ.getTech(5)   --Automobile
object.aEscortFightersIII       = civ.getTech(6)
object.aNOTUSED                 = civ.getTech(7)   --Bridge Building
object.aCadillacoftheSkies      = civ.getTech(8)
object.a1940sTechI              = civ.getTech(9)
object.aBomberDestroyersI       = civ.getTech(10)
object.aBomberDestroyersII      = civ.getTech(11)
object.aInterceptorsIV          = civ.getTech(12)
object.aNightFightersI          = civ.getTech(13)
object.aNightFightersII         = civ.getTech(14)
object.aTheGrandAlliance        = civ.getTech(15)
object.aNightFightersIII        = civ.getTech(16)
object.aAdvancedRadarI          = civ.getTech(17)
object.aNOTUSED_                = civ.getTech(18)
object.aAdvancedRadarII         = civ.getTech(19)
object.aEnginesI                = civ.getTech(20)
object.aNOTUSED__               = civ.getTech(21)
object.aEnginesII               = civ.getTech(22)
object.aEnginesIII              = civ.getTech(23)
object.aNightBombingII          = civ.getTech(24)
object.aJaboI                   = civ.getTech(25)
object.aJaboII                  = civ.getTech(26)
object.aJaboIII                 = civ.getTech(27)
object.aEnginesIV               = civ.getTech(28)
object.aExperimentalDesign      = civ.getTech(29)
object.aVolksjger               = civ.getTech(30)
object.aNOTUSED___              = civ.getTech(31)
object.aCentrifugalFlowEngine   = civ.getTech(32)
object.aAxialFlowCompressor     = civ.getTech(33)
object.aNOTUSED____             = civ.getTech(34)
object.aNOTUSED_____            = civ.getTech(35)
object.aJetFighters             = civ.getTech(36)
object.aTheThirdReich           = civ.getTech(37)
object.aJetFighterDesign        = civ.getTech(38)
object.aJetBombersI             = civ.getTech(39)
object.aJetBombersII            = civ.getTech(40)
object.aWunderwaffeProgram      = civ.getTech(41)
object.aPulseJetEngines         = civ.getTech(42)
object.aVergeltungswaffen1      = civ.getTech(43)
object.aRocketry                = civ.getTech(44)
object.aVergeltungswaffen2      = civ.getTech(45)
object.aStrategicBombersI       = civ.getTech(46)
object.aStrategicBombersII      = civ.getTech(47)
object.aStrategicBombersIII     = civ.getTech(48)
object.aWindow                  = civ.getTech(49)
object.aTacticalBombersI        = civ.getTech(50)
object.aTacticalBombersII       = civ.getTech(51)
object.aTacticalBombersIII      = civ.getTech(52)
object.aRocketFighters          = civ.getTech(53)
object.aNOTUSED______           = civ.getTech(54)
object.a1940sTechII             = civ.getTech(55)
object.a1940sTechIII            = civ.getTech(56)
object.aJetFighterFocus         = civ.getTech(57)
object.aJgernotprogramm         = civ.getTech(58)
object.aWildeSau                = civ.getTech(59)
object.aNightBombingIII         = civ.getTech(60)
object.aIndustryI               = civ.getTech(61)
object.aIndustryII              = civ.getTech(62)
object.aIndustryIII             = civ.getTech(63)
object.aFuelProductionI         = civ.getTech(64)
object.aFuelProductionII        = civ.getTech(65)
object.aNOTUSED_______          = civ.getTech(66)
object.aNOTUSED________         = civ.getTech(67)
object.aFuelProductionIII       = civ.getTech(68)
object.aWarEconomy              = civ.getTech(69)
object.aRationing               = civ.getTech(70)
object.aTheAxisPowers           = civ.getTech(71)
object.aJgerstab                = civ.getTech(72)
object.aFoggiaAirfields         = civ.getTech(73)
object.aOperationOverlordPrep   = civ.getTech(74)
object.aOperationNeptune        = civ.getTech(75)
object.aVistulaOderOffensive    = civ.getTech(76)
object.aTuskeegeeAirmen         = civ.getTech(77)
object.aMassProductionFocus     = civ.getTech(78)
object.aHighTechnologyFocus     = civ.getTech(79)
object.aArgumentforJetJabo      = civ.getTech(80)
object.aJetFightersPrioritized  = civ.getTech(81)
object.a1940sTechIV             = civ.getTech(82)
object.aProximityFuses          = civ.getTech(83)
object.aAircraftPrototypes      = civ.getTech(84)
object.aSearchforLongRangeFighter= civ.getTech(85)
object.aTheAllisonPoweredMustang= civ.getTech(86)
object.aRollsRoyceMerlin61Refit = civ.getTech(87)
object.aAdvancedRadarIII        = civ.getTech(88)
object.aDelays                  = civ.getTech(89)
object.aTacticsI                = civ.getTech(90)
object.aTacticsII               = civ.getTech(91)
object.aTacticsIII              = civ.getTech(92)
object.aRoamatWill              = civ.getTech(93)
object.aLongRangeEscortsNeeded  = civ.getTech(94)
object.aAlbertSpeersDeath       = civ.getTech(95)
object.aPoliticalSupportI       = civ.getTech(96)
object.aPoliticalSupportII      = civ.getTech(97)
object.aPoliticalSupportIII     = civ.getTech(98)
object.aPoliticalSupportIV      = civ.getTech(99)

-- Map Locations (tiles/squares)
-- recommended key prefix 'l'


-- Locations of cities starting the scenario owned by the Neutrals:


-- Locations of cities starting the scenario owned by the Allies:

object.lLondon                  =civ.getTile(172,68,0)
object.lPortsmouth              =civ.getTile(154,72,0)
object.lBristol                 =civ.getTile(139,65,0)
object.lSwansea                 =civ.getTile(119,61,0)
object.lPlymouth                =civ.getTile(110,72,0)
object.lCardiff                 =civ.getTile(131,63,0)
object.lLiverpool               =civ.getTile(140,44,0)
object.lBirmingham              =civ.getTile(150,54,0)
object.lManchester              =civ.getTile(151,43,0)
object.lNottingham              =civ.getTile(164,48,0)
object.lSheffield               =civ.getTile(167,41,0)
object.lColchester              =civ.getTile(193,65,0)
object.lHull                    =civ.getTile(181,43,0)
object.lNewcastle               =civ.getTile(171,27,0)
object.lEdinburgh               =civ.getTile(163,13,0)
object.lGlasgow                 =civ.getTile(137,11,0)
object.lBelfast                 =civ.getTile(112,22,0)
object.lCarlisle                =civ.getTile(152,24,0)
object.lLeeds                   =civ.getTile(166,32,0)
object.lRussianFront            =civ.getTile(406,74,0)
object.lItalianTheatre          =civ.getTile(345,145,0)
object.lManstonAF               =civ.getTile(191,73,0)
object.lBoxtedAF                =civ.getTile(197,63,0)
object.lCroydonAF               =civ.getTile(173,75,0)
object.lBoltHeadAF              =civ.getTile(117,71,0)
object.lDuxfordAF               =civ.getTile(176,60,0)
object.lRidgewellAF             =civ.getTile(181,57,0)
object.lWinktonAF               =civ.getTile(148,72,0)
object.lDumfriesAFN             =civ.getTile(149,17,2)
object.lWoodfordAFN             =civ.getTile(154,48,2)
object.lWinktonAFN              =civ.getTile(148,72,2)
object.lBoltHeadAFN             =civ.getTile(117,71,2)
object.lCroydonAFN              =civ.getTile(173,75,2)
object.lManstonAFN              =civ.getTile(191,73,2)
object.lBoxtedAFN               =civ.getTile(197,63,2)
object.lDremAF                  =civ.getTile(168,16,0)
object.lWoodfordAF              =civ.getTile(154,48,0)
object.lDumfriesAF              =civ.getTile(149,17,0)
object.lRidgewellAFN            =civ.getTile(181,57,2)
object.lDuxfordAFN              =civ.getTile(176,60,2)
object.lDremAFN                 =civ.getTile(168,16,2)
object.lMullaghmoreN            =civ.getTile(108,18,2)
object.lDover                   =civ.getTile(185,75,0)
object.lMullaghmoreAF           =civ.getTile(108,18,0)
object.lKingsCliffeAF           =civ.getTile(179,53,0)
object.lKingsCliffN             =civ.getTile(179,53,2)
object.lMolesworthAF            =civ.getTile(175,55,0)
object.lMolesworthN             =civ.getTile(175,55,2)

-- Locations of cities starting the scenario owned by the Germans:

object.lBerlin                  =civ.getTile(363,71,0)
object.lDresden                 =civ.getTile(369,89,0)
object.lPrague                  =civ.getTile(375,101,0)
object.lVienna                  =civ.getTile(403,121,0)
object.lLeipzig                 =civ.getTile(352,90,0)
object.lMerseburg               =civ.getTile(347,85,0)
object.lRostock                 =civ.getTile(347,55,0)
object.lLneburg                 =civ.getTile(323,73,0)
object.lHannover                =civ.getTile(306,82,0)
object.lBremen                  =civ.getTile(299,63,0)
object.lWilhelmshaven           =civ.getTile(293,59,0)
object.lDsseldorf               =civ.getTile(271,79,0)
object.lCologne                 =civ.getTile(272,86,0)
object.lEssen                   =civ.getTile(274,76,0)
object.lDortmund                =civ.getTile(280,76,0)
object.lHamburg                 =civ.getTile(317,59,0)
object.lKiel                    =civ.getTile(324,50,0)
object.lLbeck                   =civ.getTile(332,56,0)
object.lNurnburg                =civ.getTile(326,106,0)
object.lMunich                  =civ.getTile(332,120,0)
object.lFriedrichshaven         =civ.getTile(300,124,0)
object.lSchweinfurt             =civ.getTile(315,101,0)
object.lFrankfurt               =civ.getTile(295,95,0)
object.lAarhus                  =civ.getTile(326,32,0)
object.lFreiburg                =civ.getTile(277,119,0)
object.lKarlsruhe               =civ.getTile(288,104,0)
object.lMannheim                =civ.getTile(292,100,0)
object.lStuttgart               =civ.getTile(298,110,0)
object.lRegensburg              =civ.getTile(344,108,0)
object.lLinz                    =civ.getTile(370,122,0)
object.lBrest                   =civ.getTile(90,94,0)
object.lStNazaire               =civ.getTile(118,108,0)
object.lNantes                  =civ.getTile(125,111,0)
object.lLaRochelle              =civ.getTile(127,125,0)
object.lBordeaux                =civ.getTile(130,142,0)
object.lCherbourg               =civ.getTile(142,84,0)
object.lLeHavre                 =civ.getTile(164,90,0)
object.lTours                   =civ.getTile(163,117,0)
object.lRouen                   =civ.getTile(176,92,0)
object.lParis                   =civ.getTile(195,101,0)
object.lBrussels                =civ.getTile(230,84,0)
object.lAmsterdam               =civ.getTile(245,65,0)
object.lTheHague                =civ.getTile(234,70,0)
object.lRotterdam               =civ.getTile(241,71,0)
object.lAntwerp                 =civ.getTile(231,77,0)
object.lLille                   =civ.getTile(211,87,0)
object.lCalais                  =civ.getTile(199,77,0)
object.lLyon                    =civ.getTile(212,140,0)
object.lBrunswick               =civ.getTile(339,75,0)
object.lPeenemnde               =civ.getTile(375,61,0)
object.lSchipholAF              =civ.getTile(240,66,0)
object.lSchipholN               =civ.getTile(240,66,2)
object.lWoensdrechtAF           =civ.getTile(223,79,0)
object.lWoensdrechtN            =civ.getTile(223,79,2)
object.lBeaumontAF              =civ.getTile(165,101,0)
object.lBeaumontN               =civ.getTile(165,101,2)
object.lVannesAF                =civ.getTile(113,105,0)
object.lVannesN                 =civ.getTile(113,105,2)
object.lLannesAF                =civ.getTile(139,139,0)
object.lLannesN                 =civ.getTile(139,139,2)
object.lCormeillesAF            =civ.getTile(191,93,0)
object.lCormeillesN             =civ.getTile(191,93,2)
object.lOstheimAF               =civ.getTile(287,93,0)
object.lOstheimN                =civ.getTile(287,93,2)
object.lOphovenAF               =civ.getTile(258,72,0)
object.lOphovenN                =civ.getTile(258,72,2)
object.lRheinsehlenAF           =civ.getTile(313,69,0)
object.lRheinsehlenN            =civ.getTile(313,69,2)
object.lEggebekAF               =civ.getTile(313,43,0)
object.lEggebekN                =civ.getTile(313,43,2)
object.lDberitzAF               =civ.getTile(352,70,0)
object.lDberitzN                =civ.getTile(352,70,2)
object.lKolledaAF               =civ.getTile(359,87,0)
object.lKolledaN                =civ.getTile(359,87,2)
object.lWelsAF                  =civ.getTile(364,122,0)
object.lWelsN                   =civ.getTile(364,122,2)
object.lPockingAF               =civ.getTile(341,117,0)
object.lPockingN                =civ.getTile(341,117,2)
object.lNellingandAF            =civ.getTile(305,105,0)
object.lNellingandN             =civ.getTile(305,105,2)
object.lJeverAF                 =civ.getTile(288,64,0)
object.lJeverN                  =civ.getTile(288,64,2)
object.lDeelenAF                =civ.getTile(249,71,0)
object.lDeelenN                 =civ.getTile(249,71,2)
object.lSaintOmerAF             =civ.getTile(203,81,0)
object.lSaintOmerN              =civ.getTile(203,81,2)
object.lAbbevilleAF             =civ.getTile(195,87,0)
object.lAbbevilleN              =civ.getTile(195,87,2)
object.lWesterlandAF            =civ.getTile(299,43,0)
object.lWesterlandN             =civ.getTile(299,43,2)
object.lSaintMaloAF             =civ.getTile(131,97,0)
object.lSaintMaloN              =civ.getTile(131,97,2)
object.lMorlaixAF               =civ.getTile(97,93,0)
object.lMorlaixN                =civ.getTile(97,93,2)
object.lLeeuwardenAF            =civ.getTile(253,61,0)
object.lLeeuwardenN             =civ.getTile(253,61,2)
object.lBretignyAF              =civ.getTile(192,108,0)
object.lBretignyN               =civ.getTile(192,108,2)
object.lBronAF                  =civ.getTile(216,132,0)
object.lBronAFN                 =civ.getTile(216,132,2)
object.lStTrondAF               =civ.getTile(248,84,0)
object.lStTrondN                =civ.getTile(248,84,2)
object.lBorkumAF                =civ.getTile(259,55,0)
object.lBorkumN                 =civ.getTile(259,55,2)
object.lBlankenseeAF            =civ.getTile(336,64,0)
object.lBlankenseeN             =civ.getTile(336,64,2)
object.lSalzwedelAF             =civ.getTile(333,83,0)
object.lSalzwedelN              =civ.getTile(333,83,2)
object.lMetzAF                  =civ.getTile(263,99,0)
object.lMetzN                   =civ.getTile(263,99,2)
object.lVerdun                  =civ.getTile(247,109,0)

-- Locations of cities starting the scenario owned by the Events:


-- Locations of cities starting the scenario owned by the Not used:


-- Locations of cities starting the scenario owned by the Not used:


-- Locations of cities starting the scenario owned by the Not used:


-- Locations of cities starting the scenario owned by the Not used:


-- Cities
-- recommended key prefix 'c'
-- It is not recommended to put cities into this list if the city
-- can be destroyed. This list returns an error if 'nil' is the value
-- associated with the key (see bottom of file), so that could cause
-- a problem if a city in this list is destroyed.  Also, if another
-- city is founded, the ID number of the city might get reused, causing
-- more confusion.  An alternate way to reference a city is by using
-- object.lRome.city when you actually need the city (and suitably guarding
-- against nil values)

--Find these by entering "for city in civ.iterateCities() do print(city.id, city.name) end" in the console

-- All the cities existing when you made generated this template are listed here.
-- If you wish to use these objects, change the line if false then below to if true then
-- It is your job to eliminate any cities that could be destroyed from this list if you use it
-- If you are not sure, it is recommended to reference cities from their locations instead
--

if false then

--Cities starting the scenario owned by the Neutrals:


--Cities starting the scenario owned by the Allies:

object.cLondon                  =civ.getTile(172,68,0).city
object.cPortsmouth              =civ.getTile(154,72,0).city
object.cBristol                 =civ.getTile(139,65,0).city
object.cSwansea                 =civ.getTile(119,61,0).city
object.cPlymouth                =civ.getTile(110,72,0).city
object.cCardiff                 =civ.getTile(131,63,0).city
object.cLiverpool               =civ.getTile(140,44,0).city
object.cBirmingham              =civ.getTile(150,54,0).city
object.cManchester              =civ.getTile(151,43,0).city
object.cNottingham              =civ.getTile(164,48,0).city
object.cSheffield               =civ.getTile(167,41,0).city
object.cColchester              =civ.getTile(193,65,0).city
object.cHull                    =civ.getTile(181,43,0).city
object.cNewcastle               =civ.getTile(171,27,0).city
object.cEdinburgh               =civ.getTile(163,13,0).city
object.cGlasgow                 =civ.getTile(137,11,0).city
object.cBelfast                 =civ.getTile(112,22,0).city
object.cCarlisle                =civ.getTile(152,24,0).city
object.cLeeds                   =civ.getTile(166,32,0).city
object.cRussianFront            =civ.getTile(406,74,0).city
object.cItalianTheatre          =civ.getTile(345,145,0).city
object.cManstonAF               =civ.getTile(191,73,0).city
object.cBoxtedAF                =civ.getTile(197,63,0).city
object.cCroydonAF               =civ.getTile(173,75,0).city
object.cBoltHeadAF              =civ.getTile(117,71,0).city
object.cDuxfordAF               =civ.getTile(176,60,0).city
object.cRidgewellAF             =civ.getTile(181,57,0).city
object.cWinktonAF               =civ.getTile(148,72,0).city
object.cDumfriesAFN             =civ.getTile(149,17,2).city
object.cWoodfordAFN             =civ.getTile(154,48,2).city
object.cWinktonAFN              =civ.getTile(148,72,2).city
object.cBoltHeadAFN             =civ.getTile(117,71,2).city
object.cCroydonAFN              =civ.getTile(173,75,2).city
object.cManstonAFN              =civ.getTile(191,73,2).city
object.cBoxtedAFN               =civ.getTile(197,63,2).city
object.cDremAF                  =civ.getTile(168,16,0).city
object.cWoodfordAF              =civ.getTile(154,48,0).city
object.cDumfriesAF              =civ.getTile(149,17,0).city
object.cRidgewellAFN            =civ.getTile(181,57,2).city
object.cDuxfordAFN              =civ.getTile(176,60,2).city
object.cDremAFN                 =civ.getTile(168,16,2).city
object.cMullaghmoreN            =civ.getTile(108,18,2).city
object.cDover                   =civ.getTile(185,75,0).city
object.cMullaghmoreAF           =civ.getTile(108,18,0).city
object.cKingsCliffeAF           =civ.getTile(179,53,0).city
object.cKingsCliffN             =civ.getTile(179,53,2).city
object.cMolesworthAF            =civ.getTile(175,55,0).city
object.cMolesworthN             =civ.getTile(175,55,2).city

--Cities starting the scenario owned by the Germans:

object.cBerlin                  =civ.getTile(363,71,0).city
object.cDresden                 =civ.getTile(369,89,0).city
object.cPrague                  =civ.getTile(375,101,0).city
object.cVienna                  =civ.getTile(403,121,0).city
object.cLeipzig                 =civ.getTile(352,90,0).city
object.cMerseburg               =civ.getTile(347,85,0).city
object.cRostock                 =civ.getTile(347,55,0).city
object.cLneburg                 =civ.getTile(323,73,0).city
object.cHannover                =civ.getTile(306,82,0).city
object.cBremen                  =civ.getTile(299,63,0).city
object.cWilhelmshaven           =civ.getTile(293,59,0).city
object.cDsseldorf               =civ.getTile(271,79,0).city
object.cCologne                 =civ.getTile(272,86,0).city
object.cEssen                   =civ.getTile(274,76,0).city
object.cDortmund                =civ.getTile(280,76,0).city
object.cHamburg                 =civ.getTile(317,59,0).city
object.cKiel                    =civ.getTile(324,50,0).city
object.cLbeck                   =civ.getTile(332,56,0).city
object.cNurnburg                =civ.getTile(326,106,0).city
object.cMunich                  =civ.getTile(332,120,0).city
object.cFriedrichshaven         =civ.getTile(300,124,0).city
object.cSchweinfurt             =civ.getTile(315,101,0).city
object.cFrankfurt               =civ.getTile(295,95,0).city
object.cAarhus                  =civ.getTile(326,32,0).city
object.cFreiburg                =civ.getTile(277,119,0).city
object.cKarlsruhe               =civ.getTile(288,104,0).city
object.cMannheim                =civ.getTile(292,100,0).city
object.cStuttgart               =civ.getTile(298,110,0).city
object.cRegensburg              =civ.getTile(344,108,0).city
object.cLinz                    =civ.getTile(370,122,0).city
object.cBrest                   =civ.getTile(90,94,0).city
object.cStNazaire               =civ.getTile(118,108,0).city
object.cNantes                  =civ.getTile(125,111,0).city
object.cLaRochelle              =civ.getTile(127,125,0).city
object.cBordeaux                =civ.getTile(130,142,0).city
object.cCherbourg               =civ.getTile(142,84,0).city
object.cLeHavre                 =civ.getTile(164,90,0).city
object.cTours                   =civ.getTile(163,117,0).city
object.cRouen                   =civ.getTile(176,92,0).city
object.cParis                   =civ.getTile(195,101,0).city
object.cBrussels                =civ.getTile(230,84,0).city
object.cAmsterdam               =civ.getTile(245,65,0).city
object.cTheHague                =civ.getTile(234,70,0).city
object.cRotterdam               =civ.getTile(241,71,0).city
object.cAntwerp                 =civ.getTile(231,77,0).city
object.cLille                   =civ.getTile(211,87,0).city
object.cCalais                  =civ.getTile(199,77,0).city
object.cLyon                    =civ.getTile(212,140,0).city
object.cBrunswick               =civ.getTile(339,75,0).city
object.cPeenemnde               =civ.getTile(375,61,0).city
object.cSchipholAF              =civ.getTile(240,66,0).city
object.cSchipholN               =civ.getTile(240,66,2).city
object.cWoensdrechtAF           =civ.getTile(223,79,0).city
object.cWoensdrechtN            =civ.getTile(223,79,2).city
object.cBeaumontAF              =civ.getTile(165,101,0).city
object.cBeaumontN               =civ.getTile(165,101,2).city
object.cVannesAF                =civ.getTile(113,105,0).city
object.cVannesN                 =civ.getTile(113,105,2).city
object.cLannesAF                =civ.getTile(139,139,0).city
object.cLannesN                 =civ.getTile(139,139,2).city
object.cCormeillesAF            =civ.getTile(191,93,0).city
object.cCormeillesN             =civ.getTile(191,93,2).city
object.cOstheimAF               =civ.getTile(287,93,0).city
object.cOstheimN                =civ.getTile(287,93,2).city
object.cOphovenAF               =civ.getTile(258,72,0).city
object.cOphovenN                =civ.getTile(258,72,2).city
object.cRheinsehlenAF           =civ.getTile(313,69,0).city
object.cRheinsehlenN            =civ.getTile(313,69,2).city
object.cEggebekAF               =civ.getTile(313,43,0).city
object.cEggebekN                =civ.getTile(313,43,2).city
object.cDberitzAF               =civ.getTile(352,70,0).city
object.cDberitzN                =civ.getTile(352,70,2).city
object.cKolledaAF               =civ.getTile(359,87,0).city
object.cKolledaN                =civ.getTile(359,87,2).city
object.cWelsAF                  =civ.getTile(364,122,0).city
object.cWelsN                   =civ.getTile(364,122,2).city
object.cPockingAF               =civ.getTile(341,117,0).city
object.cPockingN                =civ.getTile(341,117,2).city
object.cNellingandAF            =civ.getTile(305,105,0).city
object.cNellingandN             =civ.getTile(305,105,2).city
object.cJeverAF                 =civ.getTile(288,64,0).city
object.cJeverN                  =civ.getTile(288,64,2).city
object.cDeelenAF                =civ.getTile(249,71,0).city
object.cDeelenN                 =civ.getTile(249,71,2).city
object.cSaintOmerAF             =civ.getTile(203,81,0).city
object.cSaintOmerN              =civ.getTile(203,81,2).city
object.cAbbevilleAF             =civ.getTile(195,87,0).city
object.cAbbevilleN              =civ.getTile(195,87,2).city
object.cWesterlandAF            =civ.getTile(299,43,0).city
object.cWesterlandN             =civ.getTile(299,43,2).city
object.cSaintMaloAF             =civ.getTile(131,97,0).city
object.cSaintMaloN              =civ.getTile(131,97,2).city
object.cMorlaixAF               =civ.getTile(97,93,0).city
object.cMorlaixN                =civ.getTile(97,93,2).city
object.cLeeuwardenAF            =civ.getTile(253,61,0).city
object.cLeeuwardenN             =civ.getTile(253,61,2).city
object.cBretignyAF              =civ.getTile(192,108,0).city
object.cBretignyN               =civ.getTile(192,108,2).city
object.cBronAF                  =civ.getTile(216,132,0).city
object.cBronAFN                 =civ.getTile(216,132,2).city
object.cStTrondAF               =civ.getTile(248,84,0).city
object.cStTrondN                =civ.getTile(248,84,2).city
object.cBorkumAF                =civ.getTile(259,55,0).city
object.cBorkumN                 =civ.getTile(259,55,2).city
object.cBlankenseeAF            =civ.getTile(336,64,0).city
object.cBlankenseeN             =civ.getTile(336,64,2).city
object.cSalzwedelAF             =civ.getTile(333,83,0).city
object.cSalzwedelN              =civ.getTile(333,83,2).city
object.cMetzAF                  =civ.getTile(263,99,0).city
object.cMetzN                   =civ.getTile(263,99,2).city
object.cVerdun                  =civ.getTile(247,109,0).city

--Cities starting the scenario owned by the Events:


--Cities starting the scenario owned by the Not used:


--Cities starting the scenario owned by the Not used:


--Cities starting the scenario owned by the Not used:


--Cities starting the scenario owned by the Not used:


end

-- Unit Types
-- recommended key prefix 'u'

object.uRedArmyGroup            = civ.getUnitType(0)
object.uConstructionTeam        = civ.getUnitType(1)   --Engineers
object.uBofors40mm              = civ.getUnitType(2)
object.uEarlyRadar              = civ.getUnitType(3)
object.uAdvancedRadar           = civ.getUnitType(4)
object.uFw200                   = civ.getUnitType(5)
object.uFreightTrain            = civ.getUnitType(6)
object.uRailyard                = civ.getUnitType(7)
object.uAerialPhotos            = civ.getUnitType(8)
object.uSdkfz72                 = civ.getUnitType(9)
object.u88mmFlakBattery         = civ.getUnitType(10)
object.uFlakTrain               = civ.getUnitType(11)
object.uMe109G6                 = civ.getUnitType(12)
object.uMe109G14                = civ.getUnitType(13)
object.uMe109K4                 = civ.getUnitType(14)
object.uFw190A5                 = civ.getUnitType(15)
object.uFw190A8                 = civ.getUnitType(16)
object.uFw190D9                 = civ.getUnitType(17)
object.uTa152                   = civ.getUnitType(18)
object.uMilitaryPort            = civ.getUnitType(19)
object.uMe110                   = civ.getUnitType(20)
object.uMe410                   = civ.getUnitType(21)
object.uJu88C                   = civ.getUnitType(22)
object.uJu88G                   = civ.getUnitType(23)
object.uHe219                   = civ.getUnitType(24)
object.uHe162                   = civ.getUnitType(25)
object.uMe163                   = civ.getUnitType(26)
object.uMe262                   = civ.getUnitType(27)
object.uJu87G                   = civ.getUnitType(28)
object.uFw190F8                 = civ.getUnitType(29)
object.uDo335                   = civ.getUnitType(30)
object.uDo217                   = civ.getUnitType(31)
object.uHe277                   = civ.getUnitType(32)
object.uArado234                = civ.getUnitType(33)
object.uGo229                   = civ.getUnitType(34)
object.uSpitfireIX              = civ.getUnitType(35)
object.uSpitfireXII             = civ.getUnitType(36)
object.uSpitfireXIV             = civ.getUnitType(37)
object.uHurricaneIV             = civ.getUnitType(38)
object.uTyphoon                 = civ.getUnitType(39)
object.uTempest                 = civ.getUnitType(40)
object.uMeteor                  = civ.getUnitType(41)
object.uBeaufighter             = civ.getUnitType(42)
object.uMosquitoNFMkII          = civ.getUnitType(43)
object.uMosquitoNFMkXIII        = civ.getUnitType(44)
object.uIndustry                = civ.getUnitType(45)   --Nuclear Msl
object.uFw190A5Rocket           = civ.getUnitType(46)
object.uFw190A8Rocket           = civ.getUnitType(47)   --Spy
object.uMe109G6Rocket           = civ.getUnitType(48)
object.uBarrageBalloons         = civ.getUnitType(49)   --Freight
object.uP47D11                  = civ.getUnitType(50)
object.uP47D25                  = civ.getUnitType(51)
object.uP47D40                  = civ.getUnitType(52)
object.uExperten                = civ.getUnitType(53)
object.uP38H                    = civ.getUnitType(54)
object.uP38J                    = civ.getUnitType(55)
object.uP51B                    = civ.getUnitType(56)
object.uP51D                    = civ.getUnitType(57)
object.uP80                     = civ.getUnitType(58)
object.uStirling                = civ.getUnitType(59)
object.uHalifax                 = civ.getUnitType(60)
object.uLancaster               = civ.getUnitType(61)
object.uPathfinder              = civ.getUnitType(62)
object.uA20                     = civ.getUnitType(63)
object.uB26                     = civ.getUnitType(64)
object.uA26                     = civ.getUnitType(65)
object.uB17F                    = civ.getUnitType(66)
object.uB24J                    = civ.getUnitType(67)
object.uB17G                    = civ.getUnitType(68)
object.uBattleGroupGerman       = civ.getUnitType(69)
object.uDepletedBattleGroupGerman= civ.getUnitType(70)
object.uEgonMayer               = civ.getUnitType(71)
object.u37inchFlak              = civ.getUnitType(72)
object.uHe111                   = civ.getUnitType(73)
object.uBattleGroupAllied       = civ.getUnitType(74)
object.uDepletedBattleGroupAllied= civ.getUnitType(75)
object.uSunderland              = civ.getUnitType(76)
object.uSAVE16                  = civ.getUnitType(77)
object.uHermannGraf             = civ.getUnitType(78)
object.uJosefPriller            = civ.getUnitType(79)
object.uAdolfGalland            = civ.getUnitType(80)
object.uTaskForceG              = civ.getUnitType(81)
object.uTaskForceA              = civ.getUnitType(82)
object.u332ndFG                 = civ.getUnitType(83)
object.u15thAFBombers           = civ.getUnitType(84)
object.uAircraftFactory         = civ.getUnitType(85)
object.uMe109G14Rocket          = civ.getUnitType(86)
object.uSAVE17                  = civ.getUnitType(87)
object.uRefinery                = civ.getUnitType(88)
object.uGuntherRall             = civ.getUnitType(89)
object.uWalterNowotny           = civ.getUnitType(90)
object.uUrbanCenter             = civ.getUnitType(91)
object.uWhirlwind               = civ.getUnitType(92)
object.uB25                     = civ.getUnitType(93)
object.uGunBattery              = civ.getUnitType(94)
object.uP61                     = civ.getUnitType(95)
object.uMosquitoBIV             = civ.getUnitType(96)
object.uFrancisGabreski         = civ.getUnitType(97)
object.uGeorgePreddy            = civ.getUnitType(98)
object.uJohnBraham              = civ.getUnitType(99)
object.uJohnnieJohnson          = civ.getUnitType(100)
object.uWindow                  = civ.getUnitType(101)
object.uHWSchnaufer             = civ.getUnitType(102)
object.uErichHartmann           = civ.getUnitType(103)
object.uPanzerDivision          = civ.getUnitType(104)
object.uDamagedB17F             = civ.getUnitType(105)
object.uNeutralTerritory        = civ.getUnitType(106)
object.uDamagedB17G             = civ.getUnitType(107)
object.uP38L                    = civ.getUnitType(108)
object.uCriticalIndustry        = civ.getUnitType(109)
object.uGerhardBarkhorn         = civ.getUnitType(110)
object.uAircraftCarrier         = civ.getUnitType(111)
object.uUSAAFAce                = civ.getUnitType(112)
object.uRAFAce                  = civ.getUnitType(113)
object.uBarrage                 = civ.getUnitType(114)
object.uConvoy                  = civ.getUnitType(115)
object.uSAVE18                  = civ.getUnitType(116)
object.uYak3                    = civ.getUnitType(117)
object.uIl2                     = civ.getUnitType(118)
object.u37cmFlak                = civ.getUnitType(119)
object.uJu188PR                 = civ.getUnitType(120)
object.uV1LaunchSite            = civ.getUnitType(121)
object.uV2LaunchSite            = civ.getUnitType(122)
object.uV1Buzzbomb              = civ.getUnitType(123)
object.uV2Rocket                = civ.getUnitType(124)
object.uMosquitoPR              = civ.getUnitType(125)
object.uWolfPack                = civ.getUnitType(126)

-- City Improvements
-- recommended key prefix 'i'
--          

object.iNothing                 = civ.getImprovement(0)
object.iHeadquarters            = civ.getImprovement(1)
object.iNOTUSED                 = civ.getImprovement(2)
object.iRedArmy                 = civ.getImprovement(3)
object.iCivilianPopulationI     = civ.getImprovement(4)
object.iFuelRefineryI           = civ.getImprovement(5)
object.iAircraftFactoryI        = civ.getImprovement(6)
object.iQuartermaster           = civ.getImprovement(7)
object.iCityI                   = civ.getImprovement(8)
object.iCityII                  = civ.getImprovement(9)
object.iFuelRefineryII          = civ.getImprovement(10)
object.iCivilianPopulationII    = civ.getImprovement(11)
object.iAircraftFactoryII       = civ.getImprovement(12)
object.iCriticalIndustry        = civ.getImprovement(13)
object.iCivilianPopulationIII   = civ.getImprovement(14)
object.iIndustryI               = civ.getImprovement(15)
object.iIndustryII              = civ.getImprovement(16)
object.iAirbase                 = civ.getImprovement(17)
object.i15thAirForce            = civ.getImprovement(18)
object.iOLDIndustryIII          = civ.getImprovement(19)
object.iNOTUSED_                = civ.getImprovement(20)
object.iNOTUSED__               = civ.getImprovement(21)
object.iFuelRefineryIII         = civ.getImprovement(22)
object.iCityIII                 = civ.getImprovement(23)
object.iRationing               = civ.getImprovement(24)
object.iRailyards               = civ.getImprovement(25)
object.iAircraftFactoryIII      = civ.getImprovement(26)
object.iExperimentalAircraft    = civ.getImprovement(27)
object.iFirefighters            = civ.getImprovement(28)
object.iIndustryIII             = civ.getImprovement(29)
object.iDocks                   = civ.getImprovement(30)
object.iNOTUSED___              = civ.getImprovement(31)
object.iJagdfliegerschule       = civ.getImprovement(32)
object.iWehrmacht               = civ.getImprovement(33)
object.iMilitaryPort            = civ.getImprovement(34)
object.iNOTUSED____             = civ.getImprovement(35)

-- Players (Tribes)
-- recommended key prefix 'p'

object.pNeutrals                = civ.getTribe(0)
object.pAllies                  = civ.getTribe(1)
object.pGermans                 = civ.getTribe(2)
object.pEvents                  = civ.getTribe(3)
object.pNotused                 = civ.getTribe(4)
object.pNotused_                = civ.getTribe(5)
object.pNotused__               = civ.getTribe(6)
object.pNotused___              = civ.getTribe(7)

-- Wonders
-- recommended key prefix 'w'

object.wNOTUSED                 = civ.getWonder(0)
object.wNOTUSED_                = civ.getWonder(1)
object.wIGFarben                = civ.getWonder(2)
object.wNOTUSED__               = civ.getWonder(3)
object.wNOTUSED___              = civ.getWonder(4)
object.wNOTUSED____             = civ.getWonder(5)
object.wNOTUSED_____            = civ.getWonder(6)
object.wNOTUSED______           = civ.getWonder(7)
object.wKruppWorks              = civ.getWonder(8)
object.wNOTUSED_______          = civ.getWonder(9)
object.wNOTUSED________         = civ.getWonder(10)
object.wPeenemnde               = civ.getWonder(11)
object.wNOTUSED_________        = civ.getWonder(12)
object.wNOTUSED__________       = civ.getWonder(13)
object.wNOTUSED___________      = civ.getWonder(14)
object.wAdolfHitler             = civ.getWonder(15)
object.wJgernotprogramm         = civ.getWonder(16)
object.wAlbertSpeersReforms     = civ.getWonder(17)
object.w56thFighterGroup        = civ.getWonder(18)
object.wNo617RAF                = civ.getWonder(19)
object.wJG2Richthofen           = civ.getWonder(20)
object.wNOTUSED____________     = civ.getWonder(21)
object.wArsenalofDemocracy      = civ.getWonder(22)
object.wNOTUSED_____________    = civ.getWonder(23)
object.wJG26Schlageter          = civ.getWonder(24)
object.wNOTUSED______________   = civ.getWonder(25)
object.wNOTUSED_______________  = civ.getWonder(26)
object.wNOTUSED________________ = civ.getWonder(27)

-- Base Terrain
-- recommended prefix 'b'

object.bCityLowBase             =civ.getBaseTerrain(0,0)  --Drt
object.bRailtrackLowBase        =civ.getBaseTerrain(0,1)  --Pln
object.bGrasslandLowBase        =civ.getBaseTerrain(0,2)  --Grs
object.bForestLowBase           =civ.getBaseTerrain(0,3)  --For
object.bUrbanLowBase            =civ.getBaseTerrain(0,4)  --Hil
object.bHillsLowBase            =civ.getBaseTerrain(0,5)  --Mou
object.bRefineryLowBase         =civ.getBaseTerrain(0,6)  --Tun
object.bInstallationLowBase     =civ.getBaseTerrain(0,7)  --Gla
object.bIndustryLowBase         =civ.getBaseTerrain(0,8)  --Swa
object.bAirfieldLowBase         =civ.getBaseTerrain(0,9)  --Jun
object.bWaterLowBase            =civ.getBaseTerrain(0,10)  --Oce
object.bBombedRRLowBase         =civ.getBaseTerrain(0,11)  --Bbb
object.bBombedRefineryLowBase   =civ.getBaseTerrain(0,12)  --Ccc
object.bBombedUrbanLowBase      =civ.getBaseTerrain(0,13)  --Ddd
object.bBombedIndustryLowBase   =civ.getBaseTerrain(0,14)  --Eee
object.bResidentialLowBase     =civ.getBaseTerrain(0,15)  --Fff
object.bCityHighBase            =civ.getBaseTerrain(1,0)  --Drt
object.bHillsHighBase           =civ.getBaseTerrain(1,1)  --Pln
object.bGrasslandHighBase       =civ.getBaseTerrain(1,2)  --Grs
object.bForestHighBase          =civ.getBaseTerrain(1,3)  --For
object.bUrbanHighBase           =civ.getBaseTerrain(1,4)  --Hil
object.bCloudCoverHighBase      =civ.getBaseTerrain(1,5)  --Mou
object.bRefineryHighBase        =civ.getBaseTerrain(1,6)  --Tun
object.bSAVEHighBase            =civ.getBaseTerrain(1,7)  --Gla
object.bIndustryHighBase        =civ.getBaseTerrain(1,8)  --Swa
object.bAirfieldHighBase        =civ.getBaseTerrain(1,9)  --Jun
object.bWaterHighBase           =civ.getBaseTerrain(1,10)  --Oce
object.bRubbleHighBase          =civ.getBaseTerrain(1,11)  --Bbb
object.bBombedRefineryHighBase  =civ.getBaseTerrain(1,12)  --Ccc
object.bBombedRRHighBase        =civ.getBaseTerrain(1,13)  --Ddd
object.bBombedIndustryHighBase  =civ.getBaseTerrain(1,14)  --Eee
object.bTargetHighBase          =civ.getBaseTerrain(1,15)  --Fff
object.bCityNightBase           =civ.getBaseTerrain(2,0)  --Drt
object.bRailtrackNightBase      =civ.getBaseTerrain(2,1)  --Pln
object.bGrasslandNightBase      =civ.getBaseTerrain(2,2)  --Grs
object.bForestNightBase         =civ.getBaseTerrain(2,3)  --For
object.bUrbanNightBase          =civ.getBaseTerrain(2,4)  --Hil
object.bCloudCoverNightBase     =civ.getBaseTerrain(2,5)  --Mou
object.bSearchlightsNightBase   =civ.getBaseTerrain(2,6)  --Tun
object.bHillsNightBase          =civ.getBaseTerrain(2,7)  --Gla
object.bBombedRRNightBase       =civ.getBaseTerrain(2,8)  --Swa
object.bAirfieldNightBase       =civ.getBaseTerrain(2,9)  --Jun
object.bWaterNightBase          =civ.getBaseTerrain(2,10)  --Oce
object.bFirestormNightBase      =civ.getBaseTerrain(2,11)  --Bbb
object.bRubbleNightBase         =civ.getBaseTerrain(2,12)  --Ccc
object.bBombedRRRubleNightBase  =civ.getBaseTerrain(2,13)  --Ddd
object.bBombedIndustryNightBase =civ.getBaseTerrain(2,14)  --Eee
object.bTargetNightBase         =civ.getBaseTerrain(2,15)  --Fff

-- Terrain
-- recommended prefix 't'

object.tCityLowBase             =civ.getTerrain(0,0,0)
object.tCityLowFish             =civ.getTerrain(0,0,1) -- Fish Resource
object.tCityLowWhale            =civ.getTerrain(0,0,2) -- Whale Resource
object.tRailtrackLowBase        =civ.getTerrain(0,1,0)
object.tRailtrackLowFish        =civ.getTerrain(0,1,1) -- Fish Resource
object.tRailtrackLowWhale       =civ.getTerrain(0,1,2) -- Whale Resource
object.tGrasslandLowBase        =civ.getTerrain(0,2,0)
object.tForestLowBase           =civ.getTerrain(0,3,0)
object.tLumberLowFish           =civ.getTerrain(0,3,1) -- Fish Resource
object.tGameLowWhale            =civ.getTerrain(0,3,2) -- Whale Resource
object.tUrbanLowBase            =civ.getTerrain(0,4,0)
object.tUrbanLowFish            =civ.getTerrain(0,4,1) -- Fish Resource
object.tUrbanLowWhale           =civ.getTerrain(0,4,2) -- Whale Resource
object.tHillsLowBase            =civ.getTerrain(0,5,0)
object.tCoalLowFish             =civ.getTerrain(0,5,1) -- Fish Resource
object.tIronLowWhale            =civ.getTerrain(0,5,2) -- Whale Resource
object.tRefineryLowBase         =civ.getTerrain(0,6,0)
object.tRefineryLowFish         =civ.getTerrain(0,6,1) -- Fish Resource
object.tRefineryLowWhale        =civ.getTerrain(0,6,2) -- Whale Resource
object.tInstallationLowBase     =civ.getTerrain(0,7,0)
object.tInstallationLowFish     =civ.getTerrain(0,7,1) -- Fish Resource
object.tInstallationLowWhale    =civ.getTerrain(0,7,2) -- Whale Resource
object.tIndustryLowBase         =civ.getTerrain(0,8,0)
object.tAssemblyLineLowFish     =civ.getTerrain(0,8,1) -- Fish Resource
object.tAssemblyLineLowWhale    =civ.getTerrain(0,8,2) -- Whale Resource
object.tAirfieldLowBase         =civ.getTerrain(0,9,0)
object.tAirfieldLowFish         =civ.getTerrain(0,9,1) -- Fish Resource
object.tAirfieldLowWhale        =civ.getTerrain(0,9,2) -- Whale Resource
object.tWaterLowBase            =civ.getTerrain(0,10,0)
object.tWaterLowFish            =civ.getTerrain(0,10,1) -- Fish Resource
object.tWaterLowWhale           =civ.getTerrain(0,10,2) -- Whale Resource
object.tBombedRRLowBase         =civ.getTerrain(0,11,0)
object.tBombedRRLowFish         =civ.getTerrain(0,11,1) -- Fish Resource
object.tBombedRRLowWhale        =civ.getTerrain(0,11,2) -- Whale Resource
object.tBombedRefineryLowBase   =civ.getTerrain(0,12,0)
object.tBombedRefineryLowFish   =civ.getTerrain(0,12,1) -- Fish Resource
object.tBombedRefineryLowWhale  =civ.getTerrain(0,12,2) -- Whale Resource
object.tBombedUrbanLowBase      =civ.getTerrain(0,13,0)
object.tBombedUrbanLowFish      =civ.getTerrain(0,13,1) -- Fish Resource
object.tBombedUrbanLowWhale     =civ.getTerrain(0,13,2) -- Whale Resource
object.tBombedIndustryLowBase   =civ.getTerrain(0,14,0)
object.tBombedIndustryLowFish   =civ.getTerrain(0,14,1) -- Fish Resource
object.tBombedIndustryLowWhale  =civ.getTerrain(0,14,2) -- Whale Resource
object.tResidentialLowBase     =civ.getTerrain(0,15,0)
object.tResidentialLowFish     =civ.getTerrain(0,15,1) -- Fish Resource
object.tResidentialLowWhale    =civ.getTerrain(0,15,2) -- Whale Resource
object.tCityHighBase            =civ.getTerrain(1,0,0)
object.tCityHighFish            =civ.getTerrain(1,0,1) -- Fish Resource
object.tCityHighWhale           =civ.getTerrain(1,0,2) -- Whale Resource
object.tHillsHighBase           =civ.getTerrain(1,1,0)
object.tHillsHighFish           =civ.getTerrain(1,1,1) -- Fish Resource
object.tHillsHighWhale          =civ.getTerrain(1,1,2) -- Whale Resource
object.tGrasslandHighBase       =civ.getTerrain(1,2,0)
object.tForestHighBase          =civ.getTerrain(1,3,0)
object.tForestHighFish          =civ.getTerrain(1,3,1) -- Fish Resource
object.tForestHighWhale         =civ.getTerrain(1,3,2) -- Whale Resource
object.tUrbanHighBase           =civ.getTerrain(1,4,0)
object.tUrbanHighFish           =civ.getTerrain(1,4,1) -- Fish Resource
object.tUrbanHighWhale          =civ.getTerrain(1,4,2) -- Whale Resource
object.tCloudCoverHighBase      =civ.getTerrain(1,5,0)
object.tCloudCoverHighFish      =civ.getTerrain(1,5,1) -- Fish Resource
object.tCloudCoverHighWhale     =civ.getTerrain(1,5,2) -- Whale Resource
object.tRefineryHighBase        =civ.getTerrain(1,6,0)
object.tRefineryHighFish        =civ.getTerrain(1,6,1) -- Fish Resource
object.tRefineryHighWhale       =civ.getTerrain(1,6,2) -- Whale Resource
object.tSAVEHighBase            =civ.getTerrain(1,7,0)
object.tSAVEHighFish            =civ.getTerrain(1,7,1) -- Fish Resource
object.tSAVEHighWhale           =civ.getTerrain(1,7,2) -- Whale Resource
object.tIndustryHighBase        =civ.getTerrain(1,8,0)
object.tIndustryHighFish        =civ.getTerrain(1,8,1) -- Fish Resource
object.tIndustryHighWhale       =civ.getTerrain(1,8,2) -- Whale Resource
object.tAirfieldHighBase        =civ.getTerrain(1,9,0)
object.tAirfieldHighFish        =civ.getTerrain(1,9,1) -- Fish Resource
object.tAirfieldHighWhale       =civ.getTerrain(1,9,2) -- Whale Resource
object.tWaterHighBase           =civ.getTerrain(1,10,0)
object.tWaterHighFish           =civ.getTerrain(1,10,1) -- Fish Resource
object.tWaterHighWhale          =civ.getTerrain(1,10,2) -- Whale Resource
object.tRubbleHighBase          =civ.getTerrain(1,11,0)
object.tRubbleHighFish          =civ.getTerrain(1,11,1) -- Fish Resource
object.tRubbleHighWhale         =civ.getTerrain(1,11,2) -- Whale Resource
object.tBombedRefineryHighBase  =civ.getTerrain(1,12,0)
object.tBombedRefineryHighFish  =civ.getTerrain(1,12,1) -- Fish Resource
object.tBombedRefineryHighWhale =civ.getTerrain(1,12,2) -- Whale Resource
object.tBombedRRHighBase        =civ.getTerrain(1,13,0)
object.tBombedRRHighFish        =civ.getTerrain(1,13,1) -- Fish Resource
object.tBombedRRHighWhale       =civ.getTerrain(1,13,2) -- Whale Resource
object.tBombedIndustryHighBase  =civ.getTerrain(1,14,0)
object.tBombedIndustryHighFish  =civ.getTerrain(1,14,1) -- Fish Resource
object.tBombedIndustryHighWhale =civ.getTerrain(1,14,2) -- Whale Resource
object.tTargetHighBase          =civ.getTerrain(1,15,0)
object.tTargetHighFish          =civ.getTerrain(1,15,1) -- Fish Resource
object.tTargetHighWhale         =civ.getTerrain(1,15,2) -- Whale Resource
object.tCityNightBase           =civ.getTerrain(2,0,0)
object.tCityNightFish           =civ.getTerrain(2,0,1) -- Fish Resource
object.tCityNightWhale          =civ.getTerrain(2,0,2) -- Whale Resource
object.tRailtrackNightBase      =civ.getTerrain(2,1,0)
object.tRailtrackNightFish      =civ.getTerrain(2,1,1) -- Fish Resource
object.tRailtrackNightWhale     =civ.getTerrain(2,1,2) -- Whale Resource
object.tGrasslandNightBase      =civ.getTerrain(2,2,0)
object.tForestNightBase         =civ.getTerrain(2,3,0)
object.tForestNightFish         =civ.getTerrain(2,3,1) -- Fish Resource
object.tForestNightWhale        =civ.getTerrain(2,3,2) -- Whale Resource
object.tUrbanNightBase          =civ.getTerrain(2,4,0)
object.tUrbanNightFish          =civ.getTerrain(2,4,1) -- Fish Resource
object.tUrbanNightWhale         =civ.getTerrain(2,4,2) -- Whale Resource
object.tCloudCoverNightBase     =civ.getTerrain(2,5,0)
object.tCloudCoverNightFish     =civ.getTerrain(2,5,1) -- Fish Resource
object.tCloudCoverNightWhale    =civ.getTerrain(2,5,2) -- Whale Resource
object.tSearchlightsNightBase   =civ.getTerrain(2,6,0)
object.tSearchlightsNightFish   =civ.getTerrain(2,6,1) -- Fish Resource
object.tSearchlightsNightWhale  =civ.getTerrain(2,6,2) -- Whale Resource
object.tHillsNightBase          =civ.getTerrain(2,7,0)
object.tHillsNightFish          =civ.getTerrain(2,7,1) -- Fish Resource
object.tHillsNightWhale         =civ.getTerrain(2,7,2) -- Whale Resource
object.tBombedRRNightBase       =civ.getTerrain(2,8,0)
object.tBombedRRNightFish       =civ.getTerrain(2,8,1) -- Fish Resource
object.tBombedRRNightWhale      =civ.getTerrain(2,8,2) -- Whale Resource
object.tAirfieldNightBase       =civ.getTerrain(2,9,0)
object.tAirfieldNightFish       =civ.getTerrain(2,9,1) -- Fish Resource
object.tAirfieldNightWhale      =civ.getTerrain(2,9,2) -- Whale Resource
object.tWaterNightBase          =civ.getTerrain(2,10,0)
object.tWaterNightFish          =civ.getTerrain(2,10,1) -- Fish Resource
object.tWaterNightWhale         =civ.getTerrain(2,10,2) -- Whale Resource
object.tFirestormNightBase      =civ.getTerrain(2,11,0)
object.tFirestormNightFish      =civ.getTerrain(2,11,1) -- Fish Resource
object.tFirestormNightWhale     =civ.getTerrain(2,11,2) -- Whale Resource
object.tRubbleNightBase         =civ.getTerrain(2,12,0)
object.tRubbleNightFish         =civ.getTerrain(2,12,1) -- Fish Resource
object.tRubbleNightWhale        =civ.getTerrain(2,12,2) -- Whale Resource
object.tBombedRRRubleNightBase  =civ.getTerrain(2,13,0)
object.tBombedRRRubleNightFish  =civ.getTerrain(2,13,1) -- Fish Resource
object.tBombedRRRubbleNightWhale=civ.getTerrain(2,13,2) -- Whale Resource
object.tBombedIndustryNightBase =civ.getTerrain(2,14,0)
object.tBombedIndustryNightFish =civ.getTerrain(2,14,1) -- Fish Resource
object.tBombedIndustryNightWhale=civ.getTerrain(2,14,2) -- Whale Resource
object.tTargetNightBase         =civ.getTerrain(2,15,0)
object.tTargetNightFish         =civ.getTerrain(2,15,1) -- Fish Resource
object.tTargetNightWhale        =civ.getTerrain(2,15,2) -- Whale Resource

-- Text
-- You might find it easier to keep much of your events text here
-- Remember, you can place %STRING1, %STRING2, etc. in your text and
-- use text.substitute to insert the actual values in the event, instead
-- of splitting the text into multiple parts
-- recommended prefix 'x'


-- Images
-- For optimal integration with the image functionality of the
-- text module, it is recommended that you load all your
-- images here.
-- recommended prefix `m`
--
text.setImageTable(object,"object")-- The string "object" provides a name of the table for error messages.


-- Flag and Counter Definitions
-- Flags and counters have to be defined somewhere, and this
-- is as good a place as any






-- this will give you an if you try to access a key not entered into
-- the object table, which could be helpful for debugging, but it
-- means that no nil value can ever be returned for table object
-- If you need that ability, comment out this line
gen.forbidNilValueAccess(object)

return object
